require [
  'ENV'
  'compiled/gradebook2/Gradebook'
], (ENV, Gradebook) ->
  new Gradebook(ENV.GRADEBOOK_OPTIONS)

