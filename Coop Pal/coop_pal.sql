-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Feb 27, 2025 at 04:03 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `coop_pal`
--

-- --------------------------------------------------------

--
-- Table structure for table `actuator_states`
--

CREATE TABLE `actuator_states` (
  `id` int(11) NOT NULL,
  `time` datetime NOT NULL DEFAULT current_timestamp(),
  `fan` tinyint(1) NOT NULL,
  `led_bulb` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `alert_history`
--

CREATE TABLE `alert_history` (
  `id` int(11) NOT NULL,
  `date` date NOT NULL DEFAULT current_timestamp(),
  `time` time NOT NULL DEFAULT current_timestamp(),
  `parameter` varchar(15) NOT NULL,
  `threshold` varchar(5) NOT NULL,
  `reading` varchar(5) NOT NULL,
  `actuator` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `egg_detection`
--

CREATE TABLE `egg_detection` (
  `id` int(11) NOT NULL,
  `time` datetime NOT NULL DEFAULT current_timestamp(),
  `eggs_detected` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `light_calculation`
--

CREATE TABLE `light_calculation` (
  `id` int(11) NOT NULL,
  `time` datetime NOT NULL DEFAULT current_timestamp(),
  `daylight_duration` int(11) NOT NULL,
  `led_duration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scan_history`
--

CREATE TABLE `scan_history` (
  `id` int(11) NOT NULL,
  `date` date NOT NULL DEFAULT current_timestamp(),
  `time` time NOT NULL DEFAULT current_timestamp(),
  `eggs_detected` int(11) DEFAULT NULL,
  `temperature` float NOT NULL,
  `humidity` int(11) NOT NULL,
  `light` int(11) NOT NULL,
  `air_quality` float DEFAULT NULL,
  `feeds_weight` float NOT NULL,
  `water_weight` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sensor_data`
--

CREATE TABLE `sensor_data` (
  `id` int(11) NOT NULL,
  `time` datetime NOT NULL DEFAULT current_timestamp(),
  `temperature` int(11) DEFAULT NULL,
  `humidity` int(11) DEFAULT NULL,
  `light` float NOT NULL,
  `egg_range` int(11) DEFAULT NULL,
  `feeds_weight` float DEFAULT NULL,
  `water_weight` float DEFAULT NULL,
  `mq9` float DEFAULT NULL,
  `mq135` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `sensor_data`
--
DELIMITER $$
CREATE TRIGGER `alert` AFTER INSERT ON `sensor_data` FOR EACH ROW BEGIN
    -- Create variables to hold thresholds
    DECLARE min_temp_t, max_temp_t, min_humid_t, max_humid_t INT;
    DECLARE max_feeds_t, max_water_t FLOAT;

    DECLARE latest_raw_weight FLOAT;
    DECLARE final_water_weight FLOAT;

    SELECT raw_weight INTO latest_raw_weight 
    FROM water_calibration 
	ORDER BY id DESC LIMIT 1;

    SET final_water_weight = NEW.water_weight - latest_raw_weight;

    -- Retrieve threshold values from database
    SELECT min_temp, max_temp, min_humid, max_humid, max_feeds, max_water
    INTO min_temp_t, max_temp_t, min_humid_t, max_humid_t, max_feeds_t, max_water_t
    FROM thresholds
    ORDER BY id DESC LIMIT 1;

    -- Compare values to thresholds
    -- Temperature
    IF NEW.temperature < min_temp_t THEN
        INSERT INTO alert_history (parameter, threshold, reading, actuator)
        VALUES ('Temperature', CONCAT(min_temp_t, ' °C'), CONCAT(NEW.temperature, ' °C'), 'N/A');
    ELSEIF NEW.temperature > max_temp_t THEN
        INSERT INTO alert_history (parameter, threshold, reading, actuator)
        VALUES ('Temperature', CONCAT(max_temp_t, ' °C'), CONCAT(NEW.temperature, ' °C'), 'Fan');
    END IF;
    -- Humidity
    IF NEW.humidity > max_humid_t THEN
        INSERT INTO alert_history (parameter, threshold, reading, actuator)
        VALUES ('Humidity', CONCAT(max_humid_t, '%'), CONCAT(NEW.humidity, '%'), 'Fan');
    ELSEIF NEW.humidity < min_humid_t THEN
        INSERT INTO alert_history (parameter, threshold, reading, actuator)
        VALUES ('Humidity', CONCAT(min_humid_t, '%'), CONCAT(NEW.humidity, '%'), 'N/A');
    END IF;
    -- Feeds
    IF NEW.feeds_weight <= max_feeds_t * 0.10 THEN
        INSERT INTO alert_history (parameter, threshold, reading, actuator)
        VALUES ('Feeds', CONCAT(max_feeds_t, ' kg'), CONCAT(NEW.feeds_weight, ' kg'), 'N/A');
    END IF;
    -- Water
    IF final_water_weight <= max_water_t * 0.10 THEN
        INSERT INTO alert_history (parameter, threshold, reading, actuator)
        VALUES ('Water', CONCAT(max_water_t, ' kg'), CONCAT(final_water_weight, ' kg'), 'N/A');
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `combined_trigger_after_insert` AFTER INSERT ON `sensor_data` FOR EACH ROW BEGIN
    -- Variables to hold thresholds and states
    DECLARE max_temp_threshold INT;
    DECLARE max_humid_threshold INT;
    DECLARE min_volts FLOAT;
    DECLARE light_duration_threshold INT;
    DECLARE current_duration INT;
    DECLARE led_duration_counter INT;
    DECLARE is_auto INT;

    -- Variables for actuator states
    DECLARE fan_state INT DEFAULT 0;
    DECLARE led_bulb_state INT DEFAULT 0;

    -- Fetch 'isAuto' state
    SELECT isAuto INTO is_auto FROM tools_state ORDER BY id DESC LIMIT 1;

    -- Proceed only if 'Auto Mode' is enabled
    IF is_auto = 1 THEN
        -- Fetch temperature and humidity thresholds
        SELECT max_temp, max_humid INTO max_temp_threshold, max_humid_threshold FROM thresholds ORDER BY id DESC LIMIT 1;

        -- Check temperature and humidity conditions
        IF NEW.temperature > max_temp_threshold THEN
            SET fan_state = 1;
        END IF;

        IF NEW.humidity > max_humid_threshold THEN
            SET fan_state = 1;
        END IF;

        -- Fetch light thresholds and durations
        SELECT min_light_volts, light_duration INTO min_volts, light_duration_threshold FROM thresholds ORDER BY id DESC LIMIT 1;
        SELECT daylight_duration, led_duration INTO current_duration, led_duration_counter FROM light_calculation ORDER BY id DESC LIMIT 1;

        -- Convert light duration threshold (hours to minutes)
        SET light_duration_threshold = light_duration_threshold * 60;

        -- Handle light compensation logic
        IF NEW.light >= min_volts THEN
            -- Reset counters if LED was compensating
            IF led_duration_counter > 0 THEN
                SET current_duration = 0;
                UPDATE light_calculation SET led_duration = 0;
            END IF;

            -- Increment daylight duration
            SET current_duration = current_duration + 3;
            UPDATE light_calculation SET daylight_duration = current_duration;

            -- Turn OFF LED during daytime
            SET led_bulb_state = 0;

        ELSE
            -- Nighttime light compensation logic
            IF (light_duration_threshold - current_duration) > 0 
               AND (light_duration_threshold - current_duration) != light_duration_threshold THEN

                -- Increment LED duration if needed
                IF led_duration_counter < (light_duration_threshold - current_duration) THEN
                    SET led_duration_counter = led_duration_counter + 3;
                    UPDATE light_calculation SET led_duration = led_duration_counter;

                    -- Turn ON LED for compensation
                    SET led_bulb_state = 1;
                ELSE
                    -- Reset counters once light compensation is complete
                    UPDATE light_calculation SET daylight_duration = 0, led_duration = 0;

                    -- Turn OFF LED
                    SET led_bulb_state = 0;
                END IF;
            ELSE
                -- No compensation needed, turn OFF LED
                SET led_bulb_state = 0;
            END IF;
        END IF;

        -- Insert final actuator states into the actuator_states table
        INSERT INTO actuator_states (fan, led_bulb)
        VALUES (fan_state, led_bulb_state);
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `sensor_data_to_scan_history` AFTER INSERT ON `sensor_data` FOR EACH ROW BEGIN
    -- Create variables to hold thresholds
    DECLARE mq9_min FLOAT;
    DECLARE mq9_max FLOAT;
    DECLARE mq135_min FLOAT;
    DECLARE mq135_max FLOAT;

    -- Create variables to hold normalized values
    DECLARE mq9_norm FLOAT DEFAULT 0;
    DECLARE mq135_norm FLOAT DEFAULT 0;

    -- Create variables to hold weights
    DECLARE mq9_w FLOAT DEFAULT 0.5;
    DECLARE mq135_w FLOAT DEFAULT 0.5;

    -- Create variable to hold final data
    DECLARE total FLOAT DEFAULT 0;

    DECLARE threshold INT;
    DECLARE latest_eggs_detected INT;
    DECLARE latest_raw_weight FLOAT;
    DECLARE final_water_weight FLOAT;

    -- Retrieve thresholds value
    SELECT min_mq9, max_mq9, min_mq135, max_mq135, egg_range
    INTO mq9_min, mq9_max, mq135_min, mq135_max, threshold
    FROM thresholds
    ORDER BY id DESC LIMIT 1;

    SELECT raw_weight INTO latest_raw_weight 
    FROM water_calibration 
	ORDER BY id DESC LIMIT 1;

    SET final_water_weight = NEW.water_weight - latest_raw_weight;

    -- Normalize data only if thresholds are valid
    IF mq9_max > mq9_min THEN
        SET mq9_norm = (NEW.mq9 - mq9_min) / (mq9_max - mq9_min);
    END IF;

    IF mq135_max > mq135_min THEN
        SET mq135_norm = (NEW.mq135 - mq135_min) / (mq135_max - mq135_min);
    END IF;

    -- Ensure values stay within the 0-1 range
    SET mq9_norm = GREATEST(0, LEAST(mq9_norm, 1));
    SET mq135_norm = GREATEST(0, LEAST(mq135_norm, 1));

    -- Combine data
    SET total = (mq9_norm * mq9_w) + (mq135_norm * mq135_w);

    IF NEW.egg_range <= threshold THEN
        SET latest_eggs_detected = 0;
    ELSEIF NEW.egg_range > threshold THEN
        SET latest_eggs_detected = 1;
    END IF;

    -- Insert final data into scan_history
    INSERT INTO scan_history (air_quality, eggs_detected, temperature, humidity, light, feeds_weight, water_weight)
    VALUES (total, latest_eggs_detected, NEW.temperature, NEW.humidity, NEW.light, NEW.feeds_weight, final_water_weight);

    INSERT INTO egg_detection (eggs_detected) VALUES (latest_eggs_detected);
    
    INSERT INTO water_calibration (water_weight, raw_weight, final_water_weight)
    VALUES (NEW.water_weight, latest_raw_weight, final_water_weight);

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `thresholds`
--

CREATE TABLE `thresholds` (
  `id` int(11) NOT NULL,
  `time` datetime NOT NULL DEFAULT current_timestamp(),
  `min_temp` int(11) NOT NULL,
  `max_temp` int(11) NOT NULL,
  `min_humid` int(11) DEFAULT NULL,
  `max_humid` int(11) NOT NULL,
  `min_light_volts` float NOT NULL,
  `light_duration` int(11) NOT NULL,
  `max_feeds` float NOT NULL,
  `max_water` float NOT NULL,
  `min_mq9` float NOT NULL,
  `min_mq135` float NOT NULL,
  `max_mq9` float NOT NULL,
  `max_mq135` float NOT NULL,
  `pollution_norm` float DEFAULT NULL,
  `egg_range` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tools_state`
--

CREATE TABLE `tools_state` (
  `id` int(11) NOT NULL,
  `time` datetime NOT NULL DEFAULT current_timestamp(),
  `isAuto` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `water_calibration`
--

CREATE TABLE `water_calibration` (
  `id` int(11) NOT NULL,
  `time` datetime NOT NULL DEFAULT current_timestamp(),
  `water_weight` float DEFAULT NULL,
  `raw_weight` float DEFAULT NULL,
  `final_water_weight` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `actuator_states`
--
ALTER TABLE `actuator_states`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `alert_history`
--
ALTER TABLE `alert_history`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `egg_detection`
--
ALTER TABLE `egg_detection`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `light_calculation`
--
ALTER TABLE `light_calculation`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `scan_history`
--
ALTER TABLE `scan_history`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sensor_data`
--
ALTER TABLE `sensor_data`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `thresholds`
--
ALTER TABLE `thresholds`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tools_state`
--
ALTER TABLE `tools_state`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `water_calibration`
--
ALTER TABLE `water_calibration`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `actuator_states`
--
ALTER TABLE `actuator_states`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `alert_history`
--
ALTER TABLE `alert_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `egg_detection`
--
ALTER TABLE `egg_detection`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `light_calculation`
--
ALTER TABLE `light_calculation`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scan_history`
--
ALTER TABLE `scan_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sensor_data`
--
ALTER TABLE `sensor_data`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `thresholds`
--
ALTER TABLE `thresholds`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tools_state`
--
ALTER TABLE `tools_state`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `water_calibration`
--
ALTER TABLE `water_calibration`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
