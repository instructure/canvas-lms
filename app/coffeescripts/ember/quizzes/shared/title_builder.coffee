define [
  'ember'
], (Ember) ->

  updateTitle = (title) ->
    Ember.$(document).attr('title', title)

  (tokens, separator = ': ') ->
    if tokens instanceof Array
      tokens = tokens || []
      title = tokens.join(separator)
    else
      title = tokens || ''
    updateTitle(title)
    title
