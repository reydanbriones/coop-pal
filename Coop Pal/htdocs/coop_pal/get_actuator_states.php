<?php
    // get_actuator_states.php
    
    header("Access-Control-Allow-Origin: *");
    header("Access-Control-Allow-Methods: GET, POST");
    header("Access-Control-Allow-Headers: Content-Type");
    header("Content-Type: application/json");
    
    // Database connection settings
    $host = "localhost";
    $username = "root";
    $password = "";
    $dbname = "coop_pal";

    // Create connection
    $conn = new mysqli($host, $username, $password, $dbname);
    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    }

    // Fetch data
    $sql = "SELECT *
            FROM actuator_states
            ORDER BY id DESC
            LIMIT 1";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        echo json_encode($row);
    } else {
        echo json_encode(["message" => "No data found"]);
    }

    // Close connection
    $conn->close();
?>