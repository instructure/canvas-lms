#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'i18n!feature_flags'
  '../DialogBaseView'
  'jst/feature_flags/featureFlagDialog'
], (I18n, DialogBaseView, template) ->

  class FeatureFlagDialog extends DialogBaseView

    @optionProperty 'deferred'

    @optionProperty 'message'

    @optionProperty 'title'

    @optionProperty 'hasCancelButton'

    template: template

    labels:
      okay   : I18n.t('#buttons.okay', 'Okay')
      cancel : I18n.t('#buttons.cancel', 'Cancel')

    dialogOptions: ->
      options =
        title   : @title
        height  : 300
        width   : 500
        buttons : [text: @labels.okay, click: @onConfirm, class: 'btn-primary']
        open    : @onOpen
        close   : @onClose
      if @hasCancelButton
        options.buttons.unshift(text: @labels.cancel, click: @onCancel)
      options

    onOpen: (e) =>
      @okay = false

    onClose: (e) =>
      if @okay then @deferred.resolve() else @deferred.reject()

    onCancel: (e) =>
      @close()

    onConfirm: (e) =>
      @okay = @hasCancelButton
      @close()

    toJSON: ->
      message: @message
