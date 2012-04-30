require File.dirname(__FILE__) + '/config/environment'
use Rack::Static, :urls => ['/images', '/stylesheets', '/javascripts', '/optimized'], :root => 'public'
run ActionController::Dispatcher.new

