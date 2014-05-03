define [
  'ember-data'
  '../shared/environment'
], (DS, env) ->

  DS.ActiveModelAdapter.extend
    headers:
      'Accept': 'application/vnd.api+json'
    namespace: "api/v1/courses/#{env.get('courseId')}"
    ajaxOptions: (url, type, hash)->
      hash = this._super.apply(this, arguments)
      hash.converters =
        "text json": (string) ->
          string = string.replace /^while\(1\);/, ''
          payload = Ember.$.parseJSON string
          payload
      hash
