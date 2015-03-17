# encoding: UTF-8

ENV['RACK_ENV'] = 'test'

require './main'
require 'test/unit'
require 'rack/test'

require_relative 'helpers'

class WebSocketTest < Test::Unit::TestCase
  include Rack::Test::Methods

  # Iniciar aplicación como "app"
  def app; Sinatra::ProgrezzServer end

  # WebSocket request method
  def ws_request()
    Sinatra::API::WebSocket::Methods.send( @request[:request][:type].to_s, app, @response, @session )
    GenericUtils.symbolize_keys_deep!(@response)
  end
  
  # ---------------------------
  #           Setup
  # ---------------------------
  
  # Inicializar antes de cada prueba.
  def setup
    # Setup database
    init_db()
    
    # Setup other things.
    @request = {
      metada: {},
      request: { }
    }
    
    @response = {
      metadata: {},
      request: @request,
      response: {}
    }
    
    @session = { user_id: "test" }
  end
  
  # Cerrar antes de cada prueba
  def teardown
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    
    # Deshacer cambios en la base de datos.
    drop_db()
  end
  
  # ---------------------------
  #            User
  # ---------------------------
  
  # Probar "user_update_geolocation"
  def test_user_update_geolocation
    authenticate()
    
    @request[:request][:type] = "user_update_geolocation"
    @request[:request][:data] = { user_id: "test", latitude: 23, longitude: -16 }
    ws_request()
    
    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:message], "User geolocation changed to 23.0, -16.0"
  end
  
  
end