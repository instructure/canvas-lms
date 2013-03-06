module SfuApi #:nodoc:
  module Routing #:nodoc: 
    module MapperExtensions 

      def sfu_api
        @set.add_route("/sfu/api/course/:sis_id", {:controller => "sfu_api", :action => "course"})
        @set.add_route("/sfu/api/user/:sfu_id", {:controller => "sfu_api", :action => "user"})
      end

    end
  end 
end 

ActionController::Routing::RouteSet::Mapper.send :include, SfuApi::Routing::MapperExtensions
