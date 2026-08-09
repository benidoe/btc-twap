Add-Type -AssemblyName System.Drawing

$size = 1024
$bmp = New-Object System.Drawing.Bitmap($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 13, 17, 23)) # GitHub dark #0d1117

# Green accent block (rounded rect)
$blockSize = 640
$x = ($size - $blockSize) / 2
$y = ($size - $blockSize) / 2
$radius = 170
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$path.AddArc($x, $y, $radius, $radius, 180, 90)
$path.AddArc($x + $blockSize - $radius, $y, $radius, $radius, 270, 90)
$path.AddArc($x + $blockSize - $radius, $y + $blockSize - $radius, $radius, $radius, 0, 90)
$path.AddArc($x, $y + $blockSize - $radius, $radius, $radius, 90, 90)
$path.CloseFigure()
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 63, 185, 80)) # #3fb950
$g.FillPath($brush, $path)

# BTC wordmark on the block
$font1 = New-Object System.Drawing.Font("Segoe UI", 230, [System.Drawing.FontStyle]::Bold)
$text1 = "BTC"
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$sf.LineAlignment = [System.Drawing.StringAlignment]::Center
$rect1 = [System.Drawing.RectangleF]::new($x, $y - 40, $blockSize, $blockSize)
$darkBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 13, 17, 23))
$g.DrawString($text1, $font1, $darkBrush, $rect1, $sf)

# TWAP caption below the block
$font2 = New-Object System.Drawing.Font("Segoe UI", 72, [System.Drawing.FontStyle]::Bold)
$text2 = "TWAP"
$sf2 = New-Object System.Drawing.StringFormat
$sf2.Alignment = [System.Drawing.StringAlignment]::Center
$sf2.LineAlignment = [System.Drawing.StringAlignment]::Near
$rect2 = [System.Drawing.RectangleF]::new(0, $y + $blockSize + 8, $size, 140)
$grayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 139, 148, 158)) # #8b949e
$g.DrawString($text2, $font2, $grayBrush, $rect2, $sf2)

$out = Join-Path $PSScriptRoot "..\ios\App\App\Assets.xcassets\AppIcon.appiconset\AppIcon-512@2x.png"
$out = [System.IO.Path]::GetFullPath($out)
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "wrote $out"

$g.Dispose()
$bmp.Dispose()
$brush.Dispose()
$darkBrush.Dispose()
$grayBrush.Dispose()
$font1.Dispose()
$font2.Dispose()
$path.Dispose()
