#requires -Version 5.1
# Minimal static file server for local preview (no Python/Node needed on this machine).
param(
    [int]$Port = 8642,
    [string]$Root = (Join-Path $PSScriptRoot "..\site")
)

$Root = (Resolve-Path $Root).Path
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $Root at http://localhost:$Port/ (Ctrl+C to stop)"

$mimeTypes = @{
    ".html" = "text/html"; ".css" = "text/css"; ".js" = "application/javascript"
    ".png" = "image/png"; ".jpg" = "image/jpeg"; ".jpeg" = "image/jpeg"
    ".svg" = "image/svg+xml"; ".pdf" = "application/pdf"; ".ico" = "image/x-icon"
    ".woff" = "font/woff"; ".woff2" = "font/woff2"; ".json" = "application/json"
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $req = $context.Request
    $res = $context.Response
    try {
        $path = $req.Url.AbsolutePath.TrimStart("/")
        if ([string]::IsNullOrEmpty($path)) { $path = "index.html" }
        $fullPath = Join-Path $Root $path
        $resolved = [System.IO.Path]::GetFullPath($fullPath)
        if (-not $resolved.StartsWith($Root)) {
            $res.StatusCode = 403
        } elseif (Test-Path $resolved -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($resolved).ToLower()
            $contentType = $mimeTypes[$ext]
            if (-not $contentType) { $contentType = "application/octet-stream" }
            $res.ContentType = $contentType
            $bytes = [System.IO.File]::ReadAllBytes($resolved)
            $res.ContentLength64 = $bytes.Length
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $res.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $path")
            $res.OutputStream.Write($msg, 0, $msg.Length)
        }
    } catch {
        $res.StatusCode = 500
    } finally {
        $res.OutputStream.Close()
    }
}
