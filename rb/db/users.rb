require 'neo4j'


module Game
  module Database

    class User
      include Neo4j::ActiveNode
      
      # -------------------------
      #      Atributos (DB)
      # -------------------------
      property :user_id, constraint: :unique  # Identificador de usuario (correo, �nico)
      property :alias                         # Sin usar.

      # -------------------------
      #    M�todos de clase
      # -------------------------
      def self.sign_in(al, uid)
        begin
          return create( {alias: al, user_id: uid} );
        rescue
          raise "DB ERROR: Cannot create user '" + al + "': '" + uid + "' is in use.";
        end

      end

    end
  end
end
