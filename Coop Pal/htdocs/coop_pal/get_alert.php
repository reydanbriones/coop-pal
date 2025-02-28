<?php
// get_alert.php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
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
    die(json_encode(["status" => "error", "message" => "Database connection failed: " . $conn->connect_error]));
}

// Check if date is provided
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $selected_date = isset($_POST['selected_date']) ? $_POST['selected_date'] : null;

    if ($selected_date) {
        $sql = "SELECT * FROM alert_history WHERE date = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("s", $selected_date);
        $stmt->execute();
        $result = $stmt->get_result();

        $data = [];
        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }

        echo json_encode(["status" => "success", "data" => $data]);
        $stmt->close();
    } else {
        echo json_encode(["status" => "error", "message" => "Date is required."]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid request method. Use POST."]);
}

$conn->close();
?>