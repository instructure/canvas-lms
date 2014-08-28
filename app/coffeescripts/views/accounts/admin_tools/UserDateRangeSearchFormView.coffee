define [
  'Backbone'
  'jquery'
  'i18n!user_date_range_search'
  'jst/accounts/admin_tools/userDateRangeSearchForm'
  'compiled/views/ValidatedMixin'
  'jquery.ajaxJSON'
  'jquery.instructure_date_and_time'
  'compiled/jquery.rails_flash_notifications'
], (Backbone,$, I18n, template, ValidatedMixin) ->
  class UserDateRangeSearchFormView extends Backbone.View
    @mixin ValidatedMixin

    @child 'inputFilterView', '[data-view=inputFilter]'
    @child 'usersView', '[data-view=users]'

    tagName: 'form'

    template: template

    events:
      'submit': 'submit'

    els:
      '.userIdField':          '$userIdField'
      '.dateStartSearchField': '$dateStartSearchField'
      '.dateEndSearchField':   '$dateEndSearchField'
      '.search-controls':      '$searchControls'
      '.search-people-status': '$searchPeopleStatus'

    @optionProperty 'formName'

    toJSON: -> @options

    initialize: (options) ->
      @model = new Backbone.Model
      super(options)

    # Setup the date inputs for javascript use.
    afterRender: ->
      @$dateStartSearchField.datetime_field()
      @$dateEndSearchField.datetime_field()
      @$searchControls.hide()

    attach: ->
      @inputFilterView.collection.on 'setParam deleteParam', @fetchUsers
      @usersView.collection.on 'selectedModelChange', @selectUser
      @usersView.collection.on 'sync', @resultsFound

    resultsFound: =>
      $.screenReaderFlashMessage(I18n.t('results_found', "%{length} results found", { length: @usersView.collection.length }))

    fetchUsers: =>
      @selectUser null
      @lastRequest?.abort()
      @lastRequest = @inputFilterView.collection.fetch()

    selectUser: (e) =>
      @usersView.$el.find('tr').each () -> $(this).removeClass('selected')
      if e
        @model.set e.attributes
        @$userIdField.val(e.get 'id')
        @$searchControls.show()
      else
        @$userIdField.val('')
        @$searchControls.hide()

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
      # If have both start and end, check for values to make sense together.
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
      delete json['search_term']
      json.start_time = '' unless json.start_time
      json.end_time = '' unless json.end_time
      @collection.setParams json
