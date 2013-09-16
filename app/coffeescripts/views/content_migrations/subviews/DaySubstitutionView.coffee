define [
  'underscore'
  'jquery'
  'Backbone'
  'i18nObj'
  'jst/content_migrations/subviews/DaySubstitution'
], (_, $, Backbone, I18n, template) -> 
  class DaySubstitutionView extends Backbone.View
    template: template

    els: 
      ".currentDay" : "$currentDay"
      ".subDay"     : "$subDay"

    events: 
      'click a'             : 'removeView'
      'change .currentDay'  : 'changeCurrentDay'
      'change .subDay'      : 'updateModelData'

    # When a new view is created, make sure the model is updated
    # with it's initial attributes/values

    afterRender: -> @updateModelData()

    # Ensure that after you update the current day you change focus
    # to the next select box. In this case the next select box is
    # @$subDay

    changeCurrentDay: -> 
      @updateModelData()
      #@$subDay.focus()

    # Clear the model and add new value and key
    # for the day representation.
    #
    # @api private

    updateModelData: -> 
      sub_data = {}
      sub_data[@$currentDay.val()] = @$subDay.val()
      @updateName()

      @model.clear()
      @model.set sub_data

    updateName: ->
      @$subDay.attr 'name', "date_shift_options[day_substitutions][#{@$currentDay.val()}]"
      
    # Remove the model from both the view and 
    # the collection it belongs to.
    #
    # @api private

    removeView: (event) -> 
      event.preventDefault()
      @model.collection.remove @model

    # Add weekdays to the handlebars template
    # 
    # @api backbone override

    toJSON: -> 
      json = super
      json.weekdays = @weekdays()
      json

    # Return an array of objects with weekdays
    # ie: 
    #   [{index: 0, name: 'Sunday'}, {index: 1, name: 'Monday'}]
    # @api private

    weekdays: -> 
      dayArray = I18n.lookup('date.day_names')
      _.map dayArray, (day) => {index: _.indexOf(dayArray, day), name: day}
