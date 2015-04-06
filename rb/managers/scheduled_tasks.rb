# encoding: UTF-8

require 'rufus-scheduler'

module Game
  
  # Módulo para tareas programadas.
  module Schedule
    # Clase gestora de tareas programadas.
    class TasksManager
      
      # Clase gestora (rufus)
      @@scheduler = Rufus::Scheduler.new
      
      # Inicializar tareas programadas.
      def self.setup()

        #-- Cargar ficheros de objetos de la BD #++
        GenericUtils.require_dir("./rb/schedules/**/*.rb",   "Leyendo tareas programadas:      ")
        
        # Ejecutar todas las tareas programas.
        Tasks.public_methods.each do |m|
          if m.to_s.start_with? "schtsk"
            Tasks.send( m, @@scheduler )
          end
        end
      end
      
      # Escribir un mensaje en la consola del servidor.
      # @param str [String] Mensaje a mostrar.
      def self.tasks_msg(str)
        puts "----------------------------------"
        puts DateTime.now.strftime("%Y/%m/%d - %H:%M:%S") + " - Executing scheduled task: " + str.to_s
        puts "----------------------------------"
      end
      
    end
    
    # Tareas programadas a ejecutar (métodos estáticos).
    #
    # Los métodos deben incluir el prefijo +schtsk+.
    class Tasks
      
      # Eliminar mensajes caducados.
      # @param scheduler [Rufus::Scheduler] Gestor de tareas.
      def self.schtsk_remove_caducated_messages(scheduler)
        # Realizar todos los días, a las 04:00 am
        scheduler.cron '0 4 * * *' do
          
          Game::Schedule::TasksManager.tasks_msg("Removing caducated messages (" + Game::Database::Message.clear_caducated_messages().to_s + ").")
          
        end
        
      end
     
    end
    
  end
end

Game::Schedule::TasksManager.setup()