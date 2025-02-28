<?php
    // set_tools_state.php

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
    $state = isset($_POST['state']) ? intval($_POST['state']) : null;

    if ($state !== null) {
        // SQL query to insert the state into the tools_state table
        $sql = "INSERT INTO tools_state (isAuto) VALUES ('$state')";

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