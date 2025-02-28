<?php
    // set_thresholds.php

    header("Access-Control-Allow-Origin: *");
    header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type, Authorization");
    header("Content-Type: application/json");

    // Database connection settings
    $host = "localhost";
    $username = "root";
    $password = "";
    $dbname = "coop_pal";

    // Create connection
    $conn = new mysqli($host, $username, $password, $dbname);

    // Check connection
    if ($conn->connect_error) {
    die(json_encode([
        "status" => "error",
        "message" => "Database connection failed: " . $conn->connect_error
    ]));
    }

    // Check if the request is POST
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {

        // Retrieve state from POST data
        $parameter = isset($_POST['parameter']) ? $conn->real_escape_string($_POST['parameter']) : null;
        $value_1 = isset($_POST['value_1']) ? floatval($_POST['value_1']) : null;
        $value_2 = isset($_POST['value_2']) ? floatval($_POST['value_2']) : null;

        if ($parameter !== null) {
            // SQL query to insert
            if ($parameter == "temperature") {
                $sql = "INSERT INTO thresholds (min_temp, max_temp, min_humid, max_humid, min_light_volts, light_duration, max_feeds, max_water,
                                                min_mq9, min_mq135, max_mq9, max_mq135, pollution_norm, egg_range)
                        SELECT  $value_1, $value_2, min_humid, max_humid, min_light_volts, light_duration, max_feeds, max_water,
                                min_mq9, min_mq135, max_mq9, max_mq135, pollution_norm, egg_range
                        FROM thresholds
                        ORDER BY id DESC
                        LIMIT 1;";
            }
            else if ($parameter == "humidity") {
                $sql = "INSERT INTO thresholds (min_temp, max_temp, min_humid, max_humid, min_light_volts, light_duration, max_feeds, max_water,
                                                min_mq9, min_mq135, max_mq9, max_mq135, pollution_norm, egg_range)
                        SELECT  min_temp, max_temp, $value_1, $value_2, min_light_volts, light_duration, max_feeds, max_water,
                                min_mq9, min_mq135, max_mq9, max_mq135, pollution_norm, egg_range
                        FROM thresholds
                        ORDER BY id DESC
                        LIMIT 1;";
            }
            else if ($parameter == "light") {
                $sql = "INSERT INTO thresholds (min_temp, max_temp, min_humid, max_humid, min_light_volts, light_duration, max_feeds, max_water,
                                                min_mq9, min_mq135, max_mq9, max_mq135, pollution_norm, egg_range)
                        SELECT  min_temp, max_temp, min_humid, max_humid, min_light_volts, $value_1, max_feeds, max_water,
                                min_mq9, min_mq135, max_mq9, max_mq135, pollution_norm, egg_range
                        FROM thresholds
                        ORDER BY id DESC
                        LIMIT 1;";
            }

            if ($conn->query($sql) === TRUE) {
                echo json_encode([
                    "status" => "success",
                    "message" => "State updated successfully."
                ]);
            } else {
                echo json_encode([
                    "status" => "error",
                    "message" => "Failed to update state: " . $conn->error
                ]);
            }
        } else {
            echo json_encode([
                "status" => "error",
                "message" => "Invalid input. State is required."
            ]);
        }
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "Invalid request method. Use POST."
        ]);
    }

    $conn->close();
?>