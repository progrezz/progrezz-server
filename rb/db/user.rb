# encoding: UTF-8

require_relative 'geolocated_object'

module Game
  module Database
    
    #-- Forward declarations #++
    class Message; end
    
    # Clase que representa a un jugador cualquiera en la base de datos.
    #
    # Se caracteriza por estar enlazado con diversos tipos de nodos, 
    # además de tener una serie de propiedades o atributos.
    #
    # Se considera un objeto geolocalizado.
    class User < GeolocatedObject
      include Neo4j::ActiveNode
      
      #-- -------------------------
      #        Atributos (DB)
      #   ------------------------- #++
      property :user_id, constraint: :unique  # Identificador de usuario (correo, único en la BD)
      property :alias                         # Alias o nick del usuario.
      property :created_at                    # Timestamp o fecha de creación del usuario.

      #-- -------------------------
      #     Relaciones (DB)
      #   ------------------------- #++
      
      # Relación con mensajes creados por el usuario. Se puede acceder con el atributo +written_messages+.
      has_many :out, :written_messages, model_class: Game::Database::Message, type: "has_written"

      #-- -------------------------
      #      Métodos de clase
      #   ------------------------- #++

      # Creación de nuevos usuarios.
      #
      # En caso de error, lanzará una excepción como una String (Exception).
      #
      # * *Argumentos* :
      #   - +al+: Alias o nick del usuario.
      #   - +uid+: Identificador de usuario (correo electrónico).
      def self.sign_up(al, uid)
        begin
          user = create( {alias: al, user_id: uid });
          user.geolocation = Geolocation.create_geolocation();
          
        rescue Exception => e
          raise "DB ERROR: Cannot create user '" + al + " with unique id '" + uid + "': \n\t" + e.message;
        end
        
        return user
      end

      #-- -------------------------
      #          Métodos
      #   ------------------------- #++
      
      # Añadir nuevo mensaje.
      # * *Argumentos* :
      #   - +message+: Nuevo mensaje a añadir, de tipo +Game::Database::Message+.
      def add_msg(message)
        self.written_messages << message
      end

      # Stringificar objeto.
      #
      # * *Retorna* :
      #   - Objeto como string, con el formato "<User +user_id+,+alias+,+geolocation+>".
      def to_s
        return "<User: " + self.user_id + ", " + self.alias + ", " + super.to_s + ">" 
      end
    end
  end
end