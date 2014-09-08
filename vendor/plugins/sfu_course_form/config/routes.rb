CanvasRails::Application.routes.draw do
  match "/sfu/course/new" => "course_form#new"
  match "/sfu/course/create" => "course_form#create"
  match "/sfu/adhoc/new" => "course_form#new_adhoc"
end
