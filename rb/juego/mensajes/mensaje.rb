require 'data_mapper'

module Juego
  class Mensaje
    include DataMapper::Resource
    
    # -------------------------
    #        Atributos
    # -------------------------
    property :id, Serial       # Identificador de mensaje
    
    property :latitud,  Float  # Coordenada X
    property :longitud, Float  # Coordenada Y
    
    property :mensaje, String  # Mensaje en s�

    # -------------------------
    #         M�todos
    # -------------------------
    # ...
  end
end