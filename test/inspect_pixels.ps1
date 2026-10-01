Add-Type -AssemblyName System.Drawing
Get-ChildItem assets\images\*.jpg | ForEach-Object {
    $bmp = New-Object System.Drawing.Bitmap($_.FullName)
    $p1 = $bmp.GetPixel(2, 2)
    $p2 = $bmp.GetPixel($bmp.Width - 3, 2)
    $p3 = $bmp.GetPixel(2, $bmp.Height - 3)
    $p4 = $bmp.GetPixel($bmp.Width - 3, $bmp.Height - 3)
    $bmp.Dispose()
    Write-Host "$($_.Name): ($($p1.R),$($p1.G),$($p1.B)) ($($p2.R),$($p2.G),$($p2.B)) ($($p3.R),$($p3.G),$($p3.B)) ($($p4.R),$($p4.G),$($p4.B))"
}
