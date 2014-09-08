CanvasRails::Application.routes.draw do
  match "/sfu/copyright/disclaimer" => "copyright#disclaimer"
  match "/sfu/api/v1/copyright/random/:term" => "copyright_api#random_course_files", :defaults => { :format => "json" }
end
