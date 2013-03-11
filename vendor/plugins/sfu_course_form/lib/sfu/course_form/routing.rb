module SFU #:nodoc:
  module CourseForm #:nodoc:
    module Routing #:nodoc:
      module MapperExtensions

        def course_form_urls
          @set.add_route("/sfu/course/new", {:controller => "course_form", :action => "new"})
          @set.add_route("/sfu/course/create", {:controller => "course_form", :action => "create"})
        end

       end
    end
  end 
end 

ActionController::Routing::RouteSet::Mapper.send :include, SFU::CourseForm::Routing::MapperExtensions
