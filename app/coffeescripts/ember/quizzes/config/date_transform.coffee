define [
  'ember'
  'ember-data'
  'jquery'
  'jquery.instructure_date_and_time'
], (Em, DS, $) ->

  ISODateTransform = DS.DateTransform.extend
    # TODO: May not be needed once timezunami hits master
    serialize: (date) ->
      if date instanceof Date
        date.toISOString()
      else
        null
  
  Em.onLoad 'Ember.Application', (Application) ->
    Application.initializer
      after: 'transforms'
      name: 'INSTRUCTURE dateTransform'
      initialize: (container, application) ->
        container.register 'transform:date', ISODateTransform
