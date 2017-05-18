#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'compiled/widget/assignmentRubricDialog'
], ($, assignmentRubricDialog)->

  QUnit.module 'assignmentRubricDialog'

  test 'make sure it picks up the right data attrs', ->
    $trigger = $('<div />').addClass('rubric_dialog_trigger')
    $trigger.data('noRubricExists', false)
    $trigger.data('url', '/example')
    $trigger.data('focusReturnsTo', '.announcement_cog')
    $('#fixtures').append($trigger)
    
    assignmentRubricDialog.initTriggers()

    equal assignmentRubricDialog.noRubricExists, false
    equal assignmentRubricDialog.url, '/example'
    ok assignmentRubricDialog.$focusReturnsTo

    $('#fixtures').empty()
