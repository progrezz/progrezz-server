# encoding: UTF-8

# Requerir un directorio de ficheros fuente.
#
# Se buscar�n e incluir�n ficheros seg�n se indiquen en los par�metros.
# 
# * *Argumentos* :
#   - +dir_regexp+: Expresi�n regular de la carpeta a incluir.
#   - +msg+: Mensaje que se muestra antes de cargar el fichero. Si es nil, no se muestra nada.
def require_dir(dir_regexp, msg = nil)
  Dir["./rb/game/**/*.rb"].each {|file|
    if msg != nil; puts msg + file.split(/\.rb/)[0] end
    require file.split(/\.rb/)[0]
  }
end