$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:5173/")
$listener.Start()

Write-Host "The Last Heart - passerelle Owlbear locale"
Write-Host "Adresse : http://127.0.0.1:5173"
Write-Host "Laisse cette fenetre ouverte pendant la partie."
Write-Host ""

$latest = "{}"

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET,POST,OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
        $response.Headers.Add("Cache-Control", "no-store")

        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 204
        }
        elseif ($request.HttpMethod -eq "POST" -and $request.Url.AbsolutePath -eq "/hp") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $reader.Close()

            try {
                $parsed = $body | ConvertFrom-Json
                if ($null -eq $parsed.players) { throw "Payload invalide" }
                $latest = $body
                $response.StatusCode = 200
                $out = [Text.Encoding]::UTF8.GetBytes('{"ok":true}')
            }
            catch {
                $response.StatusCode = 400
                $out = [Text.Encoding]::UTF8.GetBytes('{"ok":false}')
            }
        }
        elseif ($request.HttpMethod -eq "GET" -and $request.Url.AbsolutePath -eq "/hp") {
            $response.StatusCode = 200
            $out = [Text.Encoding]::UTF8.GetBytes($latest)
        }
        else {
            $response.StatusCode = 404
            $out = [Text.Encoding]::UTF8.GetBytes('{"error":"not found"}')
        }

        $response.ContentType = "application/json; charset=utf-8"
        $response.ContentLength64 = $out.Length
        $response.OutputStream.Write($out, 0, $out.Length)
        $response.OutputStream.Close()
    }
    catch {
        Write-Host ("Erreur : " + $_.Exception.Message)
    }
}
