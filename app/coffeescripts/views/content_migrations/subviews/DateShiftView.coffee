define [
  'jquery'
  'Backbone'
  'compiled/views/content_migrations/subviews/DaySubstitutionView'
  'compiled/models/DaySubstitution'
  'jst/content_migrations/subviews/DateShift'
], ($, Backbone, DaySubView, DaySubModel, template) -> 
  class DateShiftView extends Backbone.View
    template: template

    @child 'daySubstitution', '#daySubstitution'
    @optionProperty 'oldStartDate'
    @optionProperty 'oldEndDate'

    els: 
      ".dateShiftContent"  : "$dateShiftContent"
      "#oldStartDate"      : "$oldStartDate"
      "#oldEndDate"        : "$oldEndDate"
      "#newStartDate"      : "$newStartDate"
      "#newEndDate"        : "$newEndDate"
      "#daySubstitution"   : "$daySubstitution"

    events: 
      'click #dateShiftCheckbox' : 'toggleContent'
      'click #addDaySubstitution' : 'createDaySubView'

    # Update the model every time values in the calendar fields change. 
    # Depends on the models 'setDateShiftOptions' which will update 
    # and next the date shift options correctly. Also initializes
    # datetime_fields.
    # 
    # @api custom backbone override

    afterRender: ->
      @$el.find('input[type=text]').datetime_field()

      # Set date attributes on model when they change.
      @$oldStartDate.on 'change', (event) => @model.setDateShiftOptions property: 'old_start_date', value: event.target.value
      @$oldEndDate.on 'change', (event) => @model.setDateShiftOptions property:'old_end_date', value: event.target.value
      @$newStartDate.on 'change', (event) => @model.setDateShiftOptions property: 'new_start_date', value: event.target.value
      @$newEndDate.on 'change', (event) => @model.setDateShiftOptions property: 'new_end_date', value: event.target.value

      @$newStartDate.val(@oldStartDate).trigger('change') if @oldStartDate
      @$newEndDate.val(@oldEndDate).trigger('change') if @oldEndDate

      @collection.on 'remove', => @$el.find('#addDaySubstitution').focus()

    # Toggle content. Show's content when checked 
    # and hides content when unchecked. Sets date_shift_options
    # flag to true or false because you need to indicate if we 
    # care about date shift options
    # 
    # @expects jQuery event
    # @returns void
    # @api private

    toggleContent: (event) => 
      dateShift = $(event.target).is(':checked')
      @model.setDateShiftOptions property: 'shift_dates', value: dateShift
      @model.daySubCollection = if dateShift then @collection else null
      @$dateShiftContent.toggle()

    # Display's a new DaySubstitutionView by adding it to the collection. 
    # @api private

    createDaySubView: (event) => 
      event.preventDefault()
      @collection.add new DaySubModel

      # Focus on the last date substitution added
      $lastDaySubView = @collection.last()?.view.$el
      $lastDaySubView.find('select').first().focus()


    updateNewDates: (course) =>
      @$oldStartDate.val(course.start_at).trigger('change')
      @$oldEndDate.val(course.end_at).trigger('change')
