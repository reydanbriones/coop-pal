<?php
    // set_actuator_states.php

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
        $fan = isset($_POST['fan']) ? intval($_POST['fan']) : null;
        $led = isset($_POST['led']) ? intval($_POST['led']) : null;

        if ($fan !== null && $led !== null) {
            // SQL query to insert the state into the actuators_state table
            $sql = "INSERT INTO actuator_states (fan, led_bulb) VALUES ('$fan', '$led')";

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