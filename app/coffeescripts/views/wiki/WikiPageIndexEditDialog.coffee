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
  'jst/wiki/WikiPageIndexEditDialog'
], ($, _, I18n, htmlEscape, DialogFormView, wrapperTemplate) ->

  dialogDefaults =
    fixDialogButtons: false
    title: I18n.t 'edit_dialog_title', 'Edit Wiki Page'
    width: 450
    height: 230
    minWidth: 450
    minHeight: 230


  class WikiPageIndexEditDialog extends DialogFormView
    setViewProperties: false
    className: 'page-edit-dialog'

    returnFocusTo: null

    wrapperTemplate: wrapperTemplate
    template: -> ''

    initialize: (options = {}) ->
      @returnFocusTo = options.returnFocusTo
      super _.extend {}, dialogDefaults, options

    setupDialog: ->
      super

      form = @

      # Add a close event for focus handling
      form.$el.on('dialogclose', (event, ui) =>
        @returnFocusTo?.focus()
      )

      buttons = [
        class: 'btn'
        text: I18n.t 'cancel_button', 'Cancel'
        click: =>
          form.$el.dialog 'close'
          @returnFocusTo?.focus()
      ,
        class: 'btn btn-primary'
        text: I18n.t 'save_button', 'Save'
        'data-text-while-loading': I18n.t 'saving_button', 'Saving...'
        click: =>
          form.submit()
          @returnFocusTo?.focus()
      ]
      @$el.dialog 'option', 'buttons', buttons

    openAgain: ->
      super
      @.$('[name="title"]').focus()
