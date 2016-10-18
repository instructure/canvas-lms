define ['node_modules-version-of-backbone', 'underscore'], (Backbone, _) ->

  _parse = Backbone.Model::parse

  Backbone.Model::parse = ->
    res = _parse.apply(this, arguments)

    _.each @dateAttributes, (attr) ->
      if res[attr]
        res[attr] = Date.parse(res[attr])
    res

  Backbone.Model
