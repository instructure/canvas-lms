require 'canvas_crummy'

ActionController::Base.send :include, CanvasCrummy::ControllerMethods
ActionView::Base.send :include, CanvasCrummy::ViewMethods