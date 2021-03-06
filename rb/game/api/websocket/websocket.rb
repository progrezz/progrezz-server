# encoding: UTF-8

require 'date'
require 'sinatra-websocket'

module Sinatra

  module API
    
  # Módulo de la API WebSocket para hacer peticiones al servidor.
  module WebSocket
    
    # Clase contenedora de los métodos diversos de la API WebSocket.
    #
    # Los websockets se abrirán accediendo a la URI /dev/api/websocket
    #
    # @see http://progrezz-server.heroku.com/dev/websocket
    class Methods
    end

    # Registrar yconfigurar la API WebSocket.
    #
    # Se registrarán todos los métodos incluídos
    # en el módulo Sinatra::API::WebSocket::Methods.
    #
    # @param app [Sinatra::Application] Aplicación sinatra.
    def self.registered(app)
      # Clase contenedora de métodos
      methods = Sinatra::API::WebSocket::Methods.new()
      
      # Acceso mediante método GET
      app.get '/dev/api/websocket' do
        content_type :json  # Tipo de respuesta: JSON.
        
        ws_manager    = Game::API::WebSocket::WebSocketManager

        # Si la petición no es de un websocket, rechazar
        if !request.websocket?
          output = Game::API::JSONResponse.get_template()
          Game::API::JSONResponse.error_response!(output, "Invalid request: Not a websocket request.")
          output[:metadata][:type] = "system"
          
          return output
        else
          request.websocket do |ws|
            # Petición de apertura.
            ws.onopen do
              # Si no está autenticado, rechazar.
              ws_manager.auth_user(session, ws)
            end
            
            # Petición de mensaje.
            ws.onmessage do |msg|
              # Si deja de estar autenticado, cerrar socket.
              if !ws_manager.force_close_if_no_auth(session, ws)
                return
              end
              
              # Respuesta al usuario
              response = Game::API::JSONResponse.get_template()
              
              # Métodos WS
              methods = Methods.new()

              Game::Database::DatabaseManager.run_nested_transaction do |tx|
                # Tipo de petición
                begin
                                
                # Preparar petición JSON
                request = nil
                begin
                  request = JSON.parse(msg)
                rescue Exception => e
                  throw "Cannot parse request: " + e.message
                end
                
                GenericUtils.symbolize_keys_deep!( request )
                response[:request] = request
                
                if ENV['users_auth_disabled'] == "true"
                  puts "Warning!! Users auth disabled!"
                  session['user_id'] = request[:user_id]
                end
                  
                  method = request[:request][:type].to_s
        
                  if method == ""
                    raise ::GenericException.new( "Invalid ws request type '" + method + "'" )
                  else
                    Methods.send( "ws__" + method, app, response, session )
                  end
                  
                  # TODO: Implementar (como en REST). Cabe la posibilidad de compatibilizar los métodos REST en este apartado.
                  
                rescue Exception => e
                  # Deshacer transacción.
                  tx.failure()
                  
                  # Generar error
                  Game::API::JSONResponse.error_response!( response, e.message )
                  
                  # Añadir parámetros adicionales
                  response[:response][:backtrace] = e.backtrace
                end
              end
              
              # Parar temporizador
              Game::API::JSONResponse.stop_timer!( response )
              
              # Eliminar "request" de la respuesta.
              response.delete(:request)
              
              # Y Enviar mensaje
              ws_manager.send(ws, response)
            end
            
            # Petición de cierre.
            ws.onclose do
              ws_manager.close(session, ws)
            end
          end
        end
      end

      # Método POST (no activado)
      # post '/dev/api/rest/user' { }

      # Peticiones REST interactivas
      app.get "/dev/websocket" do
        # Parsear métodos REST
        class << app
          attr_accessor :websocket_methods
        end
        
        if app.websocket_methods == nil
          app.websocket_methods = JSON.parse( File.read('data/websocket_methods.json') )
        end
        
        erb :"dev/websocket", :locals => {
          :session => session,
          :websocket_methods => app.websocket_methods
        }, :layout => :"dev/layout"
      end
    end
  end
  end

  #-- Registrar rutas sinatra #++
  register API::WebSocket
end

class Sinatra::ProgrezzServer
  register Sinatra::API::WebSocket
end
#-- Cargar en el servidor #++