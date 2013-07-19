module SFU #:nodoc:
  module Api
    module Routing #:nodoc:
      module MapperExtensions

        def api_urls
          @set.add_route("/sfu/api/course/:sis_id/:property", {:controller => "api", :action => "course", :property => nil, :format => 'json'})
          @set.add_route("/sfu/api/user/:sfu_id/:property", {:controller => "api", :action => "user", :property => nil, :format => 'json'})
          @set.add_route("/sfu/api/courses/teaching/:sfuid/:term", {:controller => "api", :action => "courses", :term => nil, :format => 'json'})
          @set.add_route("/sfu/api/course-data/:term/:query", {:controller => "course_data", :action => "search", :query => nil, :format => 'json'})
	        @set.add_route("/sfu/api/amaint/course/:sis_id/:property", {:controller => "amaint", :action => "course", :property => nil, :format => 'json'})
        end

	      def v1_urls
          @set.add_route("/sfu/api/v1/terms", {:controller => "term", :action => "all_terms", :format => 'json'})
          @set.add_route("/sfu/api/v1/terms/current", {:controller => "term", :action => "current_term", :format => 'json'})
          @set.add_route("/sfu/api/v1/terms/next/:num_terms", {:controller => "term", :action => "next_terms", :num_terms => 1, :format => 'json'})
          @set.add_route("/sfu/api/v1/terms/previous/:num_terms", {:controller => "term", :action => "next_terms", :num_terms => 1, :format => 'json'})
          @set.add_route("/sfu/api/v1/terms/:sis_id", {:controller => "term", :action => "term_by_sis_id", :format => 'json'})
          @set.add_route("/sfu/api/v1/course/:sis_id/:property", {:controller => "api", :action => "course", :property => nil, :format => 'json'})
          @set.add_route("/sfu/api/v1/user/:sfu_id/:property", {:controller => "api", :action => "user", :property => nil, :format => 'json'})
          @set.add_route("/sfu/api/v1/course-data/:term/:query", {:controller => "course_data", :action => "search", :query => nil, :format => 'json'})
          @set.add_route("/sfu/api/v1/amaint/user/:sfu_id/:property/:filter", {:controller => "amaint", :action => "user_info", :property => nil, :filter => nil, :format => 'json'})
          @set.add_route("/sfu/api/v1/amaint/course/:sis_id/:property", {:controller => "amaint", :action => "course_info", :property => nil, :format => 'json'})
        end

      end
    end
  end
end

ActionController::Routing::RouteSet::Mapper.send :include, SFU::Api::Routing::MapperExtensions
