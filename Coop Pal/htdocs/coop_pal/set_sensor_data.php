<?php
// set_sensor_data.php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database connection settings
$host = "localhost";
$username = "root";
$password = "";
$dbname = "coop_pal";

// Create connection
$conn = new mysqli($host, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    echo json_encode([
        "status" => "error",
        "message" => "Database connection failed: " . $conn->connect_error
    ]);
    exit;
}

// Get data from POST request
if (isset($_POST['ldr_value'], $_POST['temperature'], $_POST['humidity'], $_POST['mq9'], $_POST['mq135'], $_POST['egg_range'],
    $_POST['water_weight'], $_POST['feeds_weight'])) {
    $ldr_value = $conn->real_escape_string($_POST['ldr_value']);
    $temperature = $conn->real_escape_string($_POST['temperature']);
    $humidity = $conn->real_escape_string($_POST['humidity']);
    $mq9 = $conn->real_escape_string($_POST['mq9']);
    $mq135 = $conn->real_escape_string($_POST['mq135']);
    $egg_range = $conn->real_escape_string($_POST['egg_range']);
    $water_weight = $conn->real_escape_string($_POST['water_weight']);
    $feeds_weight = $conn->real_escape_string($_POST['feeds_weight']);

    // Insert data into table
    $sql = "INSERT INTO `sensor_data`(`egg_range`, `light`, `temperature`, `humidity`, `mq9`, `mq135`, `feeds_weight`, `water_weight`) 
            VALUES ('$egg_range','$ldr_value', '$temperature', '$humidity', '$mq9', '$mq135', '$feeds_weight', '$water_weight')";

    if ($conn->query($sql) === TRUE) {
        echo json_encode(["status" => "success", "message" => "New record created successfully"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Error: " . $conn->error]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid or missing POST data"]);
}

$conn->close();