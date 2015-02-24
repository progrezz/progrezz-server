# encoding: UTF-8

$LOAD_PATH << File.dirname(__FILE__) + "\n"

require 'sinatra'
require "sinatra/reloader" if development?

# Cargar datos referente a la base de datos
require './rb/db'

# Cargar datos referentes a la api REST
require './rb/rest'

# Método index de prueba
get '/' do
  erb :index, :locals => {:test => "Prueba" }
end

