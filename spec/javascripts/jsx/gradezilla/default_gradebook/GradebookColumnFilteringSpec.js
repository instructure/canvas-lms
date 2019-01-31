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
import DataLoader from 'jsx/gradezilla/DataLoader';
import {
  createGradebook,
  setFixtureHtml
} from 'jsx/gradezilla/default_gradebook/__tests__/GradebookSpecHelper';
import SlickGridSpecHelper from '../../gradezilla/default_gradebook/GradebookGrid/GridSupport/SlickGridSpecHelper'

QUnit.module('Gradebook Grid Column Filtering', function (suiteHooks) {
  let $fixture;
  let gridSpecHelper;
  let gradebook;
  let dataLoader;

  let assignmentGroups;
  let assignments;
  let contextModules;
  let customColumns;

  function createGradebookWithAllFilters (options = {}) {
    gradebook = createGradebook({
      settings: {
        selected_view_options_filters: ['assignmentGroups', 'modules', 'gradingPeriods', 'sections']
      },
      ...options
    })
    sinon.stub(gradebook, 'saveSettings').callsFake((settings, onSuccess = () => {}) => {
      onSuccess(settings)
    })
  }

  function createContextModules () {
    contextModules = [
      { id: '2601', position: 3, name: 'Final Module' },
      { id: '2602', position: 2, name: 'Second Module' },
      { id: '2603', position: 1, name: 'First Module' }
    ];
  }

  function createCustomColumns () {
    customColumns = [
      { id: '2401', teacher_notes: true, title: 'Notes' },
      { id: '2402', teacher_notes: false, title: 'Other Notes' }
    ];
  }

  function createAssignments () {
    assignments = {
      homework: [{
        id: '2301',
        assignment_group_id: '2201',
        course_id: '1201',
        due_at: '2015-05-04T12:00:00Z',
        html_url: '/assignments/2301',
        module_ids: ['2601'],
        module_positions: [1],
        muted: false,
        name: 'Math Assignment',
        omit_from_final_grade: false,
        points_possible: null,
        position: 1,
        published: true,
        submission_types: ['online_text_entry']
      }, {
        id: '2303',
        assignment_group_id: '2201',
        course_id: '1201',
        due_at: '2015-06-04T12:00:00Z',
        html_url: '/assignments/2302',
        module_ids: ['2601'],
        module_positions: [2],
        muted: false,
        name: 'English Assignment',
        omit_from_final_grade: false,
        points_possible: 15,
        position: 2,
        published: true,
        submission_types: ['online_text_entry']
      }],

      quizzes: [{
        id: '2302',
        assignment_group_id: '2202',
        course_id: '1201',
        due_at: '2015-05-05T12:00:00Z',
        html_url: '/assignments/2301',
        module_ids: ['2602'],
        module_positions: [1],
        muted: false,
        name: 'Math Quiz',
        omit_from_final_grade: false,
        points_possible: 10,
        position: 1,
        published: true,
        submission_types: ['online_quiz']
      }, {
        id: '2304',
        assignment_group_id: '2202',
        course_id: '1201',
        due_at: '2015-05-11T12:00:00Z',
        html_url: '/assignments/2302',
        module_ids: ['2603'],
        module_positions: [1],
        muted: false,
        name: 'English Quiz',
        omit_from_final_grade: false,
        points_possible: 20,
        position: 2,
        published: true,
        submission_types: ['online_quiz']
      }]
    };
  }

  function createAssignmentGroups () {
    assignmentGroups = [
      { id: '2201', position: 2, name: 'Homework', assignments: assignments.homework },
      { id: '2202', position: 1, name: 'Quizzes', assignments: assignments.quizzes }
    ];
  }

  function addStudentIds () {
    dataLoader.gotStudentIds.resolve({
      user_ids: ['1101']
    });
  }

  function addGradingPeriodAssignments () {
    dataLoader.gotGradingPeriodAssignments.resolve({
      grading_period_assignments: { 1401: ['2301', '2304'], 1402: ['2302', '2303'] }
    });
  }

  function addContextModules () {
    dataLoader.gotContextModules.resolve(contextModules);
  }

  function addCustomColumns () {
    dataLoader.gotCustomColumns.resolve(customColumns);
  }

  function addAssignmentGroups () {
    dataLoader.gotAssignmentGroups.resolve(assignmentGroups);
  }

  function addGridData () {
    addStudentIds();
    addContextModules();
    addCustomColumns();
    addAssignmentGroups();
    addGradingPeriodAssignments();
  }

  function addDataAndInitialize () {
    gradebook.initialize();
    addGridData();
    gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid);
  }

  suiteHooks.beforeEach(function () {
    $fixture = document.createElement('div');
    document.body.appendChild($fixture);
    setFixtureHtml($fixture);

    fakeENV.setup({
      current_user_id: '1101'
    });

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
    createContextModules();
    createCustomColumns();
  });

  suiteHooks.afterEach(function () {
    gradebook.destroy();
    DataLoader.loadGradebookData.restore();
    DataLoader.getDataForColumn.restore();
    fakeENV.teardown();
    $fixture.remove();
  });

  QUnit.module('with unpublished assignments', function (hooks) {
    function setShowUnpublishedAssignments (show) {
      gradebook.gridDisplaySettings.showUnpublishedAssignments = show;
    }

    hooks.beforeEach(function () {
      assignments.homework[1].published = false;
      assignments.quizzes[1].published = false;
      createGradebookWithAllFilters()
    });

    test('optionally shows all unpublished assignment columns at initial render', function () {
      setShowUnpublishedAssignments(true);
      addDataAndInitialize();
      const expectedColumns = [
        'assignment_2301', 'assignment_2302', 'assignment_2303', 'assignment_2304',
        'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally hides all unpublished assignment columns at initial render', function () {
      setShowUnpublishedAssignments(false);
      addDataAndInitialize();
      const expectedColumns = [
        'assignment_2301', 'assignment_2302', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally shows all unpublished assignment columns', function () {
      setShowUnpublishedAssignments(false);
      addDataAndInitialize();
      gradebook.toggleUnpublishedAssignments();
      const expectedColumns = [
        'assignment_2301', 'assignment_2302', 'assignment_2303', 'assignment_2304',
        'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally hides all unpublished assignment columns', function () {
      setShowUnpublishedAssignments(true);
      addDataAndInitialize();
      gradebook.toggleUnpublishedAssignments();
      const expectedColumns = [
        'assignment_2301', 'assignment_2302', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('sorts all scrollable columns after showing unpublished assignment columns', function () {
      const customOrder = [
        'student', 'custom_col_2401', 'custom_col_2402', 'total_grade', 'assignment_group_2201', 'assignment_2301',
        'assignment_2303', 'assignment_group_2202', 'assignment_2302', 'assignment_2304'
      ];
      setShowUnpublishedAssignments(true);
      addDataAndInitialize();
      gridSpecHelper.updateColumnOrder(customOrder);
      gradebook.toggleUnpublishedAssignments(); // hide unpublished
      gradebook.toggleUnpublishedAssignments(); // show unpublished
      deepEqual(gridSpecHelper.listColumnIds(), customOrder);
    });

    test('sorts all scrollable columns after hiding unpublished assignment columns', function () {
      const customOrder = [
        'student', 'custom_col_2401', 'custom_col_2402', 'total_grade', 'assignment_group_2201', 'assignment_2301',
        'assignment_2303', 'assignment_group_2202', 'assignment_2302', 'assignment_2304'
      ];
      setShowUnpublishedAssignments(true);
      addDataAndInitialize();
      gridSpecHelper.updateColumnOrder(customOrder);
      gradebook.toggleUnpublishedAssignments();
      const expectedColumns = [
        'student', 'custom_col_2401', 'custom_col_2402', 'total_grade', 'assignment_group_2201', 'assignment_2301',
        'assignment_group_2202', 'assignment_2302'
      ];
      deepEqual(gridSpecHelper.listColumnIds(), expectedColumns);
    });
  });

  QUnit.module('with attendance assignments', function (hooks) {
    function setShowAttendance (show) {
      gradebook.show_attendance = show;
    }

    hooks.beforeEach(function () {
      assignments.homework[0].submission_types = ['attendance'];
      assignments.homework[1].submission_types = ['attendance'];
      createGradebookWithAllFilters()
    });

    test('optionally shows all attendance assignment columns at initial render', function () {
      setShowAttendance(true);
      addDataAndInitialize();
      const expectedColumns = [
        'assignment_2301', 'assignment_2302', 'assignment_2303', 'assignment_2304',
        'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally hides all attendance assignment columns at initial render', function () {
      setShowAttendance(false);
      addDataAndInitialize();
      const expectedColumns = [
        'assignment_2302', 'assignment_2304', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });
  });

  test('does not show "not graded" assignments', function () {
    assignments.homework[1].submission_types = ['not_graded'];
    assignments.quizzes[1].submission_types = ['not_graded'];
    createGradebookWithAllFilters();
    addDataAndInitialize();
    const expectedColumns = [
      'assignment_2301', 'assignment_2302', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
    ];
    deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
  });

  QUnit.module('with multiple assignment groups', function (hooks) {
    hooks.beforeEach(function () {
      createGradebookWithAllFilters()
    });

    test('optionally shows assignment columns for all assignment groups at initial render', function () {
      addDataAndInitialize();
      gradebook.updateCurrentAssignmentGroup('0')
      const expectedColumns = [
        'assignment_2301', 'assignment_2302', 'assignment_2303', 'assignment_2304',
        'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally shows only assignment columns for the selected assignment group at initial render', function () {
      addDataAndInitialize();
      gradebook.updateCurrentAssignmentGroup('2201')
      const expectedColumns = [
        'assignment_2301', 'assignment_2303', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally shows assignment columns for all assignment groups', function () {
      addDataAndInitialize();
      gradebook.updateCurrentAssignmentGroup('0');
      const expectedColumns = [
        'assignment_2301', 'assignment_2302', 'assignment_2303', 'assignment_2304',
        'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally shows only assignment columns for the selected assignment group', function () {
      addDataAndInitialize();
      gradebook.updateCurrentAssignmentGroup('2202');
      const expectedColumns = [
        'assignment_2302', 'assignment_2304', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('sorts all scrollable columns after selecting an assignment group', function () {
      const customOrder = [
        'student', 'custom_col_2401', 'custom_col_2402', 'total_grade', 'assignment_group_2201', 'assignment_2301',
        'assignment_2303', 'assignment_group_2202', 'assignment_2302', 'assignment_2304'
      ];
      addDataAndInitialize();
      gridSpecHelper.updateColumnOrder(customOrder);
      gradebook.updateCurrentAssignmentGroup('2202');
      const expectedColumns = [
        'student', 'custom_col_2401', 'custom_col_2402', 'total_grade', 'assignment_group_2201',
        'assignment_group_2202', 'assignment_2302', 'assignment_2304'
      ];
      deepEqual(gridSpecHelper.listColumnIds(), expectedColumns);
    });

    test('sorts all scrollable columns after deselecting an assignment group', function () {
      const customOrder = [
        'student', 'custom_col_2401', 'custom_col_2402', 'total_grade', 'assignment_group_2201', 'assignment_2301',
        'assignment_2303', 'assignment_group_2202', 'assignment_2302', 'assignment_2304'
      ];
      addDataAndInitialize();
      gridSpecHelper.updateColumnOrder(customOrder);
      gradebook.updateCurrentAssignmentGroup('2202');
      gradebook.updateCurrentAssignmentGroup('0');
      deepEqual(gridSpecHelper.listColumnIds(), customOrder);
    });
  });

  QUnit.module('with grading periods', function (hooks) {
    hooks.beforeEach(function () {
      createGradebookWithAllFilters({
        grading_period_set: {
          id: '1501',
          display_totals_for_all_grading_periods: true,
          grading_periods: [{id: '1401', title: 'GP1'}, {id: '1402', title: 'GP2'}]
        }
      });
    });

    test('optionally shows assignment columns for all grading periods at initial render', function () {
      gradebook.setFilterColumnsBySetting('gradingPeriodId', '0');
      addDataAndInitialize();
      const expectedColumns = [
        'assignment_2301', 'assignment_2302', 'assignment_2303', 'assignment_2304',
        'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally shows only assignment columns for the selected grading period at initial render', function () {
      gradebook.setFilterColumnsBySetting('gradingPeriodId', '1401');
      addDataAndInitialize();
      const expectedColumns = [
        'assignment_2301', 'assignment_2304', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally shows assignment columns for all grading periods', function () {
      addDataAndInitialize();
      gradebook.updateCurrentGradingPeriod('0');
      const expectedColumns = [
        'assignment_2301', 'assignment_2302', 'assignment_2303', 'assignment_2304',
        'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally shows only assignment columns for the selected grading period', function () {
      addDataAndInitialize();
      gradebook.updateCurrentGradingPeriod('1402');
      const expectedColumns = [
        'assignment_2302', 'assignment_2303', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally hides assignment group and total grade columns when filtering at initial render', function () {
      gradebook.gradingPeriodSet.displayTotalsForAllGradingPeriods = false;
      addDataAndInitialize();
      gradebook.setFilterColumnsBySetting('gradingPeriodId', '0');
      const expectedColumns = [
        'assignment_2301', 'assignment_2302', 'assignment_2303', 'assignment_2304'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally hides assignment group and total grade columns when filtering', function () {
      gradebook.gradingPeriodSet.displayTotalsForAllGradingPeriods = false;
      addDataAndInitialize();
      gradebook.updateCurrentGradingPeriod('0');
      const expectedColumns = [
        'assignment_2301', 'assignment_2302', 'assignment_2303', 'assignment_2304'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('sorts all scrollable columns after selecting a grading period', function () {
      const customOrder = [
        'student', 'custom_col_2401', 'custom_col_2402', 'total_grade', 'assignment_group_2201', 'assignment_2301',
        'assignment_2303', 'assignment_group_2202', 'assignment_2302', 'assignment_2304'
      ];
      addDataAndInitialize();
      gridSpecHelper.updateColumnOrder(customOrder);
      gradebook.updateCurrentGradingPeriod('1402');
      const expectedColumns = [
        'student', 'custom_col_2401', 'custom_col_2402', 'total_grade', 'assignment_group_2201',
        'assignment_2303', 'assignment_group_2202', 'assignment_2302'
      ];
      deepEqual(gridSpecHelper.listColumnIds(), expectedColumns);
    });

    test('sorts all scrollable columns after deselecting a grading period', function () {
      const customOrder = [
        'student', 'custom_col_2401', 'custom_col_2402', 'total_grade', 'assignment_group_2201', 'assignment_2301',
        'assignment_2303', 'assignment_group_2202', 'assignment_2302', 'assignment_2304'
      ];
      addDataAndInitialize();
      gridSpecHelper.updateColumnOrder(customOrder);
      gradebook.updateCurrentGradingPeriod('1402');
      gradebook.updateCurrentGradingPeriod('0');
      deepEqual(gridSpecHelper.listColumnIds(), customOrder);
    });
  });

  QUnit.module('with multiple context modules', function (hooks) {
    hooks.beforeEach(function () {
      createGradebookWithAllFilters()
    });

    test('optionally shows assignment columns for all context modules at initial render', function () {
      gradebook.setFilterColumnsBySetting('contextModuleId', '0');
      addDataAndInitialize();
      const expectedColumns = [
        'assignment_2301', 'assignment_2302', 'assignment_2303', 'assignment_2304',
        'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally shows only assignment columns for the selected context module at initial render', function () {
      gradebook.setFilterColumnsBySetting('contextModuleId', '2601');
      addDataAndInitialize();
      const expectedColumns = [
        'assignment_2301', 'assignment_2303', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally shows assignment columns for all context modules', function () {
      addDataAndInitialize();
      gradebook.updateCurrentModule('0');
      const expectedColumns = [
        'assignment_2301', 'assignment_2302', 'assignment_2303', 'assignment_2304',
        'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('optionally shows only assignment columns for the selected context module', function () {
      addDataAndInitialize();
      gradebook.updateCurrentModule('2602');
      const expectedColumns = [
        'assignment_2302', 'assignment_group_2201', 'assignment_group_2202', 'total_grade'
      ];
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns);
    });

    test('sorts all scrollable columns after selecting a context module', function () {
      const customOrder = [
        'student', 'custom_col_2401', 'custom_col_2402', 'total_grade', 'assignment_group_2201', 'assignment_2301',
        'assignment_2303', 'assignment_group_2202', 'assignment_2302', 'assignment_2304'
      ];
      addDataAndInitialize();
      gridSpecHelper.updateColumnOrder(customOrder);
      gradebook.updateCurrentModule('2601');
      const expectedColumns = [
        'student', 'custom_col_2401', 'custom_col_2402', 'total_grade', 'assignment_group_2201', 'assignment_2301',
        'assignment_2303', 'assignment_group_2202'
      ];
      deepEqual(gridSpecHelper.listColumnIds(), expectedColumns);
    });

    test('sorts all scrollable columns after deselecting a context module', function () {
      const customOrder = [
        'student', 'custom_col_2401', 'custom_col_2402', 'total_grade', 'assignment_group_2201', 'assignment_2301',
        'assignment_2303', 'assignment_group_2202', 'assignment_2302', 'assignment_2304'
      ];
      addDataAndInitialize();
      gridSpecHelper.updateColumnOrder(customOrder);
      gradebook.updateCurrentModule('2602');
      gradebook.updateCurrentModule('0');
      deepEqual(gridSpecHelper.listColumnIds(), customOrder);
    });
  });
});
