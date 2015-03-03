# encoding: UTF-8

if development?
  DEV = true
end

# Módulo que contiene estructuras referentes al juego (general).
module Game
# Módulo que contiene estructuras de datos referentes a la base de datos.
module Database
  
  # Lista de transacciones.
  @@transactions = []

  # Clase gestora de la base de datos.
  #
  # Se encarga de realizar tareas sencillas, como inicializar el acceso a la base
  # de datos neo4j, reiniciar su estado, etc.
  class DatabaseManager
    # Inicializa la base de datos.
    #
    # Si se encuentra la variable de entorno 'GRAPHENEDB_URL' (heroku), se usará dicha dirección como servidor
    # neo4j. En caso contrario, se usará (por defecto) el servidor loca, con el puerto 7474.
    def self.setup()
      #-- Cargar ficheros de objetos de la BD #++
      GenericUtils.require_dir("./rb/db/objects/**/*.rb", "Leyendo Objetos de DB: ")
      
      #-- Cargar ficheros de relaciones de la BD #++
      GenericUtils.require_dir("./rb/db/relations/**/*.rb", "Leyendo Objetos de DB: ")
      
      #-- Conectar a la base de datos #++
      neo4j_url = ENV['GRAPHENDB_URL'] || 'http://localhost:7474' # En Heroku, o en localhost
      uri = URI.parse(neo4j_url)
      server_url = "http://#{uri.host}:#{uri.port}"

      Neo4j::Session.open(:server_db, server_url, basic_auth: { username: uri.user, password: uri.password})
      
      # Iniciar transacción inicial
      @@transactions = Neo4j::Transaction.new
      @@transaction_start_time = Time.now
    end

    # Destruye todo el contenido de la base de datos.
    #
    # @warning ¡No se pueden revertir los cambios!
    def self.drop()
      self.force_save()
      Neo4j::Session.current._query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
    end
    
    # Guardar de manera forzada el contenido en la base de datos.
    #
    # Se ignorará el tiempo mínimo para guardar datos en la DB.
    def self.force_save()
      # Borrar y cancelar transacciones actuales.
      for tx in @@transactions do
        tx.fail()
        tx.close()
      end
      
      @@transactions = []
      
      if defined? DEV
        puts "--------------------------------------"
        puts "**        Forced saving DB          **"
        puts "--------------------------------------"
      end
    end
    
    # Iniciar una nueva transacción.
    #
    # * *Retorna*: 
    #   - Referencia a la transacción creada.
    def self.start_transaction()
      tx = Neo4j::Transaction.new
      @@transactions << tx
      return tx
    end
    
    # Termina y guarda una transacción.
    #
    # * *Argumentos*: 
    #   - +tx+: Referencia a la transacción.
    def self.stop_transaction(tx)
      @@transactions.delete(tx)
      tx.close()
    end
    
    # Deshace los cambios de una transacción (rollback).
    #
    # * *Argumentos*: 
    #   - +tx+: Referencia a la transacción.
    def self.rollback_transaction(tx)
      tx.fail()
    end
    
  end

  #-- Lanzar el método setup #++
  DatabaseManager.setup()
  DatabaseManager.save() # Empezar transacción.

end
end
