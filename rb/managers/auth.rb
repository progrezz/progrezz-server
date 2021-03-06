# encoding: UTF-8

require 'omniauth-oauth2'

require 'date'
require 'uri'

module Game
  
  # Clase gestora de la autenticación de usuarios.
  #
  # Se hace uso de la API OmniAuth para registrar usuarios, y se guardarán
  # los datos de la sesión en las cookies de las sesiones de Ruby Sinatra.
  class AuthManager
        
    # Log de usuarios baneados.
    BAN_FILE = "tmp/ban.log"
    
    # Servicios disponibles.
    SERVICES = [:google_oauth2, :twitter, :github, :steam, :facebook]
    
    # Servicios cargados con OmniAuth.
    @@loaded_services
    
    # Iniciar módulos OmniAuth.
    #
    # Los datos referentes a los servicios se cargarán desde las variables de entorno siguientes:
    # - *google*: id: progrezz_google_id, secreto: progrezz_google_secret
    # - *github*: id: progrezz_github_id, secreto: progrezz_github_secret
    # - *twitter*: id: progrezz_twitter_id, secreto: progrezz_twitter_secret
    # 
    # @param service_exceptions [Array<Symbol>] Servicios (símbolos ruby) que no serán cargados. Por defecto, se cargarán todos los posibles. La lista de servicios se encuentra en SERVICES.
    def self.setup(service_exceptions = [] )
      @@loaded_services = []
      
      # Incluir o excluir google.
      for service in SERVICES
        if !service_exceptions.include? service
          @@loaded_services << service
        end
      end
      
    end
    
    # Getter de los servicios cargados.
    #
    # @return [Array<Symbol>] Lista o Array de símbolos de los servicios cargados (ej: [:google, :twitter, ...]).
    def self.get_loaded_services()
      return @@loaded_services
    end
    
    # Comprobar si un usuario está baneado.
    # @param user [Game::Database::User] Usuario a comprobar.
    # @return [Boolean] True si está baneado. False en caso contrario.
    def self.banned?(user)
      if user.banned_until != nil && DateTime.now < user.banned_until
        return true
      end
      
      return false
    end
    
    # Busca un usuario autenticado en la sesión actual.
    #
    # @param user_id [String] Identificador de usuario (correo electrónico).
    # @param session [Hash] Sesión de Ruby Sinatra.
    #
    # @return [Game::Database::User] Si el usuario existe y está autenticado en la sesión actual, devuelve una referencia al mismo. Si no, genera una excepción.
    def self.search_auth_user(user_id, session)
      user = Game::Database::User.search_user(user_id)
      
      if banned?(user)
        raise ::GenericException.new( "Current user '" + user_id + "' is banned until " + user.banned_until.to_s )
      end

      if ENV['users_auth_disabled'] == "true"
        puts "Warning!! Users auth disabled!"
      else
        if user.user_id != session[:user_id]
          error_msg = "You are NOT authenticated as '" + user.user_id + "'."
          if session[:user_id] != nil
            error_msg += " You are authenticated as '" + session[:user_id] + "'."
          end
          
          raise ::GenericException.new( error_msg )
        end
      end
      
      return user
    end
    
    # Dar de alta a un usuario.
    #
    # Si el usuario no existe, se creará una entrada en la base de datos.
    # Si el usuario ya existe, no se añadirá nada.
    #
    # @param user_id [String] Identificador del usuario (correo).
    # @param user_alias [String] Alias del usuario (nombre).
    def self.login(user_id, user_alias)
      begin
        # Buscar usuario
        user = Game::Database::User.search_user( user_id )
        
        # Actualizar perfil.
        user.update_profile( { :alias => user_alias } )
      rescue
        # Si no existe, añadir a la BD
        user = Game::Database::User.sign_up( user_alias, user_id )
      end
      
       if banned?(user)
        raise ::GenericException.new( "Current '" + user_id + "' is banned until " + user.banned_until.to_s )
      end
    end
    
    # Banear a un usuario.
    # @param user_id [String] Identificador del usuario.
    # @param ban_time_seconds [DateTime] Cantidad de segundos para banear al usuario.
    # @param ban_reason [String] Razón de bloqueo del usuario.
    def self.ban_user(user_id, ban_time_seconds, ban_reason = "")
      user = Game::Database::User.search_user( user_id )
      
      if(ban_time_seconds > 0)
        ban = DateTime.strptime((DateTime.now.to_time.to_i + ban_time_seconds).to_s,'%s')
        user.update( banned_until: ban, banned_reason: ban_reason )
        
        File.open(BAN_FILE, 'a') { |f|
          f.puts DateTime.now.to_s + " - Banned '" + user_id + "' " + ban_time_seconds.to_s + " seconds. Reason: '" + ban_reason + "'."
        }
      end
    end
    
    # Desbanear a un usuario.
    # @param user_id [String] Identificador del usuario.
    def self.unban_user(user_id)
      user = Game::Database::User.search_user( user_id )
      
      user.update( banned_until: 0, banned_reason: "" )
      File.open(BAN_FILE, 'a') { |f|
        f.puts DateTime.now.to_s + " - Unbanned '" + user_id + "'."
      }
    end
    
    # Lista de usuarios baneados.
    # @return [Array] Lista de referencias a usuarios baneados.
    def self.banned_users()
      return Game::Database::User.as(:u).where( "u.banned_until > {tnow}" ).params(tnow: DateTime.now.strftime("%s").to_i ).to_a
    end
    
    # Comprobar si el usuario actual está autenticado.
    #
    # @return [Boolean] true si es posible, false en caso contrario.
    def self.auth?(session)
      if ENV['users_auth_disabled'] == "true"
        puts "Warning!! Users auth disabled!"
        return true
      elsif session['user_id'] == nil
        return false
      end
      
      return true
    end
    
    # Obtener usuario actual
    def self.current_user(session)
      return session['user_id']
    end
    
    
  end
