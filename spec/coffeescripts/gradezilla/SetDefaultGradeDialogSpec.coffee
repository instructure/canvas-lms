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
  'compiled/models/Assignment'
  'compiled/gradezilla/SetDefaultGradeDialog'
  'jst/SetDefaultGradeDialog'
], ($, Assignment, SetDefaultGradeDialog) ->

  QUnit.module 'SetDefaultGradeDialog',
    setup: ->
      @assignment = new Assignment(id: 1, points_possible: 10)

    teardown: ->
      $(".ui-dialog").remove()
      $(".use-css-transitions-for-show-hide").remove()
      $('#set_default_grade_form').remove()

  test '#gradeIsExcused returns true if grade is EX', ->
    dialog = new SetDefaultGradeDialog({ @assignment })
    dialog.show()
    deepEqual dialog.gradeIsExcused('EX'), true
    deepEqual dialog.gradeIsExcused('ex'), true
    deepEqual dialog.gradeIsExcused('eX'), true
    deepEqual dialog.gradeIsExcused('Ex'), true

  test '#gradeIsExcused returns false if grade is not EX', ->
    dialog = new SetDefaultGradeDialog({ @assignment })
    dialog.show()
    deepEqual dialog.gradeIsExcused('14'), false
    deepEqual dialog.gradeIsExcused('F'), false
    #this test documents that we do not consider 'excused' to return true
    deepEqual dialog.gradeIsExcused('excused'), false
