# encoding: UTF-8

# Clase de utilidades gen�ricas.
class GenericUtils

  # Requerir un directorio de ficheros fuente.
  #
  # Se buscar�n e incluir�n ficheros seg�n se indiquen en los par�metros.
  # 
  # * *Argumentos* :
  #   - +dir_regexp+: Expresi�n regular de la carpeta a incluir.
  #   - +msg+: Mensaje que se muestra antes de cargar el fichero. Si es nil, no se muestra nada.
  def self.require_dir(dir_regexp, msg = nil)
    Dir[dir_regexp].each {|file|
      if msg != nil; puts msg + file.split(/\.rb/)[0] end
      require file.split(/\.rb/)[0]
    }
  end

  #-- ...  #++
end
