[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$blossomBase64 = 'TTI0OS4xNzYgMzIzLjQzNFYyOTguMjc2QzI0OS4xNzYgMjk2LjE1OCAyNDkuOTcxIDI5NC41NjkgMjUxLjgyNSAyOTMuNTA5TDMwMi40MDYgMjY0LjM4MUMzMDkuMjkgMjYwLjQwOSAzMTcuNSAyNTguNTU1IDMyNS45NzMgMjU4LjU1NUMzNTcuNzUgMjU4LjU1NSAzNzcuODc3IDI4My4xODUgMzc3Ljg3NyAzMDkuMzk5QzM3Ny44NzcgMzExLjI1MyAzNzcuODc3IDMxMy4zNzEgMzc3LjYxMSAzMTUuNDlMMzI1LjE3OCAyODQuNzcxQzMyMi4wMDEgMjgyLjkxOSAzMTguODIyIDI4Mi45MTkgMzE1LjY0NSAyODQuNzcxTDI0OS4xNzYgMzIzLjQzNFpNMzY3LjI4MyA0MjEuNDE1VjM2MS4zMDFDMzY3LjI4MyAzNTcuNTkyIDM2NS42OTQgMzU0Ljk0NSAzNjIuNTE2IDM1My4wOTJMMjk2LjA0OCAzMTQuNDNMMzE3Ljc2MyAzMDEuOTgyQzMxOS42MTcgMzAwLjkyNSAzMjEuMjA2IDMwMC45MjUgMzIzLjA1OCAzMDEuOTgyTDM3My42MzkgMzMxLjExMkMzODguMjA1IDMzOS41ODYgMzk4LjAwMyAzNTcuNTkyIDM5OC4wMDMgMzc1LjA2OUMzOTguMDAzIDM5NS4xOTUgMzg2LjA4NyA0MTMuNzMzIDM2Ny4yODMgNDIxLjQxMlY0MjEuNDE1Wk0yMzMuNTUzIDM2OC40NTJMMjExLjgzOCAzNTUuNzQyQzIwOS45ODYgMzU0LjY4NCAyMDkuMTkgMzUzLjA5NSAyMDkuMTkgMzUwLjk3NVYyOTIuNzE4QzIwOS4xOSAyNjQuMzgzIDIzMC45MDUgMjQyLjkzMiAyNjAuMzAxIDI0Mi45MzJDMjcxLjQyMyAyNDIuOTMyIDI4MS43NDggMjQ2LjY0MSAyOTAuNDkgMjUzLjI2TDIzOC4zMjEgMjgzLjQ0OUMyMzUuMTQ2IDI4NS4zMDMgMjMzLjU1NSAyODcuOTUxIDIzMy41NTUgMjkxLjY1OVYzNjguNDU1TDIzMy41NTMgMzY4LjQ1MlpNMjgwLjI5MiAzOTUuNDYyTDI0OS4xNzYgMzc3Ljk4NVYzNDAuOTEzTDI4MC4yOTIgMzIzLjQzNkwzMTEuNDA3IDM0MC45MTNWMzc3Ljk4NUwyODAuMjkyIDM5NS40NjJaTTMwMC4yODYgNDc1Ljk2OEMyODkuMTYzIDQ3NS45NjggMjc4LjgzNyA0NzIuMjU5IDI3MC4wOTcgNDY1LjY0TDMyMi4yNjQgNDM1LjQ0OUMzMjUuNDQxIDQzMy41OTcgMzI3LjAzIDQzMC45NDkgMzI3LjAzIDQyNy4yMzlWMzUwLjQ0NUwzNDkuMDExIDM2My4xNTVDMzUwLjg2NSAzNjQuMjEzIDM1MS42NiAzNjUuODAyIDM1MS42NiAzNjcuOTIyVjQyNi4xNzlDMzUxLjY2IDQ1NC41MTQgMzI5LjY3OSA0NzUuOTY1IDMwMC4yODYgNDc1Ljk2NVY0NzUuOTY4Wk0yMzcuNTI1IDQxNi45MTVMMTg2Ljk0NCAzODcuNzg1QzE3Mi4zNzggMzc5LjMxIDE2Mi41ODIgMzYxLjMwNSAxNjIuNTgyIDM0My44MjdDMTYyLjU4MiAzMjMuNDM2IDE3NC43NjMgMzA1LjE2NCAxOTMuNTYzIDI5Ny40ODVWMzU3Ljg2MUMxOTMuNTYzIDM2MS41NzEgMTk1LjE1NCAzNjQuMjE3IDE5OC4zMyAzNjYuMDcxTDI2NC41MzUgNDA0LjQ2N0wyNDIuODIgNDE2LjkxNUMyNDAuOTY3IDQxNy45NzIgMjM5LjM3NyA0MTcuOTcyIDIzNy41MjUgNDE2LjkxNVpNMjM0LjYxNCA0NjAuMzQzQzIwNC42ODkgNDYwLjM0MyAxODIuNzEgNDM3LjgzMyAxODIuNzEgNDEwLjAyOEMxODIuNzEgNDA3LjkxIDE4Mi45NzYgNDA1Ljc5MiAxODMuMjM4IDQwMy42NzJMMjM1LjQwNSA0MzMuODYzQzIzOC41ODIgNDM1LjcxNSAyNDEuNzYzIDQzNS43MTUgMjQ0LjkzOCA0MzMuODYzTDMxMS40MDcgMzk1LjQ2NlY0MjAuNjIyQzMxMS40MDcgNDIyLjc0MiAzMTAuNjEyIDQyNC4zMzEgMzA4Ljc1OCA0MjUuMzg5TDI1OC4xNzkgNDU0LjUxOUMyNTEuMjkzIDQ1OC40OTEgMjQzLjA4MyA0NjAuMzQzIDIzNC42MTEgNDYwLjM0M0gyMzQuNjE0Wk0zMDAuMjg2IDQ5MS44NTRDMzMyLjMyOSA0OTEuODU0IDM1OS4wNzMgNDY5LjA4MiAzNjUuMTY3IDQzOC44OTJDMzk0LjgyNSA0MzEuMjExIDQxMy44OTIgNDAzLjQwNiA0MTMuODkyIDM3NS4wNzNDNDEzLjg5MiAzNTYuNTM1IDQwNS45NDggMzM4LjUyOSAzOTEuNjQ4IDMyNS41NTJDMzkyLjk3MiAzMTkuOTkxIDM5My43NjYgMzE0LjQzIDM5My43NjYgMzA4Ljg3QzM5My43NjYgMjcxLjAwMyAzNjMuMDQ4IDI0Mi42NjYgMzI3LjU2MiAyNDIuNjY2QzMyMC40MTMgMjQyLjY2NiAzMTMuNTI4IDI0My43MjMgMzA2LjY0NCAyNDYuMTA5QzI5NC43MjUgMjM0LjQ1NyAyNzguMzA3IDIyNy4wNDIgMjYwLjMwMSAyMjcuMDQyQzIyOC4yNTggMjI3LjA0MiAyMDEuNTEzIDI0OS44MTUgMTk1LjQyIDI4MC4wMDRDMTY1Ljc2MSAyODcuNjg1IDE0Ni42OTQgMzE1LjQ5IDE0Ni42OTQgMzQzLjgyNEMxNDYuNjk0IDM2Mi4zNjIgMTU0LjYzOCAzODAuMzY4IDE2OC45MzggMzkzLjM0NEMxNjcuNjEzIDM5OC45MDYgMTY2LjgxOSA0MDQuNDY3IDE2Ni44MTkgNDEwLjAyN0MxNjYuODE5IDQ0Ny44OTQgMTk3LjUzOCA0NzYuMjMxIDIzMy4wMjQgNDc2LjIzMUMyNDAuMTcyIDQ3Ni4yMzEgMjQ3LjA1OCA0NzUuMTczIDI1My45NDMgNDcyLjc4OEMyNjUuODU5IDQ4NC40NDEgMjgyLjI3OCA0OTEuODU0IDMwMC4yODYgNDkxLjg1NFo='

Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing

$data = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($blossomBase64))
function New-IconImage([int]$pixelSize) {
    [double]$size = $pixelSize
    $inset = [Math]::Max(1.0, $size / 32.0)
    $visual = New-Object System.Windows.Media.DrawingVisual
    $context = $visual.RenderOpen()
    $context.DrawRoundedRectangle(
        [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(20, 23, 29)),
        [System.Windows.Media.Pen]::new([System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(89, 97, 110)), $inset),
        [System.Windows.Rect]::new($inset, $inset, $size - 2 * $inset, $size - 2 * $inset),
        $size / 4.0,
        $size / 4.0)

    $logo = [System.Windows.Media.Geometry]::Parse($data).Clone()
    $bounds = $logo.Bounds
    $scale = ($size * 0.84375) / [Math]::Max($bounds.Width, $bounds.Height)
    $logo.Transform = [System.Windows.Media.MatrixTransform]::new([System.Windows.Media.Matrix]::new(
        $scale,
        0,
        0,
        $scale,
        (($size - $bounds.Width * $scale) / 2 - $bounds.X * $scale),
        (($size - $bounds.Height * $scale) / 2 - $bounds.Y * $scale)))
    $context.DrawGeometry([System.Windows.Media.Brushes]::White, $null, $logo)
    $context.Close()

    $rendered = [System.Windows.Media.Imaging.RenderTargetBitmap]::new($pixelSize, $pixelSize, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
    $rendered.Render($visual)
    $encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
    $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($rendered))
    $stream = New-Object System.IO.MemoryStream
    $encoder.Save($stream)
    $bytes = $stream.ToArray()
    $stream.Dispose()
    [PSCustomObject]@{ Size = $pixelSize; Data = $bytes }
}

$frames = @(16, 20, 24, 32, 40, 48, 64, 128, 256 | ForEach-Object { New-IconImage $_ })
$directory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$file = [System.IO.File]::Create($OutputPath)
$writer = New-Object System.IO.BinaryWriter($file)
$writer.Write([uint16]0)
$writer.Write([uint16]1)
$writer.Write([uint16]$frames.Count)
$offset = 6 + 16 * $frames.Count
foreach ($frame in $frames) {
    [byte]$dimension = if ($frame.Size -eq 256) { 0 } else { $frame.Size }
    $writer.Write($dimension)
    $writer.Write($dimension)
    $writer.Write([byte]0)
    $writer.Write([byte]0)
    $writer.Write([uint16]1)
    $writer.Write([uint16]32)
    $writer.Write([uint32]$frame.Data.Length)
    $writer.Write([uint32]$offset)
    $offset += $frame.Data.Length
}
foreach ($frame in $frames) {
    $writer.Write($frame.Data)
}
$writer.Dispose()
