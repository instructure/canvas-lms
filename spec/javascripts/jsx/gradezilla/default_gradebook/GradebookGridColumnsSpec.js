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

import $ from 'jquery';
import fakeENV from 'helpers/fakeENV';
import {
  createGradebook,
  setFixtureHtml
} from 'spec/jsx/gradezilla/default_gradebook/GradebookSpecHelper';
import SlickGridSpecHelper from 'spec/jsx/gradezilla/default_gradebook/slick-grid/SlickGridSpecHelper';
import DataLoader from 'jsx/gradezilla/DataLoader';

QUnit.module('Gradebook Grid Columns', function (suiteHooks) {
  let $fixture;
  let gridSpecHelper;
  let gradebook;
  let dataLoader;
  let server;

  let assignmentGroups;
  let assignments;
  let customColumns;

  function createAssignments () {
    assignments = {
      homework: [{
        id: '2301',
        assignment_group_id: '2201',
        course_id: '1201',
        html_url: '/assignments/2301',
        muted: false,
        name: 'Math Assignment',
        omit_from_final_grade: false,
        position: 1,
        published: true,
        submission_types: ['online_text_entry']
      }],

      quizzes: [{
        id: '2302',
        assignment_group_id: '2202',
        course_id: '1201',
        html_url: '/assignments/2302',
        muted: false,
        name: 'English Assignment',
        omit_from_final_grade: false,
        position: 1,
        published: true,
        submission_types: ['online_text_entry']
      }]
    };
  }

  function createAssignmentGroups () {
    assignmentGroups = [
      { id: '2201', position: 1, name: 'Homework', assignments: assignments.homework },
      { id: '2202', position: 2, name: 'Quizzes', assignments: assignments.quizzes }
    ];
  }

  function createCustomColumns () {
    customColumns = [
      { id: '2401', teacher_notes: true, hidden: false, title: 'Notes' },
      { id: '2402', teacher_notes: false, hidden: false, title: 'Other Notes' }
    ];
  }

  function addStudentIds () {
    dataLoader.gotStudentIds.resolve({
      user_ids: ['1101']
    });
  }

  function addGradingPeriodAssignments () {
    dataLoader.gotGradingPeriodAssignments.resolve({
      grading_period_assignments: {
        1401: ['2301'],
        1402: ['2302']
      }
    });
  }

  function addCustomColumns () {
    dataLoader.gotCustomColumns.resolve(customColumns);
  }

  function addAssignmentGroups () {
    dataLoader.gotAssignmentGroups.resolve(assignmentGroups);
  }

  function addGridData () {
    addStudentIds();
    addCustomColumns();
    addAssignmentGroups();
    addGradingPeriodAssignments();
  }

  function createGradebookAndAddData (options) {
    gradebook = createGradebook(options);
    gradebook.initialize();
    addGridData();
  }

  suiteHooks.beforeEach(function () {
    $fixture = document.createElement('div');
    document.body.appendChild($fixture);
    setFixtureHtml($fixture);

    fakeENV.setup({
      current_user_id: '1101'
    });
    server = sinon.fakeServer.create();

    dataLoader = {
      gotAssignmentGroups: $.Deferred(),
      gotContextModules: $.Deferred(),
      gotCustomColumnData: $.Deferred(),
      gotCustomColumns: $.Deferred(),
      gotGradingPeriodAssignments: $.Deferred(),
      gotStudentIds: $.Deferred(),
      gotStudents: $.Deferred(),
      gotSubmissions: $.Deferred()
    };
    sinon.stub(DataLoader, 'loadGradebookData').returns(dataLoader);
    sinon.stub(DataLoader, 'getDataForColumn');

    createAssignments();
    createAssignmentGroups();
    createCustomColumns();
  });

  suiteHooks.afterEach(function () {
    gradebook.gradebookGrid.gridSupport.destroy();
    gradebook.gradebookGrid.grid.destroy();
    gradebook.destroy();
    DataLoader.loadGradebookData.restore();
    DataLoader.getDataForColumn.restore();
    server.restore();
    fakeENV.teardown();
    $fixture.remove();
  });

  QUnit.module('when initializing the grid', function (hooks) {
    hooks.beforeEach(function () {
      createGradebookAndAddData();
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid);
    });

    test('adds the student column to the grid as a frozen column', function () {
      ok(gridSpecHelper.listFrozenColumnIds().includes('student'));
    });

    test('adds the total grade column to the grid as a scrollable column', function () {
      ok(gridSpecHelper.listScrollableColumnIds().includes('total_grade'));
    });

    test('adds each assignment column to the grid', function () {
      const columns = gridSpecHelper.listColumns().filter(column => column.type === 'assignment');
      deepEqual(columns.map(column => column.id), ['assignment_2301', 'assignment_2302']);
    });

    test('adds each assignment group column to the grid', function () {
      const columns = gridSpecHelper.listColumns().filter(column => column.type === 'assignment_group');
      deepEqual(columns.map(column => column.id), ['assignment_group_2201', 'assignment_group_2202']);
    });

    test('freezes custom columns', function () {
      const columnIds = gridSpecHelper.listFrozenColumnIds().filter(columnId => columnId.match(/^custom_col_/));
      deepEqual(columnIds.sort(), ['custom_col_2401', 'custom_col_2402']);
    });

    test('does not freeze assignment columns', function () {
      const columnIds = gridSpecHelper.listScrollableColumnIds().filter(columnId => columnId.match(/^assignment_(?!group)/));
      deepEqual(columnIds.sort(), ['assignment_2301', 'assignment_2302']);
    });

    test('does not freeze assignment group columns', function () {
      const columnIds = gridSpecHelper.listScrollableColumnIds().filter(columnId => columnId.match(/^assignment_group_/));
      deepEqual(columnIds.sort(), ['assignment_group_2201', 'assignment_group_2202']);
    });
  });

  QUnit.module('when reordering columns with drag and drop', function (hooks) {
    let reorderApiResponse;

    hooks.beforeEach(function () {
      createGradebookAndAddData();
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid);
      reorderApiResponse = $.Deferred();
      sinon.stub(gradebook, 'reorderCustomColumns').returns(reorderApiResponse);
      sinon.stub(gradebook, 'storeCustomColumnOrder');
    });

    test('updates the stored custom column order when custom columns were reordered', function () {
      gridSpecHelper.updateColumnOrder([
        'student', 'custom_col_2402', 'custom_col_2401', 'assignment_2301', 'assignment_2302',
        'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ]);
      reorderApiResponse.resolve();
      deepEqual(gradebook.gradebookContent.customColumns.map(column => column.id), ['2402', '2401']);
    });

    test('stores "custom" column order when assignment columns were reordered', function () {
      gridSpecHelper.updateColumnOrder([
        'student', 'custom_col_2401', 'custom_col_2402', 'assignment_2302', 'assignment_2301',
        'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ]);
      strictEqual(gradebook.storeCustomColumnOrder.callCount, 1);
    });

    test('stores "custom" column order when assignment group columns were reordered', function () {
      gridSpecHelper.updateColumnOrder([
        'student', 'custom_col_2401', 'custom_col_2402', 'assignment_2301', 'assignment_2302',
        'assignment_group_2202', 'assignment_group_2201', 'total_grade'
      ]);
      strictEqual(gradebook.storeCustomColumnOrder.callCount, 1);
    });
  });

  QUnit.module('when rearranging scrollable columns', function (hooks) {
    hooks.beforeEach(function () {
      createGradebookAndAddData();
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid);
    });

    test('reorders sortable grid columns to match intended ascending sort order', function () {
      gradebook.arrangeColumnsBy({ sortBy: 'default', direction: 'ascending' });
      const expectedOrder = [
        'assignment_2301', 'assignment_2302', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder);
    });

    test('reorders sortable grid columns to match intended descending sort order', function () {
      gradebook.arrangeColumnsBy({ sortBy: 'default', direction: 'descending' });
      const expectedOrder = [
        'assignment_2302', 'assignment_2301', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder);
    });

    test('does not reorder frozen grid columns', function () {
      gridSpecHelper.updateColumnOrder([
        'custom_col_2402', 'student', 'custom_col_2401', 'assignment_2301', 'assignment_2302',
        'assignment_group_2202', 'assignment_group_2201', 'total_grade'
      ]);
      gradebook.arrangeColumnsBy({ sortBy: 'default', direction: 'ascending' });
      deepEqual(gridSpecHelper.listFrozenColumnIds(), ['custom_col_2402', 'student', 'custom_col_2401']);
    });
  });

  QUnit.module('when freezing the total grade column', function (hooks) {
    hooks.beforeEach(function () {
      createGradebookAndAddData();
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid);
    });

    test('places the total grade column after the student column', function () {
      gradebook.freezeTotalGradeColumn();
      deepEqual(gridSpecHelper.listFrozenColumnIds(), ['student', 'total_grade', 'custom_col_2401', 'custom_col_2402']);
    });

    test('removes the total grade column from the scrollable columns', function () {
      gradebook.freezeTotalGradeColumn();
      const expectedOrder = ['assignment_2301', 'assignment_2302', 'assignment_group_2201', 'assignment_group_2202'];
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder);
    });

    test('preserves relative order of frozen columns', function () {
      gridSpecHelper.updateColumnOrder([
        'student', 'custom_col_2402', 'custom_col_2401', 'assignment_group_2202', 'assignment_2302', 'total_grade',
        'assignment_group_2201', 'assignment_2301'
      ]);
      gradebook.freezeTotalGradeColumn();
      deepEqual(gridSpecHelper.listFrozenColumnIds(), ['student', 'total_grade', 'custom_col_2402', 'custom_col_2401']);
    });

    test('preserves relative order of other scrollable columns', function () {
      gridSpecHelper.updateColumnOrder([
        'student', 'custom_col_2402', 'custom_col_2401', 'assignment_group_2202', 'assignment_2302', 'total_grade',
        'assignment_group_2201', 'assignment_2301'
      ]);
      gradebook.freezeTotalGradeColumn();
      const expectedOrder = ['assignment_group_2202', 'assignment_2302', 'assignment_group_2201', 'assignment_2301'];
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder);
    });
  });

  QUnit.module('when moving the frozen total grade column to the end of the scrollable columns', function (hooks) {
    hooks.beforeEach(function () {
      createGradebookAndAddData();
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid);
      gradebook.freezeTotalGradeColumn();
    });

    test('removes the total grade column from the frozen columns', function () {
      gradebook.moveTotalGradeColumnToEnd();
      deepEqual(gridSpecHelper.listFrozenColumnIds(), ['student', 'custom_col_2401', 'custom_col_2402']);
    });

    test('places the total grade column after all scrollable columns', function () {
      gradebook.moveTotalGradeColumnToEnd();
      const expectedOrder = [
        'assignment_2301', 'assignment_2302', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder);
    });

    test('preserves relative order of frozen columns', function () {
      gridSpecHelper.updateColumnOrder([
        'student', 'custom_col_2402', 'total_grade', 'custom_col_2401', 'assignment_group_2202', 'assignment_2302',
        'assignment_group_2201', 'assignment_2301'
      ]);
      gradebook.moveTotalGradeColumnToEnd();
      deepEqual(gridSpecHelper.listFrozenColumnIds(), ['student', 'custom_col_2402', 'custom_col_2401']);
    });

    test('preserves relative order of other scrollable columns', function () {
      gridSpecHelper.updateColumnOrder([
        'student', 'custom_col_2402', 'total_grade', 'custom_col_2401', 'assignment_group_2202', 'assignment_2302',
        'assignment_group_2201', 'assignment_2301'
      ]);
      gradebook.moveTotalGradeColumnToEnd();
      const expectedOrder = [
        'assignment_group_2202', 'assignment_2302', 'assignment_group_2201', 'assignment_2301', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder);
    });
  });

  QUnit.module('when moving the scrollable total grade column to the end of scrollable columns', function (hooks) {
    hooks.beforeEach(function () {
      createGradebookAndAddData();
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid);
    });

    test('places the total grade column after all scrollable columns', function () {
      gridSpecHelper.updateColumnOrder([
        'student', 'custom_col_2401', 'custom_col_2402', 'assignment_2301', 'assignment_2302', 'total_grade',
        'assignment_group_2201', 'assignment_group_2202'
      ]);
      gradebook.moveTotalGradeColumnToEnd();
      const expectedOrder = [
        'assignment_2301', 'assignment_2302', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder);
    });

    test('preserves order of frozen columns', function () {
      gridSpecHelper.updateColumnOrder([
        'student', 'custom_col_2402', 'custom_col_2401', 'assignment_group_2202', 'assignment_2302', 'total_grade',
        'assignment_group_2201', 'assignment_2301'
      ]);
      gradebook.moveTotalGradeColumnToEnd();
      deepEqual(gridSpecHelper.listFrozenColumnIds(), ['student', 'custom_col_2402', 'custom_col_2401']);
    });

    test('preserves relative order of other scrollable columns', function () {
      gridSpecHelper.updateColumnOrder([
        'student', 'custom_col_2402', 'custom_col_2401', 'assignment_group_2202', 'assignment_2302', 'total_grade',
        'assignment_group_2201', 'assignment_2301'
      ]);
      gradebook.moveTotalGradeColumnToEnd();
      const expectedOrder = [
        'assignment_group_2202', 'assignment_2302', 'assignment_group_2201', 'assignment_2301', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder);
    });
  });

  QUnit.module('when using grading periods', function (hooks) {
    function initializeAndAddData () {
      gradebook.initialize();
      addGridData();
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid);
    }

    hooks.beforeEach(function () {
      gradebook = createGradebook({
        grading_period_set: {
          id: '1301',
          display_totals_for_all_grading_periods: false,
          grading_periods: [
            { id: '1401', title: 'Grading Period 1' },
            { id: '1402', title: 'Grading Period 2' }
          ]
        }
      });
    });

    test('excludes assignment group columns when setting is disabled', function () {
      initializeAndAddData();
      const columns = gridSpecHelper.listColumns().filter(column => column.type === 'assignment_group');
      deepEqual(columns.map(column => column.id), []);
    });

    test('excludes the total grade column when setting is disabled', function () {
      initializeAndAddData();
      const columns = gridSpecHelper.listColumns().filter(column => column.type === 'total_grade');
      deepEqual(columns.map(column => column.id), []);
    });

    test('includes assignment group and total grade columns when setting is enabled', function () {
      gradebook.gradingPeriodSet.displayTotalsForAllGradingPeriods = true;
      initializeAndAddData();
      const columns = gridSpecHelper.listColumns().filter(column => column.type === 'assignment_group');
      deepEqual(columns.map(column => column.id), ['assignment_group_2201', 'assignment_group_2202']);
    });

    test('includes the total grade column when setting is enabled', function () {
      gradebook.gradingPeriodSet.displayTotalsForAllGradingPeriods = true;
      initializeAndAddData();
      const columns = gridSpecHelper.listColumns().filter(column => column.type === 'total_grade');
      deepEqual(columns.map(column => column.id), ['total_grade']);
    });
  });

  QUnit.module('when changing column filters', function (hooks) {
    hooks.beforeEach(function () {
      createGradebookAndAddData({
        grading_period_set: {
          id: '1301',
          display_totals_for_all_grading_periods: true,
          grading_periods: [
            { id: '1401', title: 'Grading Period 1' },
            { id: '1402', title: 'Grading Period 2' }
          ]
        }
      });
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid);
      gradebook.getAssignment('2302').published = false;
      sinon.stub(gradebook, 'saveSettings');
    });

    test('removes unpublished assignment columns when filtered', function () {
      gradebook.toggleUnpublishedAssignments();
      const expectedOrder = [
        'assignment_2301', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder);
    });

    test('removes unrelated assignment columns when filtering by assignment group', function () {
      gradebook.updateCurrentAssignmentGroup('2202');
      const expectedOrder = [
        'assignment_2302', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder);
    });

    test('removes unrelated assignment columns when filtering by grading period', function () {
      gradebook.updateCurrentGradingPeriod('1401');
      const expectedOrder = [
        'assignment_2301', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder);
    });
  });

  QUnit.module('when teacher notes are hidden', function (hooks) {
    hooks.beforeEach(function () {
      customColumns[0].hidden = true;
      createGradebookAndAddData({ teacher_notes: { id: '2401', title: 'Notes', teacher_notes: true, hidden: true } });
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid);
    });

    test('does not include the column in the grid', function () {
      const columns = gridSpecHelper.listColumns().filter(column => column.id.match(/^custom_col_/));
      deepEqual(columns.map(column => column.id), ['custom_col_2402']);
    });

    test('adds the column to the frozen columns when showing', function () {
      gradebook.showNotesColumn();
      deepEqual(gridSpecHelper.listFrozenColumnIds(), ['student', 'custom_col_2401', 'custom_col_2402']);
    });
  });

  QUnit.module('when hiding the teacher notes column', function (hooks) {
    hooks.beforeEach(function () {
      createGradebookAndAddData();
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid);
    });

    test('removes the column from the frozen columns', function () {
      gradebook.hideNotesColumn();
      deepEqual(gridSpecHelper.listFrozenColumnIds(), ['student', 'custom_col_2402']);
    });
  });
});
