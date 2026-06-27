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
        
        # Usa schtasks.exe com o comando PowerShell sem aspas aninhadas
        $schtaskCommand = "schtasks /create /tn `"$Nome`" /tr `"powershell.exe -Command Start-Process '$CaminhoExecutavel' -WindowStyle Hidden`" /sc onstart /ru SYSTEM /rl HIGHEST /f"
        
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
