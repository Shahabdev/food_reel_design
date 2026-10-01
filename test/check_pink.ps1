Add-Type -AssemblyName System.Drawing
Get-ChildItem assets\images\*.jpg | ForEach-Object {
    $bmp = New-Object System.Drawing.Bitmap($_.FullName)
    $reddish = 0
    $total = 0
    for ($x = 0; $x -lt $bmp.Width; $x += 20) {
        for ($y = 0; $y -lt $bmp.Height; $y += 20) {
            $p = $bmp.GetPixel($x, $y)
            $total++
            if ($p.R -gt 240 -and $p.G -lt 235 -and $p.B -lt 235) {
                $reddish++
            }
        }
    }
    $bmp.Dispose()
    Write-Host "$($_.Name): reddish pixels = $reddish / $total"
}
