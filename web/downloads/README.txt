DevPlay — carpeta de binarios
=============================
Aquí se publican los archivos que ofrece el botón de descarga:

  devplay.apk            -> Android (flutter build apk --release)
  devplay-windows.zip    -> Windows (flutter build windows + zip)

Generación automática:
  powershell -ExecutionPolicy Bypass -File tool\build_releases.ps1

Mientras un archivo no exista, su tarjeta en la app dice "Próximamente".
