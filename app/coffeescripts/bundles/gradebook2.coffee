require [
  'compiled/gradebook2/Gradebook'
], (Gradebook) ->
  new Gradebook(ENV.GRADEBOOK_OPTIONS)