end

# Inicializar.
Game::AuthManager.setup( eval(ENV["progrezz_auth_disabled"].to_s) || [] )

module Sinatra
  
  # Métodos http de autenticación.
  module AuthMethods
    
    # Registrar páginas web necesarias.
    # @param app [Sinatra::Application] Aplicación sinatra.
    def self.registered(app)
      
      # Configuración Omniauth.
      # @return [Object]
      app.configure do
        app.enable :sessions
        app.set :session_secret, ENV['progrezz_secret']

        ::OmniAuth.config.on_failure do |env|
          message_key = env['omniauth.error.type']
          origin_query_param = env['omniauth.origin'] ? "&origin=#{CGI.escape(env['omniauth.origin'])}" : ""
          strategy_name_query_param = env['omniauth.error.strategy'] ? "&strategy=#{env['omniauth.error.strategy'].name}" : ""
          extra_params = env['omniauth.params'] ? "&#{env['omniauth.params'].to_query}" : ""
          new_path = "/auth/failure?message=#{message_key}#{origin_query_param}#{strategy_name_query_param}#{extra_params}"
          
          puts "----->", new_path, "<-----"
          Rack::Response.new(["302 Moved"], 302, 'Location' => new_path).finish
        end
        
        app.use OmniAuth::Builder do

          # Configurar Google Auth.
          if Game::AuthManager.get_loaded_services.include? :google_oauth2
            require 'omniauth-google-oauth2'
            provider :google_oauth2, ENV['progrezz_google_id'], ENV['progrezz_google_secret'], 
              :scope => "userinfo.email,userinfo.profile", :provider_ignores_state => true
          end
          
          # Configurar Twitter
          if Game::AuthManager.get_loaded_services.include? :twitter
            require 'omniauth-twitter'
            provider :twitter, ENV['progrezz_twitter_id'], ENV['progrezz_twitter_secret']
          end
          
          # Configurar GitHub
          if Game::AuthManager.get_loaded_services.include? :github
            require 'omniauth-github'
            provider :github, ENV['progrezz_github_id'], ENV['progrezz_github_secret'], scope: "user"
          end
          
          # Configurar Steam
          if Game::AuthManager.get_loaded_services.include? :steam
            require 'omniauth-steam'
            provider :steam, ENV['progrezz_steam_id']
          end
          
          # Configurar Facebook
          if Game::AuthManager.get_loaded_services.include? :facebook
            require 'omniauth-facebook'
            provider :facebook, ENV['progrezz_facebook_id'], ENV['progrezz_facebook_secret'], :scope => 'email,read_stream'
          end

          # ...
        end
      end
    
      # URL para cerrar la sesión.
      # @return [Object]
      app.get '/auth/logout' do
        session[:user_id] = session[:name] = session[:alias] = session[:url] = nil
        
        if (params["redirect"] != nil)
          redirect to(oparams["redirect"])
        else
          redirect back
        end
      end

      # Callback que será llamado por el servicio.
      # Se puede acceder a cualquier servicio con la URI "/auth/<servicio>" (ej: /auth/twitter o /auth/google_oauth2).
      app.route :get, :post, '/auth/:provider/callback' do
        # Recoger datos de auth.
        auth = request.env['omniauth.auth']
        session[:user_id] = auth['info'].email || params['provider'].to_s + "-" + auth['uid'].to_s  # ID -> correo (salvo steam)
        session[:name]    = auth['info'].name                  # Nombre completo
        session[:alias]   = auth['info'].nick || auth['info'].alias || auth['info'].name.split(' ')[0] # Coger como Alias la primera palabra.
        
        # Registrar el usuario en la base de datos.
        begin
          Game::AuthManager.login( session[:user_id], session[:alias] )
        rescue Exception => e
          session[:user_id] = session[:name] = session[:alias] = nil
          redirect_page = params["error_redirect"] || request.env["omniauth.origin"] || "/"

          if redirect_page.include? "?"
            redirect to(redirect_page + "&error_message=" + URI.escape(e.message, /\W/))
          else
            redirect to(redirect_page + "?error_message=" + URI.escape(e.message, /\W/))
          end
        end
        
        redirect_page = params["redirect"] || request.env["omniauth.origin"] || "/"
        
        # Redireccionar al usuario.
        redirect to(redirect_page)
        
      end
      
      # URL o callback de inicion de sesión fallido.
      app.get '/auth/failure' do

        error_message = nil

        error_message ||= params["message"] || ""
        redirect_page = params["error_redirect"] || params["origin"] || "/"
        
        if redirect_page.include? "?"
          redirect to(redirect_page + "&error_message=" + URI.escape(error_message, /\W/))
        else
          redirect to(redirect_page + "?error_message=" + URI.escape(error_message, /\W/))
        end
      end
      
    end
  end

  # Registrar en sinatra.
  register AuthMethods
end

class Sinatra::ProgrezzServer
  register Sinatra::AuthMethods
end
#-- Cargar en el servidor #++
