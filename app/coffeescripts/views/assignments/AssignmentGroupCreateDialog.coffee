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
  'i18n!assignments'
  'Backbone'
  'jquery'
  'jst/assignments/AssignmentGroupCreateDialog'
  'jquery.toJSON'
  'jquery.instructure_forms'
  'jquery.disableWhileLoading'
  '../../jquery.rails_flash_notifications'
  '../../jquery/fixDialogButtons'
], (I18n, {View}, $, template) ->

  class AssignmentGroupCreateDialog extends View

    events:
      submit: 'createAssignmentGroup'
      'click .cancel-button': 'cancel'

    tagName: 'div'

    render: =>
      @$el.html template()
      @$el.dialog(
        title: I18n.t('titles.add_assignment_group', "Add Assignment Group"),
        width: 'auto',
        modal: true
      ).fixDialogButtons()
      @$el.closest('.ui-dialog').find('.ui-dialog-titlebar-close').click =>  @cancel()
      this

    createAssignmentGroup: (event) =>
      event.preventDefault()
      event.stopPropagation()
      disablingDfd = new $.Deferred()
      @$el.disableWhileLoading disablingDfd
      $.ajaxJSON "/courses/#{ENV.CONTEXT_ID}/assignment_groups",
        'POST',
        @$el.find('form').toJSON(),
        (data) =>
          disablingDfd.resolve()
          @closeDialog()
          @trigger 'assignmentGroup:created', data.assignment_group

    cancel: =>
      @trigger 'assignmentGroup:canceled'
      @closeDialog()

    closeDialog: =>
      @$el.dialog 'close'
      @trigger 'close'
