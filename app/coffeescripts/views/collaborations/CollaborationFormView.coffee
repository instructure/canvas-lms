#
# Copyright (C) 2013 Instructure, Inc.
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
#

define [
  'i18n!collaborations'
  'Backbone'
  'compiled/views/collaborations/CollaboratorPickerView'
], (I18n, {View}, CollaboratorPickerView) ->

  class CollaborationFormView extends View
    translations:
      errors:
        noName: I18n.t('errors.no_name', 'Please enter a name for this collaboration.')

    events:
      'submit': 'onSubmit'
      'click .cancel_button': 'onCancel'

    initialize: ->
      @cacheElements()
      @picker = new CollaboratorPickerView(el: @$collaborators)

    cacheElements: ->
      @$titleInput    = @$el.find('#collaboration_title')
      @$collaborators = @$el.find('.collaborator_list')

    render: (focus = true) ->
      @$el.show()
      @$el.find('h2').focus() if focus
      @picker.render() if @$collaborators.is(':empty')
      this

    onSubmit: (e) ->
      data = @$el.getFormData()
      unless data['collaboration[title]']
        e.preventDefault()
        e.stopPropagation()
        return @raiseTitleError()
      setTimeout ->
        window.location = window.location.pathname
      , 2500

    onCancel: (e) ->
      e.preventDefault()
      @$el.hide()
      @trigger('hide')

    raiseTitleError: ->
      @trigger('error', @$titleInput, @translations.errors.noName)
      false
