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
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/collaborations/CollaboratorPickerView'
  'jst/collaborations/edit'
], (I18n, $, {extend}, {View}, CollaboratorPickerView, editForm) ->

  class CollaborationView extends View
    events:
      'click .edit_collaboration_link': 'onEdit'
      'click .delete_collaboration_link': 'onDelete'
      'click .cancel_button': 'onCloseForm'

    initialize: ->
      super
      @id = @$el.data('id')

    # Internal: Create collaboration edit form HTML.
    #
    # options - A hash of options used to configure the template:
    #           :action    - The URL to post the form to.
    #           :className - A string of CSS classes to add to the form.
    #           :data      - A hash of TemplateData to apply to the form fields.
    #
    # Returns a jQuery object form.
    formTemplate: ({action, className, data}) ->
      $form = $(editForm(extend(data, action: action, id: @id)))
      #$form.attr('class', className)

    # Internal: Confirm deleting of a Google Docs collaboration.
    #
    # Returns nothing.
    confirmGoogleDocsDelete: ->
      # TODO: pull this dialog into handlebars.
      $dialog = $('#delete_collaboration_dialog').data('collaboration', @$el)
      $dialog.dialog
        title: I18n.t('titles.delete', 'Delete collaboration?')
        width: 350

    # Internal: Confirm deleting a non-Google Docs collaboration.
    #
    # url - The URL to post the delete request to.
    #
    # Returns nothing.
    confirmDelete: (url) ->
      @$el.confirmDelete
        message: I18n.t('collaboration.delete', 'Are you sure you want to delete this collaboration?')
        success: @delete
        url: url

    delete: =>
      @$el.slideUp(=> @$el.remove())
      @trigger('delete', this)

    # Internal: Hide collaboration and display an edit form.
    #
    # e - Event object.
    #
    # Returns nothing.
    onEdit: (e) ->
      e.preventDefault()
      $form = @formTemplate
        action: $(e.currentTarget).attr('href')
        className: @$el.attr('class')
        data: @$el.getTemplateData(textValues: ['title', 'description'])
      @$el.children().hide()
      @$el.append($form)
      @addCollaboratorPicker($form)

    # Internal: Delete the collaboration.
    #
    # e - Event object.
    #
    # Returns nothing.
    onDelete: (e) ->
      e.preventDefault()
      href = $(e.currentTarget).attr('href')
      if @$el.hasClass('google_docs')
        @confirmGoogleDocsDelete()
      else
        @confirmDelete(href)

    # Internal: Hide the edit form and display the show content.
    #
    # e - Event object.
    #
    # Returns nothing.
    onCloseForm: (e) ->
      @$el.find('form').remove()
      @$el.children().show()

    addCollaboratorPicker: ($form) ->
      view = new CollaboratorPickerView
        edit: true
        el:   $form.find('.collaborator_list')
        id:   @id
      view.render()

