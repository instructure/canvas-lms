/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import Gradebook from 'compiled/gradebook/Gradebook';
import _ from 'underscore';
import fakeENV from 'helpers/fakeENV';
import UserSettings from 'compiled/userSettings';
import $ from 'jquery';

function createGradebook (opts = {}) {
  return new Gradebook({ settings: {}, sections: {}, ...opts });
}

QUnit.module('addRow', {
  setup () {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: { context_id: 1 },
    });
  },
  teardown: () => fakeENV.teardown(),
});

test("doesn't add filtered out users", () => {
  const gb = {
    sections_enabled: true,
    sections: {1: {name: 'Section 1'}, 2: {name: 'Section 2'}},
    options: {},
    rows: [],
    sectionToShow: '2', // this is the filter
    ...Gradebook.prototype
  };

  const student1 = {
    enrollments: [{grades: {}}],
    sections: ['1'],
    name: 'student',
  };
  const student2 = {...student1, sections: ['2']};
  const student3 = {...student1, sections: ['2']};
  [student1, student2, student3].forEach(s => gb.addRow(s));

  ok(student1.row == null, 'filtered out students get no row number');
  ok(student2.row === 0, 'other students do get a row number');
  ok(student3.row === 1, 'row number increments');
  ok(_.isEqual(gb.rows, [student2, student3]));
});

QUnit.module('Gradebook#groupTotalFormatter', {
  setup () {
    fakeENV.setup();
  },
  teardown () {
    fakeENV.teardown();
  },
});

test('calculates percentage from given  score and possible values', function () {
  const gradebook = new Gradebook({ settings: {}, sections: {} });
  const groupTotalOutput = gradebook.groupTotalFormatter(0, 0, { score: 9, possible: 10 }, {});
  ok(groupTotalOutput.includes('9 / 10'));
  ok(groupTotalOutput.includes('90%'));
});

test('displays percentage as "-" when group total score is positive infinity', function () {
  const gradebook = new Gradebook({ settings: {}, sections: {} });
  sandbox.stub(gradebook, 'calculateAndRoundGroupTotalScore').returns(Number.POSITIVE_INFINITY);
  const groupTotalOutput = gradebook.groupTotalFormatter(0, 0, { score: 9, possible: 0 }, {});
  ok(groupTotalOutput.includes('9 / 0'));
  ok(groupTotalOutput.includes('-'));
});

test('displays percentage as "-" when group total score is negative infinity', function () {
  const gradebook = new Gradebook({ settings: {}, sections: {} });
  sandbox.stub(gradebook, 'calculateAndRoundGroupTotalScore').returns(Number.NEGATIVE_INFINITY);
  const groupTotalOutput = gradebook.groupTotalFormatter(0, 0, { score: 9, possible: 0 }, {});
  ok(groupTotalOutput.includes('9 / 0'));
  ok(groupTotalOutput.includes('-'));
});

test('displays percentage as "-" when group total score is not a number', function () {
  const gradebook = new Gradebook({ settings: {}, sections: {} });
  sandbox.stub(gradebook, 'calculateAndRoundGroupTotalScore').returns(NaN);
  const groupTotalOutput = gradebook.groupTotalFormatter(0, 0, { score: 9, possible: 0 }, {});
  ok(groupTotalOutput.includes('9 / 0'));
  ok(groupTotalOutput.includes('-'));
});

QUnit.module('Gradebook#getFrozenColumnCount');

test('returns number of columns in frozen section', function () {
  const gradebook = new Gradebook({ settings: {}, sections: {} });
  gradebook.parentColumns = [{ id: 'student' }, { id: 'secondary_identifier' }];
  gradebook.customColumns = [{ id: 'custom_col_1' }];
  equal(gradebook.getFrozenColumnCount(), 3);
});

QUnit.module('Gradebook#switchTotalDisplay', {
  setupThis ({ showTotalGradeAsPoints = true } = {}) {
    return {
      options: {
        show_total_grade_as_points: showTotalGradeAsPoints,
        setting_update_url: 'http://settingUpdateUrl'
      },
      displayPointTotals () {
        return true;
      },
      grid: {
        invalidate: sinon.stub()
      },
      totalHeader: {
        switchTotalDisplay: sinon.stub()
      }
    }
  },

  setup () {
    sandbox.stub($, 'ajaxJSON');
    this.switchTotalDisplay = Gradebook.prototype.switchTotalDisplay;
  },

  teardown () {
    UserSettings.contextRemove('warned_about_totals_display');
  }
});

test('sets the warned_about_totals_display setting when called with true', function () {
  notOk(UserSettings.contextGet('warned_about_totals_display'));

  const self = this.setupThis();
  this.switchTotalDisplay.call(self, { dontWarnAgain: true });

  ok(UserSettings.contextGet('warned_about_totals_display'));
});

