/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

define([
  'compiled/AssignmentDetailsDialog',
  'jsx/gradezilla/shared/AssignmentDetailsDialogManager',
], (AssignmentDetailsDialog, AssignmentDetailsDialogManager) => {
  function createAssignmentProp () {
    return {
      id: '1',
      html_url: 'http://assignment_htmlUrl',
      invalid: false,
      muted: false,
      name: 'Assignment #1',
      omit_from_final_grade: false,
      points_possible: 13,
      submission_types: ['online_text_entry'],
      course_id: '42'
    }
  }

  function createStudentsProp () {
    return [
      {
        id: '11',
        name: 'Clark Kent',
        is_inactive: false,
        submission: {
          score: 7,
          submitted_at: null
        }
      },
      {
        id: '13',
        name: 'Barry Allen',
        is_inactive: false,
        submission: {
          score: 8,
          submitted_at: new Date('Thu Feb 02 2017 16:33:19 GMT-0500 (EST)')
        }
      },
      {
        id: '15',
        name: 'Bruce Wayne',
        is_inactive: false,
        submission: {
          score: undefined,
          submitted_at: undefined
        }
      }
    ];
  }

  QUnit.module('AssignmentDetailsDialogManager#isDialogEnabled');

  test('returns true when submissions are loaded', function () {
    const manager = new AssignmentDetailsDialogManager(createAssignmentProp(), createStudentsProp(), true);

    ok(manager.isDialogEnabled());
  });

  test('returns false when submissions are not loaded', function () {
    const manager = new AssignmentDetailsDialogManager(createAssignmentProp(), createStudentsProp(), false);

    notOk(manager.isDialogEnabled());
  });

  QUnit.module('AssignmentDetailsDialogManager#showDialog', {
    setup () {
      this.manager = new AssignmentDetailsDialogManager(createAssignmentProp(), createStudentsProp(), true);
    }
  });

  test('calls show() on the AssignmentDetailsDialog', function () {
    const stubbedShow = this.stub(AssignmentDetailsDialog.prototype, 'show');
    this.manager.showDialog();

    equal(stubbedShow.callCount, 1);
  });

  test('calls AssignmentDetailsDialog.show with the correct arguments', function () {
    const stubbedShow = this.stub(AssignmentDetailsDialog, 'show');
    const expectedArgs = {
      assignment: createAssignmentProp(),
      students: [
        { assignment_1: { score: 7 } },
        { assignment_1: { score: 8 } },
        { assignment_1: { score: undefined } }
      ]
    };
    this.manager.showDialog();

    equal(stubbedShow.callCount, 1);
    deepEqual(stubbedShow.getCall(0).args[0], expectedArgs);
  });
});
