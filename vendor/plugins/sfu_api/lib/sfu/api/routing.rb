module SFU #:nodoc:
  module Api
    module Routing #:nodoc:
      module MapperExtensions
        def api_urls
          @set.add_route("/sfu/api/course/:sis_id/:property", {:controller => "api", :action => "course", :property => nil, :format => 'json'})
          @set.add_route("/sfu/api/user/:sfu_id/:property", {:controller => "api", :action => "user", :property => nil, :format => 'json'})
          @set.add_route("/sfu/api/courses/teaching/:sfuid/:term", {:controller => "api", :action => "courses", :term => nil, :format => 'json'})
        end

      end
    end
  end
end

ActionController::Routing::RouteSet::Mapper.send :include, SFU::Api::Routing::MapperExtensions
