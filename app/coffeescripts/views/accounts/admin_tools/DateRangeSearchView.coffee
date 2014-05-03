define [
  'Backbone'
  'jquery'
  'i18n!user_date_range_search'
  'jst/accounts/admin_tools/dateRangeSearch'
  'jquery.instructure_date_and_time'
], (Backbone, $, I18n, template) ->
  class DateRangeSearchView extends Backbone.View
    template: template

    els:
      '.dateSearchField': '$dateSearchFields'

    toJSON: ->
      name: @options.name

    constructor: (@options) ->
      super

    afterRender: ->
      @$dateSearchFields.datetime_field()

    validate: (json) ->
      json ||= @$el.toJSON()
      errors = {}
      if json.start_time && json.end_time && (json.start_time > json.end_time)
        errors['end_time'] = [{
          type: 'invalid'
          message: I18n.t('cant_come_before_from', "'To Date' can't come before 'From Date'")
        }]
      errors