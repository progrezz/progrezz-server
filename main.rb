# encoding: UTF-8

#-- Cargar ruta actual en la ruta de carga de fuentes. #++
$LOAD_PATH << File.dirname(__FILE__) + "\n"

require 'sinatra'
require "sinatra/reloader" if development?
require 'neo4j'

# Aplicación principal (servidor).
#
# Funciona como contenedor de una aplicación Ruby Sinatra.
class ProgrezzServer < Sinatra::Base
end

#-- Require especial (con expresiones regulares, para directorios). #++
require './rb/generic_utils'

#-- Cargar datos referente a la base de datos. #++
require './rb/db'

#-- Cargar datos referentes a la api REST. #++
require './rb/rest'

