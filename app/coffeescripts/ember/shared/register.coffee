define ['ember'], (Ember) ->

  # Registers objects on the application container, like components. This
  # prevents us from having to add App.WhateverThing to every app, and instead
  # just require the shared object into your app without any extra fuss.

  register = (type, name, obj) ->
    Ember.Application.initializer
      name: name
      initialize: (container) ->
        container.register "#{type}:#{name}", obj
    obj

