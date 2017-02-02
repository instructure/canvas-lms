/*
 * Copyright (C) 2017 Instructure, Inc.
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
  'jquery',
  'compiled/gradezilla/SetDefaultGradeDialog',
  'jsx/gradezilla/shared/SetDefaultGradeDialogManager',
], ($, SetDefaultGradeDialog, SetDefaultGradeDialogManager) => {
  function createAssignmentProp () {
    return {
      id: '1',
      htmlUrl: 'http://assignment_htmlUrl',
      invalid: false,
      muted: false,
      name: 'Assignment #1',
      omitFromFinalGrade: false,
      pointsPossible: 13,
      submissionTypes: ['online_text_entry'],
      courseId: '42'
    }
  }

  function createStudentsProp () {
    return [
      {
        id: '11',
        name: 'Clark Kent',
        isInactive: false,
        submission: {
          score: 7,
          submittedAt: null
        }
      },
      {
        id: '13',
        name: 'Barry Allen',
        isInactive: false,
        submission: {
          score: 8,
          submittedAt: new Date('Thu Feb 02 2017 16:33:19 GMT-0500 (EST)')
        }
      },
      {
        id: '15',
        name: 'Bruce Wayne',
        isInactive: false,
        submission: {
          score: undefined,
          submittedAt: undefined
        }
      }
    ];
  }

  QUnit.module('SetDefaultGradeDialogManager#isDialogEnabled');

  test('returns true when submissions are loaded', function () {
    const manager = new SetDefaultGradeDialogManager(
      createAssignmentProp(), createStudentsProp(), 'contextId', 'selectedSection', false, true
    );

    ok(manager.isDialogEnabled());
  });

  test('returns false when submissions are not loaded', function () {
    const manager = new SetDefaultGradeDialogManager(
      createAssignmentProp(), createStudentsProp(), 'contextId', 'selectedSection', false, false
    );

    notOk(manager.isDialogEnabled());
  });

  QUnit.module('SetDefaultGradeDialogManager#showDialog', {
    setupDialogManager (opts) {
      const assignment = {
        ...createAssignmentProp(),
        inClosedGradingPeriod: opts.inClosedGradingPeriod
      };

      return new SetDefaultGradeDialogManager(
        assignment, createStudentsProp(), 'contextId', 'selectedSection', opts.isAdmin, true
      );
    },

    setup () {
      this.flashErrorStub = this.stub($, 'flashError');
      this.showDialogStub = this.stub(SetDefaultGradeDialog.prototype, 'show');
    }
  });

  test('shows the SetDefaultGradeDialog when assignment is not in a closed grading period', function () {
    const manager = this.setupDialogManager({ inClosedGradingPeriod: false, isAdmin: false });
    manager.showDialog();

    equal(this.showDialogStub.callCount, 1);
  });

  test('does not show an error when assignment is not in a closed grading period', function () {
    const manager = this.setupDialogManager({ inClosedGradingPeriod: false, isAdmin: false });
    manager.showDialog();

    equal(this.flashErrorStub.callCount, 0);
  });

  test('shows the SetDefaultGradeDialog when assignment is in a closed grading period but isAdmin is true', function () {
    const manager = this.setupDialogManager({ inClosedGradingPeriod: true, isAdmin: true });
    manager.showDialog();

    equal(this.showDialogStub.callCount, 1);
  });

  test('does not show an error when assignment is in a closed grading period but isAdmin is true', function () {
    const manager = this.setupDialogManager({ inClosedGradingPeriod: true, isAdmin: true });
    manager.showDialog();

    equal(this.flashErrorStub.callCount, 0);
  });

  test('shows an error message when assignment is in a closed grading period and isAdmin is false', function () {
    const manager = this.setupDialogManager({ inClosedGradingPeriod: true, isAdmin: false });
    manager.showDialog();

    equal(this.flashErrorStub.callCount, 1);
  });

  test('does not show the SetDefaultGradeDialog when assignment is in a closed grading period and isAdmin is false', function () {
    const manager = this.setupDialogManager({ inClosedGradingPeriod: true, isAdmin: false });
    manager.showDialog();

    equal(this.showDialogStub.callCount, 0);
  });
});

