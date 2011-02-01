ActionController::Base.send :include, Crummy::ControllerMethods
ActionView::Base.send       :include, Crummy::ViewMethods
