require 'sinatra'
require 'json'

get '/test_message' do
  message = Game::Database::Messages.new
  message.id_msg = 1
  message.total_fragments = 3
  message.content = "Habia una vez un pinguino chiquitito :)"
  message.resource_link = "http://www.example.com"
  message.id_user = 1
  message.save

  message_geo = Game::Database::MessageGeo.new
  message_geo.id_msg = 1
  message_geo.fragment_index = 1
  message_geo.latitude = 43.291310
  message_geo.longitude = -2.863652
  message_geo.save

  message_geo = Game::Database::MessageGeo.new
  message_geo.id_msg = 1
  message_geo.fragment_index = 2
  message_geo.latitude = 43.292074
  message_geo.longitude = -2.862922
  message_geo.save

  message_geo = Game::Database::MessageGeo.new
  message_geo.id_msg = 1
  message_geo.fragment_index = 3
  message_geo.latitude = 43.291373
  message_geo.longitude = -2.861903
  message_geo.save

  message_user = Game::Database::UserMessages.new
  message_user.id_msg = 1
  message_user.id_user = 1
  message_user.fragment_index = 1
  message_user.status = "obtained"
  message_user.save

  message_user = Game::Database::UserMessages.new
  message_user.id_msg = 1
  message_user.id_user = 1
  message_user.fragment_index = 2
  message_user.status = "obtained"
  message_user.save

  "Mensaje creado"
end


get '/test_list' do
  output = "Lista de mensajes:<br>"
  messages = Game::Database::Messages.all

  for message in messages
    output += message.id.to_s + " -> " + message.content + "<br>"
  end

  output
end
