CanvasRails::Application.routes.draw do
  match "/sfu/stats" => "stats#index"
  match "/sfu/stats/restricted" => "stats#restricted"
  match "/sfu/stats/courses(/:term_id(.:format))" => "stats#courses", :defaults => { :term => nil, :format => "html" }
  match "/sfu/stats/enrollments(/:term_id(.:format))" => "stats#enrollments", :defaults => { :term => nil, :format => "html" }
end
