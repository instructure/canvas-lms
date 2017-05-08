define [
  'react'
  'react-dom'
  'instructure-ui/lib/components/Spinner'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/str/splitAssetString'
  'jsx/shared/CheatDepaginator'
  "i18n!calendar.edit"
], (React, ReactDOM, {default: Spinner}, $, _, Backbone, splitAssetString, Depaginate, I18n) ->
  class CalendarEvent extends Backbone.Model

    urlRoot: '/api/v1/calendar_events/'

    dateAttributes: ['created_at', 'end_at', 'start_at', 'updated_at']

    present: ->
      result = Backbone.Model::toJSON.call(this)
      result.newRecord = !result.id
      result

