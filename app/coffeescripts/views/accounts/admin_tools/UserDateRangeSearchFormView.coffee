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
              click: ->
                self.$hiddenDateStart.val(if self.$dateStartSearchField.attr('aria-invalid') == 'true' then '' else self.$dateStartSearchField.val())
                self.$hiddenDateEnd.val(if self.$dateEndSearchField.attr('aria-invalid') == 'true' then '' else self.$dateEndSearchField.val())
                self.$el.submit()
                $(this).dialog('close')
            }
          ]
      else
        @$userIdField.val('')

    validityCheck: ->
      json = @$el.toJSON()

      valid = true
      errors = {}
      # If have both start and end, check for values to make sense together.
      if json.start_time && json.end_time && (json.start_time > json.end_time)
        valid = false
        errors['end_time'] =
          [
            {
            type: 'invalid'
            message: I18n.t('"To Date" can\'t come before "From Date"')
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
