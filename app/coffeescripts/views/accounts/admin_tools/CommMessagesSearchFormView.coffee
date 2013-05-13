define [
  'Backbone'
  'jquery'
  'i18n!notifications_search'
  'jst/accounts/admin_tools/commMessagesSearchForm'
  'compiled/collections/CommMessageCollection'
  'compiled/views/ValidatedMixin'
  'jquery.ajaxJSON'
], (Backbone,$, I18n, template, CommMessageCollection, ValidatedMixin) ->
  class CommMessagesSearchFormView extends Backbone.View
    @mixin ValidatedMixin

    tagName: 'form'

    template: template

    events:
      'submit': 'submit'

    els:
      '#userIdSearchField':   '$userIdSearchField'
      '#dateStartSearchField': '$dateStartSearchField'
      '#dateEndSearchField':   '$dateEndSearchField'

    # Setup the date inputs for javascript use.
    afterRender: ->
      @$dateStartSearchField.datetime_field()
      @$dateEndSearchField.datetime_field()

    validityCheck: ->
      json = @$el.toJSON()

      valid = true
      errors = {}
      if !json.user_id
        valid = false
        errors['user_id'] =
          [
            {
            type: 'required'
            message: I18n.t('cant_be_blank', "Canvas User ID can't be blank")
            }
          ]
      # If have both start and end, check for va lues to make sense together.
      if json.start_time && json.end_time && (json.start_time > json.end_time)
        valid = false
        errors['end_time'] =
          [
            {
            type: 'invalid'
            message: I18n.t('cant_come_before_from', "'To Date' can't come before 'From Date'")
            }
          ]
      # Show any errors
      @showErrors errors
      # Return false if there are any errors
      valid

    submit: (event) ->
      event.preventDefault()
      if @validityCheck()
        @updateCollection()

    updateCollection: ->
      # Update the params (which fetches the collection)
      json = @$el.toJSON()
      json.start_time = '' unless json.start_time
      json.end_time = '' unless json.end_time
      @collection.setParams json
