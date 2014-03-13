module SFU #:nodoc:
  module Copyright #:nodoc:
    module Routing #:nodoc:
      module MapperExtensions

        def copyright_urls
          @set.add_route("/sfu/copyright/disclaimer", {:controller => "copyright", :action => "disclaimer"})
        end

      end
    end
  end
end

ActionController::Routing::RouteSet::Mapper.send :include, SFU::Copyright::Routing::MapperExtensions
