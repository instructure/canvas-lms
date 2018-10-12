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
  'i18n!groups'
  '../../DialogFormView'
  'jst/groups/manage/groupEdit'
  'jst/EmptyDialogFormWrapper'
], (I18n, DialogFormView, template, wrapper) ->

  class GroupEditView extends DialogFormView

    @optionProperty 'groupCategory'
    @optionProperty 'student'

    defaults:
      width: 550
      title: I18n.t "edit_group", "Edit Group"

    els:
      '[name=max_membership]': '$maxMembership'

    template: template

    wrapperTemplate: wrapper

    className: 'dialogFormView group-edit-dialog form-horizontal form-dialog'

    attach: ->
      if @model
        @model.on('change', @refreshIfNameOnlyMode, this)

    refreshIfNameOnlyMode: ->
      if @options.nameOnly
        window.location.reload()


    events: Object.assign {},
      DialogFormView::events
      'click .dialog_closer': 'close'

    translations:
      too_long: I18n.t "name_too_long", "Name is too long"

    validateFormData: (data, errors) ->
      if @$maxMembership.length > 0 and !@$maxMembership[0].validity.valid
        {"max_membership": [{message: I18n.t('max_membership_number', 'Max membership must be a number') }]}

    openAgain: ->
      super
      # reset the form contents
      @render()

    toJSON: ->
      json = Object.assign {}, super,
        role: @groupCategory.get('role')
        nameOnly: @options.nameOnly
      json
