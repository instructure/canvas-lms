#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'Backbone'
  'jquery'
  'i18n!user_date_range_search'
  'jst/accounts/admin_tools/userDateRangeSearchForm'
  '../../ValidatedMixin'
  'jquery.ajaxJSON'
  'jquery.instructure_date_and_time'
  'jqueryui/dialog'
  '../../../jquery.rails_flash_notifications'
], (Backbone, $, I18n, template, ValidatedMixin) ->
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
      '.hiddenDateStart':      '$hiddenDateStart'
      '.hiddenDateEnd':        '$hiddenDateEnd'
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
      @collection.on 'sync', @notificationsFound

    resultsFound: =>
      setTimeout(() =>
        $.screenReaderFlashMessageExclusive(I18n.t('%{length} results found', { length: @usersView.collection.length }))
      , 500)

    notificationsFound: =>
      $.screenReaderFlashMessage(I18n.t('%{length} notifications found', { length: @collection.length }))

    fetchUsers: =>
      @selectUser null
      @lastRequest?.abort()
      @lastRequest = @inputFilterView.collection.fetch()

    selectUser: (e) =>
      @usersView.$el.find('tr').each () -> $(this).removeClass('selected')
      if e
        @model.set e.attributes
        id = e.get 'id'
        @$userIdField.val(id)
        self = this
        @$searchControls.show().dialog
          title:  I18n.t('Generate Activity for %{user}', user: e.get 'name')
          resizable: false
          height: 'auto'
          width: 400
          modal: true
          dialogClass: 'userDateRangeSearchModal'
          close: ->
            self.$el.find('.roster_user_name[data-user-id=' +id + ']').focus()
          buttons: [
            {
              text: I18n.t('Cancel')
              click: ->
                $(this).dialog('close')
            }
            {
              text: I18n.t('Find')
              'class': 'btn btn-primary userDateRangeSearchBtn'
              'id': "#{self.formName}-find-button"
              click: ->
                errors = self.datesValidation()
                if Object.keys(errors).length != 0
                  self.showErrors(errors, true)
                  return

                self.$hiddenDateStart.val(self.$dateStartSearchField.val())
                self.$hiddenDateEnd.val(self.$dateEndSearchField.val())
                self.$el.submit()
                $(this).dialog('close')
            }
          ]
      else
        @$userIdField.val('')

    dateIsValid: (dateField) ->
      if dateField.val() == ''
        return true
      date = dateField.data('unfudged-date')
      return (date instanceof Date && !isNaN(date.valueOf()))

    datesValidation: ->
      errors = {}
      startDateField = @$dateStartSearchField
      endDateField = @$dateEndSearchField
      startDate = startDateField.data('unfudged-date')
      endDate = endDateField.data('unfudged-date')

      if startDate && endDate && (startDate > endDate)
        errors["#{@formName}_end_time"] = [{
          message: I18n.t('To Date cannot come before From Date')
        }]
      else
        if !@dateIsValid(startDateField)
          errors["#{@formName}_start_time"] = [{
            message: I18n.t('Not a valid date')
          }]
        if !@dateIsValid(endDateField)
          errors["#{@formName}_end_time"] = [{
            message: I18n.t('Not a valid date')
          }]
      return errors

    submit: (event) ->
      event.preventDefault()
      @updateCollection()

    updateCollection: ->
      # Update the params (which fetches the collection)
      json = @$el.toJSON()
      delete json['search_term']
      json.start_time = '' unless json.start_time
      json.end_time = '' unless json.end_time
      @collection.setParams json
