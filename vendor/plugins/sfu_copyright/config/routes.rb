(CANVAS_RAILS2 ? FakeRails3Routes : CanvasRails::Application.routes).draw do
  match "/sfu/copyright/disclaimer" => "copyright#disclaimer"
end
