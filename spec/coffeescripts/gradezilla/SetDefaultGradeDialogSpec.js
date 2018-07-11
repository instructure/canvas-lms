/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import Assignment from 'compiled/models/Assignment'
import SetDefaultGradeDialog from 'compiled/gradezilla/SetDefaultGradeDialog'
import 'jst/SetDefaultGradeDialog'

QUnit.module('SetDefaultGradeDialog', {
  setup() {
    this.assignment = new Assignment({
      id: 1,
      points_possible: 10
    })
  },
  teardown() {
    $('.ui-dialog').remove()
    $('.use-css-transitions-for-show-hide').remove()
    $('#set_default_grade_form').remove()
  }
})

test('#gradeIsExcused returns true if grade is EX', function() {
  const dialog = new SetDefaultGradeDialog({assignment: this.assignment})
  dialog.show()
  deepEqual(dialog.gradeIsExcused('EX'), true)
  deepEqual(dialog.gradeIsExcused('ex'), true)
  deepEqual(dialog.gradeIsExcused('eX'), true)
  deepEqual(dialog.gradeIsExcused('Ex'), true)
})

test('#gradeIsExcused returns false if grade is not EX', function() {
  const dialog = new SetDefaultGradeDialog({assignment: this.assignment})
  dialog.show()
  deepEqual(dialog.gradeIsExcused('14'), false)
  deepEqual(dialog.gradeIsExcused('F'), false)
  // this test documents that we do not consider 'excused' to return true
  deepEqual(dialog.gradeIsExcused('excused'), false)
})

test('when given callback for #show, invokes callback upon dialog close', function() {
  const callback = sinon.stub()
  const dialog = new SetDefaultGradeDialog({assignment: this.assignment})
  dialog.show(callback)
  $('button.ui-dialog-titlebar-close').click()
  equal(callback.callCount, 1)
})

test('#show text', function() {
  const dialog = new SetDefaultGradeDialog({assignment: this.assignment})
  dialog.show()
  ok(document.getElementById('default_grade_description').innerText.includes('same grade'))
})

test('#show changes text for grading percent', function() {
  this.assignment.grading_type = 'percent'
  const dialog = new SetDefaultGradeDialog({assignment: this.assignment})
  dialog.show()
  ok(document.getElementById('default_grade_description').innerText.includes('same percent grade'))
})
