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
  'i18n!dialog'
  'jquery'
  'underscore'
  'Backbone'
  'jqueryui/dialog'
], (I18n, $, _, Backbone) ->

  ##
  # A Backbone View to extend for creating a jQuery dialog.
  #
  # Define options for the dialog as an object using the dialogOptions key,
  # those options will be merged with the defaultOptions object.
  # Begin with id and title options.
  class DialogBaseView extends Backbone.View

    initialize: ->
      super
      @initDialog()
      @setElement @dialog

    defaultOptions: ->
      # id:
      # title:
      autoOpen: false
      width: 420
      resizable: false
      buttons: []
      destroy: false

    initDialog: () ->
      opts = _.extend {}, @defaultOptions(),
        buttons: [
          text: I18n.t '#buttons.cancel', 'Cancel'
          'class' : 'cancel_button'
          click: @cancel
        ,
          text: I18n.t '#buttons.update', 'Update'
          'class' : 'btn-primary'
          click: @update
        ],
        _.result(this, 'dialogOptions')
      @dialog = $("<div id=\"#{ opts.id }\"></div>").appendTo('body').dialog opts
      @dialog.parent().attr('id', opts.containerId) if opts.containerId
      $('.ui-resizable-handle').attr('aria-hidden', true)

      @dialog

    ##
    # Sample
    #
    # render: ->
    #   @$el.html someTemplate()
    #   this

    show: ->
      @dialog.dialog('open')

    close: ->
      if (@options.destroy)
        @dialog.dialog('destroy')
      else
        @dialog.dialog('close')

    update: (e) ->
      throw 'Not yet implemented'

    cancel: (e) =>
      e.preventDefault()
      @close()
