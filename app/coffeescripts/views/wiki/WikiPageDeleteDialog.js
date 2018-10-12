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
  'jquery'
  'underscore'
  'i18n!pages'
  'str/htmlEscape'
  '../DialogFormView'
], ($, _, I18n, htmlEscape, DialogFormView) ->

  dialogDefaults =
    fixDialogButtons: false
    title: I18n.t 'delete_dialog_title', 'Delete Page'
    width: 400
    height: 'auto'

  class WikiPageDeleteDialog extends DialogFormView
    setViewProperties: false
    wrapperTemplate: -> '<div class="outlet"></div>'
    template: -> I18n.t 'delete_confirmation', 'Are you sure you want to delete this page?'

    @optionProperty 'wiki_pages_path'
    @optionProperty 'focusOnCancel'
    @optionProperty 'focusOnDelete'

    initialize: (options) ->
      super _.extend {}, dialogDefaults, options

    submit: (event) ->
      event?.preventDefault()

      destroyDfd = @model.destroy(wait: true)

      dfd = $.Deferred()
      page_title = @model.get('title')
      wiki_pages_path = @wiki_pages_path

      destroyDfd.then =>
        if wiki_pages_path
          expires = new Date
          expires.setMinutes(expires.getMinutes() + 1)
          path = '/' # should be wiki_pages_path, but IE will only allow *sub*directries to read the cookie, not the directory itself...
          $.cookie 'deleted_page_title', page_title, expires: expires, path: path
          window.location.href = wiki_pages_path
        else
          $.flashMessage I18n.t 'notices.page_deleted', 'The page "%{title}" has been deleted.', title: page_title
          dfd.resolve()
          @close()

      destroyDfd.fail =>
        $.flashError I18n.t('notices.delete_failed', 'The page "%{title}" could not be deleted.', title: page_title)
        dfd.reject()

      @$el.disableWhileLoading dfd

    close: ->
      if @dialog?.isOpen()
        @dialog.close()
      if @buttonClicked == 'delete'
        @focusOnDelete?.focus()
      else
        @focusOnCancel?.focus()

    setupDialog: ->
      super

      form = @

      buttons = [
        class: 'btn'
        text: I18n.t 'cancel_button', 'Cancel'
        click: =>
          @buttonClicked = 'cancel'
          form.$el.dialog 'close'
      ,
        class: 'btn btn-danger'
        text: I18n.t 'delete_button', 'Delete'
        'data-text-while-loading': I18n.t 'deleting_button', 'Deleting...'
        click: =>
          @buttonClicked = 'delete'
          form.submit()
      ]
      @$el.dialog 'option', 'buttons', buttons
