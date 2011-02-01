require File.join(File.dirname(__FILE__), *%w[.. lib crummy])
ActionController::Base.send :include, Crummy::ControllerMethods
ActionView::Base.send       :include, Crummy::ViewMethods
