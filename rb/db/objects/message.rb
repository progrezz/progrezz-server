# encoding: UTF-8

require_relative 'user'
require_relative 'message_fragment'
require_relative '../relations/user-completed_message'

module Game
  module Database
    
    # Clase que representa a un mensaje en la base de datos.
    #
    # Se caracteriza por estar enlazado con diversos tipos de nodos, principalmente con
    # un autor y una serie de fragmentos geolocalizados.
    class Message
      include Neo4j::ActiveNode
      
      #-- -------------------------
      #        Constantes
      #   ------------------------- #++
      
      # Nombre de autor desconocido.
      NO_AUTHOR = "?"
      # Nombre de recurso no especificado.
      NO_RESOURCE = ""
      
      # Tamaño mínimo del contenido.
      CONTENT_MIN_LENGTH = 9
      
      # Tamaño máximo del contenido.
      CONTENT_MAX_LENGTH = 255
      
      # Tamaño máximo del recurso.
      RESOURCE_MAX_LENGTH = 128
      
      
      #-- -------------------------
      #        Atributos (DB)
      #   ------------------------- #++
      
      # Identificador de mensaje (se usa el uuid de neo4j).
      #property :id_msg, constraint: :unique
      
      # Número total de fragmentos que tiene el mensaje.
      #
      # @return [Integer] Debe ser mayor que cero.
      property :total_fragments, type: Integer

      # Contenido del mensaje.
      #
      # @return [String].
      property :content, type: String
      
      # Recurso adicional (imagen, hipervínculo, ...).
      # Totalmente opcional.
      #
      # @return [String].
      property :resource_link, type: String
      
      # Timestamp o fecha de creación del mensaje.
      # @return [Integer] Milisegundos desde el 1/1/1970.
      property :created_at

      #-- -------------------------
      #       Relaciones (DB)
      #   ------------------------- #++
      
      # @!method author
      # Relación con un autor (#Game::Database::User). Se puede acceder con el atributo +author+.
      # @return [Game::Database::User]
      has_one :in, :author, model_class: Game::Database::User, origin: :written_messages
      
      # @!method fragments
      #
      # Relación con los fragmentos del mensaje (#Game::Database::MessageFragment).
      # Se puede acceder con el atributo #fragments. El enlace tiene nombre +is_fragmented_in+.
      # Si el mensaje se borra, desaparecerán todos los fragmentos.
      #
      # @return [Game::Database::MessageFragment] Fragmentos.
      has_many :out, :fragments, model_class: Game::Database::MessageFragment, type: "is_fragmented_in", dependent: :destroy

      # @!method owners
      # Relación con los usuarios que han completado este mensaje.
      # Se puede acceder con el atributo #owners.
      #
      # @return [Game::Database::RelationShips::UserCompletedMessage]
      has_many :in, :owners, rel_class: Game::Database::RelationShips::UserCompletedMessage, model_class: Game::Database::User
      
      #-- -------------------------
      #      Métodos de clase
      #   ------------------------- #++

      # Creación de nuevos mensajes.
      #
      # @param cont [String] Contenido del mensaje.
      # @param n_fragments [Integer] Número de fragmentos en el que se romperá el mensaje. Por defecto, 1.
      # @param resource [String] Recurso mediático (opcional).
      # @param custom_author [Game::Database::User] Autor del mensaje (opcional).
      #
      # @return [Game::Database::Message] Referencia al objeto creado en la base de datos, de tipo Game::Database::Message.
      def self.create_message(cont, n_fragments = 1, resource = nil, custom_author = nil, position = {latitude: 0, longitude:0 })
        begin
          message = create( {content: cont, total_fragments: n_fragments, resource_link: resource }) do |msg|
            if custom_author != nil
              custom_author.add_msg(msg)
            end
            
            # Para cada fragmento, se crea un nuevo nodo en la bd
            for fragment_index in 0...(msg.total_fragments) do
              Game::Database::MessageFragment.create_message_fragment(msg, fragment_index, position)
            end
          end

        rescue Exception => e
          puts e.to_s
          raise "DB ERROR: Cannot create message: \n\t" + e.message;
        end
        
        return message
      end
    
      #-- -------------------------
      #          Métodos
      #   ------------------------- #++
      
      # Getter del autor.
      #
      # @return [Game::Database::Author] Autor del mensaje. En caso de que no exista devolverá Game::Database::Message.NO_AUTHOR
      def get_author()
        if(self.author == nil); return NO_AUTHOR end
        return self.author
      end
      
      # Getter del alias del autor.
      #
      # @return [String] Alias del autor del mensaje. En caso de que no exista devolverá Game::Database::Message.NO_AUTHOR
      def get_author_alias()
        if(self.author == nil); return NO_AUTHOR end
        return self.author.alias
      end
      
      # Getter del recurso mediático.
      #
      # @return [String] Recurso mediático del mensaje. En caso de que no exista devolverá Game::Database::Message.NO_RESOURCE
      def get_resource()
        if(self.resource_link == nil); return NO_RESOURCE end
        return self.resource_link
      end
      
      # Getter formateado del mensaje conseguido por un usuario.
      #
      # Usado para la API REST.
      #
      # @return [Hash<Symbol, Object>] Hash con los datos referentes al mensaje completado por el usuario.
      def get_user_message(user_rel = nil)
        output = {
          id:              self.neo_id,
          author:          self.get_author_alias,
          author_id:       self.author != nil ? self.author.user_id : "",
          content:         self.content,
          resource:        self.get_resource,
          total_fragments: self.total_fragments,
          write_date:      self.created_at.strftime('%Q'),
        }
        
        if(user_rel != nil)
          output[:status]     = user_rel.status                    if user_rel.respond_to? :status
          output[:created_at] = user_rel.created_at.strftime('%Q') if user_rel.respond_to? :created_at
        end
        
        return output
      end
      
      # Transformar objeto a un hash
      #
      # @return [Hash<Symbol, Object>] Objeto como hash.
      def to_hash()
        return {
          uuid:            self.uuid,
          id:              self.neo_id,
          author:          self.get_author_alias,
          author_id:       self.author != nil ? self.author.user_id : "",
          content:         self.content,
          resource:        self.get_resource,
          total_fragments: self.total_fragments,
          write_date:      self.created_at.strftime('%Q')
        }
      end
      
      # Stringificar objeto.
      #
      # @return [String] Objeto como string, con el formato "<Message: +content+,+author+,+total_fragments+,+resource_link+>".
      def to_s()
        return "<Message: " + self.content + ", " + get_author() + ", " + self.total_fragments.to_s + ", " + get_resource() + ">" 
      end
    end
  end
end
