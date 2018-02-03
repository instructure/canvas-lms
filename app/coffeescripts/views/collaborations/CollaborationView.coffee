#
# Copyright (C) 2012 - present Instructure, Inc.
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
  './CollaboratorPickerView'
  'jst/collaborations/edit'
  'jst/collaborations/EditIframe',
  'jsx/external_apps/lib/iframeAllowances'
], (I18n, $, {extend}, {View}, CollaboratorPickerView, editForm, editIframe, iframeAllowances) ->

  class CollaborationView extends View
    events:
      'click .edit_collaboration_link': 'onEdit'
      'keyclick .edit_collaboration_link': 'onEdit'
      'click .delete_collaboration_link': 'onDelete'
      'keyclick .delete_collaboration_link': 'onDelete'
      'click .cancel_button': 'onCloseForm'
      'focus .before_external_content_info_alert': 'handleAlertFocus'
      'focus .after_external_content_info_alert': 'handleAlertFocus'
      'blur .before_external_content_info_alert': 'handleAlertBlur'
      'blur .after_external_content_info_alert': 'handleAlertBlur'

    initialize: ->
      super
      @id = @$el.data('id')

    handleAlertFocus: (e) ->
      $(e.target).removeClass('screenreader-only')
      @$el.find('iframe').addClass('info_alert_outline')

    handleAlertBlur: (e) =>
      $(e.target).addClass('screenreader-only')
      @$el.find('iframe').removeClass('info_alert_outline')

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
      $form.on 'keydown', (e) =>
        if e.which == 27
          e.preventDefault()
          @onCloseForm(e)

    iframeTemplate: ({url}) ->
      $iframe = $(editIframe({
        id: @id,
        url: url,
        allowances: iframeAllowances()
      }))
      $iframe.on 'keydown', (e) =>
        if e.which == 27
          e.preventDefault()
          @onCloseForm(e)

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
      $.screenReaderFlashMessage(I18n.t('Collaboration was deleted'));
      @$el.slideUp(=> @$el.remove())
      @trigger('delete', this)
      otherDeleteLinks = $('.delete_collaboration_link').toArray()
      curDeleteLink = @$el.find('.delete_collaboration_link')[0]
      newIndex = otherDeleteLinks.indexOf(curDeleteLink)
      if (newIndex > 0)
        otherDeleteLinks[newIndex - 1].focus()
      else
        $('.add_collaboration_link').focus()

    # Internal: Hide collaboration and display an edit form.
    #
    # e - Event object.
    #
    # Returns nothing.
    onEdit: (e) ->
      e.preventDefault()
      if this.$el.attr('data-update-launch-url')
        $iframe = @iframeTemplate
          url: this.$el.attr('data-update-launch-url')
        @$el.children().hide()
        @$el.append($iframe)
      else
        $form = @formTemplate
          action: $(e.currentTarget).attr('href')
          className: @$el.attr('class')
          data: @$el.getTemplateData(textValues: ['title', 'description'])
        @$el.children().hide()
        @$el.append($form)
        @addCollaboratorPicker($form)
        $form.find('[name="collaboration[title]"]').focus()

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
      @$el.find('.edit_collaboration_link').focus()

    addCollaboratorPicker: ($form) ->
      view = new CollaboratorPickerView
        edit: true
        el:   $form.find('.collaborator_list')
        id:   @id
      view.render()

