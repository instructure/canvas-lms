define ['ember'], (Ember) ->
  Ember.Handlebars.helper 'forcePrecision', (float) ->
    (float || 0).toFixed(2)