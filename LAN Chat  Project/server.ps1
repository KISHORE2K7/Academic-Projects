$port = 3000

$ErrorActionPreference = "SilentlyContinue"
try {
    New-NetFirewallRule -DisplayName "Lumina LAN TCP" -Direction Inbound -LocalPort $port -Protocol TCP -Action Allow | Out-Null
} catch {}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$port/")
try {
    $listener.Start()
} catch {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$port/")
    $listener.Start()
}

$ipFinder = Test-Connection -ComputerName $env:COMPUTERNAME -Count 1 -ErrorAction SilentlyContinue
$ip = if ($ipFinder) { $ipFinder.IPv4Address.IPAddressToString } else { "localhost" }

Write-Host ""
Write-Host "=========================================="
Write-Host "🚀 Lumina Offline PowerShell Router RUNNING!"
Write-Host "📱 Open Browser on any LAN device and go to:"
Write-Host "👉 http://$ip:$port"
Write-Host "=========================================="

$messages = @()
$groups = @("General")

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $response.Headers.Add("Access-Control-Allow-Origin", "*")

        if ($request.Url.AbsolutePath -eq "/") {
            $path = Join-Path $PWD "index.html"
            $buffer = [System.IO.File]::ReadAllBytes($path)
            $response.ContentType = "text/html"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($request.Url.AbsolutePath -eq "/api/config") {
            $json = "{ `"url`": `"http://$ip:$port`" }"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($request.Url.AbsolutePath -eq "/sync") {
            $state = @{ groups = $groups; messages = $messages }
            $json = $state | ConvertTo-Json -Depth 5 -Compress
            if (-not $json) { $json = "{}" }
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($request.Url.AbsolutePath -eq "/send" -and $request.HttpMethod -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream)
            $body = $reader.ReadToEnd()
            if ($body) {
                $msgObj = $body | ConvertFrom-Json
                if ($msgObj.type -eq "join") {
                    if ($groups -notcontains $msgObj.group) { $groups += $msgObj.group }
                } else {
                    $messages += $msgObj
                }
            }
        }
        $response.Close()
    } catch {
        try { $response.Close() } catch {}
    }
}
