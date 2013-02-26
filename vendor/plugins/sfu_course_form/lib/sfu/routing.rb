module SFU #:nodoc: 
  module Routing #:nodoc: 
    module MapperExtensions 

      def course_form
	@set.add_route("/sfu/course/new", {:controller => "course_form", :action => "new"})
        @set.add_route("/sfu/course/create", {:controller => "course_form", :action => "create"})
        @set.add_route("/sfu/course/:course_code/:term", {:controller => "course_form", :action => "course_info"})
        @set.add_route("/sfu/courses/:sfuid", {:controller => "course_form", :action => "courses"})
        @set.add_route("/sfu/courses/:sfuid/:term", {:controller => "course_form", :action => "courses"})
        @set.add_route("/sfu/terms/:sfuid", {:controller => "course_form", :action => "terms"})
        @set.add_route("/sfu/user/:sfuid", {:controller => "course_form", :action => "user"})
      end

    end
  end 
end 

ActionController::Routing::RouteSet::Mapper.send :include, SFU::Routing::MapperExtensions
