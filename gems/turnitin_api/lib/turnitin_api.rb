require 'json'
require 'securerandom'
require 'simple_oauth'
require 'faraday'
require 'faraday_middleware'

module TurnitinApi
  require 'turnitin_api/version'
  require 'turnitin_api/outcomes_response_transformer'
end
