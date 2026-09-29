$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:5173/")
$listener.Start()

Write-Host "The Last Heart - passerelle Owlbear locale"
Write-Host "Adresse : http://127.0.0.1:5173"
Write-Host "Laisse cette fenetre ouverte pendant la partie."
Write-Host ""

$latest = "{}"

function Send-Response($response, [int]$statusCode, [string]$contentType, [string]$body) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    $response.StatusCode = $statusCode
    $response.ContentType = $contentType
    $response.ContentEncoding = [System.Text.Encoding]::UTF8
    $response.ContentLength64 = [long]$bytes.Length
    try {
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
    }
    finally {
        $response.Close()
    }
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $response.Headers["Access-Control-Allow-Origin"] = "*"
        $response.Headers["Access-Control-Allow-Methods"] = "GET,POST,OPTIONS"
        $response.Headers["Access-Control-Allow-Headers"] = "Content-Type, Access-Control-Request-Private-Network"
        $response.Headers["Access-Control-Allow-Private-Network"] = "true"
        $response.Headers["Cache-Control"] = "no-store"

        if ($request.HttpMethod -eq "OPTIONS") {
            Send-Response $response 204 "text/plain; charset=utf-8" ""
            continue
        }

        if ($request.HttpMethod -eq "POST" -and $request.Url.AbsolutePath -eq "/hp") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $reader.Dispose()

            try {
                $parsed = $body | ConvertFrom-Json
                if ($null -eq $parsed.players) { throw "Payload invalide" }
                $latest = $body
                Send-Response $response 200 "application/json; charset=utf-8" '{"ok":true}'
            }
            catch {
                Write-Host ("Payload invalide : " + $_.Exception.Message)
                Send-Response $response 400 "application/json; charset=utf-8" '{"ok":false}'
            }
            continue
        }

        if ($request.HttpMethod -eq "GET" -and $request.Url.AbsolutePath -eq "/hp") {
            Send-Response $response 200 "application/json; charset=utf-8" $latest
            continue
        }

        Send-Response $response 404 "application/json; charset=utf-8" '{"error":"not found"}'
    }
    catch {
        Write-Host ("Erreur : " + $_.Exception.Message)
        try {
            if ($null -ne $context -and $null -ne $context.Response) {
                $context.Response.Close()
            }
        } catch {}
    }
}