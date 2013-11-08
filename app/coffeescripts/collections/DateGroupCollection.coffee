define [
  'Backbone'
  'underscore'
  'jquery'
  'compiled/models/DateGroup'
], (Backbone, _, $, DateGroup) ->

  class DateGroupCollection extends Backbone.Collection

    model: DateGroup
