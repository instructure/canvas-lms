module SFU #:nodoc:
  module Stats #:nodoc:
    module Routing #:nodoc:
      module MapperExtensions

        def stats_urls
          @set.add_route("/sfu/stats", {:controller => "stats", :action => "index"})
          @set.add_route("/sfu/stats/restricted", {:controller => "stats", :action => "restricted"})
          @set.add_route("/sfu/stats/courses/:term_id.:format", {:controller => "stats", :action => "courses"})
          @set.add_route("/sfu/stats/enrollments/:term_id/:enrollment_type.:format", {:controller => "stats", :action => "enrollments"})
        end

       end
    end
  end
end

ActionController::Routing::RouteSet::Mapper.send :include, SFU::Stats::Routing::MapperExtensions
