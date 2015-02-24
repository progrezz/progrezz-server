require 'neo4j'

module Game
  module Database

    class User
      include Neo4j::ActiveNode
      
      # -------------------------
      #      Atributos (DB)
      # -------------------------
      property :user_id, constraint: :unique  # Identificador de usuario (correo, �nico en la BD)
      property :alias                         # Alias o nick del usuario.
      property :created_at                    # Timestamp o fecha de creaci�n del usuario.

      # -------------------------
      #     Relaciones (DB)
      # -------------------------
      has_one :out, :geolocation, model_class: Geolocation, type: "is_located_at" # Posici�n del jugador

      # -------------------------
      #    M�todos de clase
      # -------------------------

      # Creaci�n de nuevos usuarios
      # al  -> alias
      # uid -> identificador de usuario (correo)
      def self.sign_in(al, uid)
        begin
          user = create( {alias: al, user_id: uid } );
          user.geolocation = Geolocation.create_geolocation();

        rescue Exception => e
          raise "DB ERROR: Cannot create user '" + al + " with unique id '" + uid + "': \n\t" + e.message;
        end
        
        return user
      end

      # -------------------------
      #        M�todos
      # -------------------------

      # Stringificar objeto
      def to_s
        return "<User: " + self.user_id + ", " + self.alias + ", [" + self.geolocation.to_s + "]>" 
      end
    end
  end
end