test('flips the show_total_grade_as_points property', function () {
  const self = this.setupThis();
  this.switchTotalDisplay.call(self, { dontWarnAgain: false });

  equal(self.options.show_total_grade_as_points, false);

  this.switchTotalDisplay.call(self, { dontWarnAgain: false });

  equal(self.options.show_total_grade_as_points, true);
});

test('updates the total display preferences for the current user', function () {
  const self = this.setupThis({ showTotalGradeAsPoints: false });
  this.switchTotalDisplay.call(self, { dontWarnAgain: false });

  equal($.ajaxJSON.callCount, 1);
  equal($.ajaxJSON.getCall(0).args[0], 'http://settingUpdateUrl');
  equal($.ajaxJSON.getCall(0).args[1], 'PUT');
  equal($.ajaxJSON.getCall(0).args[2].show_total_grade_as_points, true);
});

test('invalidates the grid so it re-renders it', function () {
  const self = this.setupThis();
  this.switchTotalDisplay.call(self, { dontWarnAgain: false });

  equal(self.grid.invalidate.callCount, 1);
});

test('updates the total grade column header with the new value of the show_total_grade_as_points property', function () {
  const self = this.setupThis();
  this.switchTotalDisplay.call(self, false);
  this.switchTotalDisplay.call(self, false)

  equal(self.totalHeader.switchTotalDisplay.callCount, 2);
  equal(self.totalHeader.switchTotalDisplay.getCall(0).args[0], false);
  equal(self.totalHeader.switchTotalDisplay.getCall(1).args[0], true);
});

QUnit.module('Gradebook#togglePointsOrPercentTotals', {
  setupThis () {
    return {
      options: {
        show_total_grade_as_points: true,
        setting_update_url: 'http://settingUpdateUrl'
      },
      switchTotalDisplay: sinon.stub()
    }
  },

  setup () {
    sandbox.stub($, 'ajaxJSON');
    this.togglePointsOrPercentTotals = Gradebook.prototype.togglePointsOrPercentTotals;
  },

  teardown () {
    UserSettings.contextRemove('warned_about_totals_display');
    $(".ui-dialog").remove();
  }
});

test('when user is ignoring warnings, immediately toggles the total grade display', function () {
  UserSettings.contextSet('warned_about_totals_display', true);

  const self = this.setupThis(true);

  this.togglePointsOrPercentTotals.call(self);

  equal(self.switchTotalDisplay.callCount, 1, 'toggles the total grade display');
});

test('when user is not ignoring warnings, return a dialog', function () {
  UserSettings.contextSet('warned_about_totals_display', false);

  const self = this.setupThis(true);
  const dialog = this.togglePointsOrPercentTotals.call(self);

  equal(dialog.constructor.name, 'GradeDisplayWarningDialog', 'returns a grade display warning dialog');

  dialog.cancel();
});

test('when user is not ignoring warnings, the dialog has a save property which is the switchTotalDisplay function', function () {
  sandbox.stub(UserSettings, 'contextGet').withArgs('warned_about_totals_display').returns(false);
  const self = this.setupThis(true);
  const dialog = this.togglePointsOrPercentTotals.call(self);

  equal(dialog.options.save, self.switchTotalDisplay);

  dialog.cancel();
});

QUnit.module('Gradebook', (_suiteHooks) => {
  let gradebook;

  QUnit.module('#updateSubmissionsFromExternal', (hooks) => {
    const columns = [
      { id: 'student', type: 'student' },
      { id: 'assignment_232', type: 'assignment' },
      { id: 'total_grade', type: 'total_grade' },
      { id: 'assignment_group_12', type: 'assignment' }
    ];

    hooks.beforeEach(() => {
      gradebook = createGradebook();

      gradebook.students = {
        1101: { id: '1101', row: '1', assignment_201: {}, assignment_202: {} },
        1102: { id: '1102', row: '2', assignment_201: {} }
      };
      gradebook.assignments = []
      gradebook.submissionStateMap = {
        setSubmissionCellState () {},
        getSubmissionState () { return { locked: false } }
      };

      sinon.stub(gradebook, 'updateAssignmentVisibilities');
      sinon.stub(gradebook, 'updateSubmission');
      sinon.stub(gradebook, 'calculateStudentGrade');
      sinon.stub(gradebook, 'updateRowTotals');

      gradebook.grid = {
        getActiveCell () {},
        getColumns () { return columns },
        updateCell: sinon.stub(),
        getActiveCellNode: sinon.stub(),
      };
    });

    test('ignores submissions for students not currently loaded', () => {
      const submissions = [
        { assignment_id: '201', user_id: '1101', score: 10, assignment_visible: true },
        { assignment_id: '201', user_id: '1103', score: 9, assignment_visible: true },
        { assignment_id: '201', user_id: '1102', score: 8, assignment_visible: true }
      ];
      gradebook.updateSubmissionsFromExternal(submissions);

      const rowsUpdated = gradebook.updateRowTotals.getCalls().map((stubCall) => stubCall.args[0]);
      deepEqual(rowsUpdated, ['1', '2']);
    });
  });
});
