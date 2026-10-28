# 1. Ruta de las imágenes y archivo de salida
$rutaDirectorio = "C:\Users\Downloads\imagenes"
$archivoSalida  = "$rutaDirectorio\resultado_combinado.pdf"

# Si el PDF anterior existe, lo borramos para evitar conflictos
if (Test-Path $archivoSalida) { Remove-Item $archivoSalida }

# 2. Lista de las 3 imágenes
$nombresImagenes = @("1.jpeg", "2.jpeg", "3.jpeg")

# 3. Cargar librerías de .NET
Add-Type -AssemblyName System.Drawing

$doc = New-Object System.Drawing.Printing.PrintDocument
$doc.PrinterSettings.PrinterName = "Microsoft Print to PDF"
$doc.PrinterSettings.PrintToFile = $true
$doc.PrinterSettings.PrintFileName = $archivoSalida

# Usar ámbito de script para el contador
$script:contador = 0

$doc.add_PrintPage({
    param($sender, $e)
    if ($script:contador -lt $nombresImagenes.Count) {
        $rutaCompleta = Join-Path $rutaDirectorio $nombresImagenes[$script:contador]
        $img = [System.Drawing.Image]::FromFile($rutaCompleta)
        
        # --- CORREGIR ORIENTACIÓN EXIF (Metadatos de la foto) ---
        if ($img.PropertyIdList -contains 274) {
            $orientationItem = $img.GetPropertyItem(274)
            $orientation = [BitConverter]::ToInt16($orientationItem.Value, 0)
            
            switch ($orientation) {
                3 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
                6 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
                8 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
            }
        }
        # --------------------------------------------------------
        
        # Dibujar la imagen en la página
        $e.Graphics.DrawImage($img, $e.PageBounds)
        $img.Dispose()
        
        $script:contador++
        
        # Controlar si hay más páginas
        if ($script:contador -lt $nombresImagenes.Count) {
            $e.HasMorePages = $true
        } else {
            $e.HasMorePages = $false
        }
    } else {
        $e.HasMorePages = $false
    }
})

# 4. Ejecutar la impresión
try {
    $doc.Print()
    Write-Host "¡PDF creado con éxito y orientación corregida en: $archivoSalida!" -ForegroundColor Green
} catch {
    Write-Host "Ocurrió un error: $_" -ForegroundColor Red
}