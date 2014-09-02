define ['ember'], (Ember) ->

  # {path: '/1/moderate, title: 'Expected Title'}
  (options) ->
    test "updates document.title for #{options.path} correctly", ->
      visit(options.path)
      andThen ->
        equal document.title, options.title
