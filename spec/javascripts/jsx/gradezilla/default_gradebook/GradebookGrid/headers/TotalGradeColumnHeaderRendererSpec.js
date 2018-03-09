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

import ReactDOM from 'react-dom';
import { createGradebook, setFixtureHtml } from '../../GradebookSpecHelper';
import TotalGradeColumnHeaderRenderer
from 'jsx/gradezilla/default_gradebook/GradebookGrid/headers/TotalGradeColumnHeaderRenderer'

QUnit.module('TotalGradeColumnHeaderRenderer', function (suiteHooks) {
  let $container;
  let gradebook;
  let gridSupport;
  let columns;
  let column;
  let renderer;
  let component;

  function render () {
    renderer.render(column, $container, gridSupport, { ref (ref) { component = ref } });
  }

  suiteHooks.beforeEach(function () {
    $container = document.createElement('div');
    document.body.appendChild($container);
    setFixtureHtml($container);

    gradebook = createGradebook();
    sinon.stub(gradebook, 'saveSettings')
    columns = {
      frozen: [{ id: 'student' }],
      scrollable: [{ id: 'assignment_2301' }, { id: 'total_grade' }]
    };

    gridSupport = {
      columns: {
        getColumns () {
          return columns;
        }
      }
    };

    column = { id: 'total_grade' };
    renderer = new TotalGradeColumnHeaderRenderer(gradebook);
  });

  suiteHooks.afterEach(function() {
    $container.remove();
  });

  QUnit.module('#render', function () {
    test('renders the TotalGradeColumnHeader to the given container node', function () {
      render();
      ok($container.innerText.includes('Total'), 'the "Total" header is rendered');
    });

    test('calls the "ref" callback option with the component reference', function () {
      render();
      equal(component.constructor.name, 'TotalGradeColumnHeader');
    });

    test('includes a callback for adding elements to the Gradebook KeyboardNav', function () {
      sinon.stub(gradebook.keyboardNav, 'addGradebookElement');
      render();
      component.props.addGradebookElement();
      strictEqual(gradebook.keyboardNav.addGradebookElement.callCount, 1);
    });

    test('sets grabFocus to true when the column header option menu needs focus', function () {
      sinon.stub(gradebook, 'totalColumnShouldFocus').returns(true);
      render();
      strictEqual(component.props.grabFocus, true);
    });

    test('sets grabFocus to true when the column header option menu does not need focus', function () {
      sinon.stub(gradebook, 'totalColumnShouldFocus').returns(false);
      render();
      strictEqual(component.props.grabFocus, false);
    });

    test('displays grades as points when set in gradebook options', function () {
      gradebook.options.show_total_grade_as_points = true;
      render();
      equal(component.props.gradeDisplay.currentDisplay, 'points');
    });

    test('displays grades as percent when set in gradebook options', function () {
      gradebook.options.show_total_grade_as_points = false;
      render();
      equal(component.props.gradeDisplay.currentDisplay, 'percentage');
    });

    test('hides the action to change grade display when assignment groups are weighted', function () {
      sinon.stub(gradebook, 'weightedGroups').returns(true);
      render();
      strictEqual(component.props.gradeDisplay.hidden, true);
    });

    test('hides the action to change grade display when grading periods are weighted', function () {
      gradebook.gradingPeriodSet = { id: '1', weighted: true };
      render();
      strictEqual(component.props.gradeDisplay.hidden, true);
    });

    test('shows the action to change grade display when assignment groups are not weighted', function () {
      sinon.stub(gradebook, 'weightedGroups').returns(false);
      render();
      strictEqual(component.props.gradeDisplay.hidden, false);
    });

    test('shows the action to change grade display when grading periods are not weighted', function () {
      gradebook.gradingPeriodSet = { id: '1', weighted: false };
      render();
      strictEqual(component.props.gradeDisplay.hidden, false);
    });

    test('includes a callback to toggle grade display', function () {
      sinon.stub(gradebook, 'togglePointsOrPercentTotals');
      render();
      component.props.gradeDisplay.onSelect();
      strictEqual(gradebook.togglePointsOrPercentTotals.callCount, 1);
    });

    test('includes a callback for keyDown events', function () {
      sinon.stub(gradebook, 'handleHeaderKeyDown');
      render();
      component.props.onHeaderKeyDown({});
      strictEqual(gradebook.handleHeaderKeyDown.callCount, 1);
    });

    test('calls Gradebook#handleHeaderKeyDown with a given event', function () {
      const exampleEvent = new Event('example');
      sinon.stub(gradebook, 'handleHeaderKeyDown');
      render();
      component.props.onHeaderKeyDown(exampleEvent);
      const event = gradebook.handleHeaderKeyDown.lastCall.args[0];
      equal(event, exampleEvent);
    });

    test('calls Gradebook#handleHeaderKeyDown with a given event', function () {
      sinon.stub(gradebook, 'handleHeaderKeyDown');
      render();
      component.props.onHeaderKeyDown({});
      const columnId = gradebook.handleHeaderKeyDown.lastCall.args[1];
      equal(columnId, column.id);
    });

    test('includes a callback for closing the column header menu', function () {
      sinon.stub(gradebook, 'handleColumnHeaderMenuClose');
      render();
      component.props.onMenuClose();
      strictEqual(gradebook.handleColumnHeaderMenuClose.callCount, 1);
    });

    test('sets position.isInBack to true when the column is the last scrollable column', function () {
      render();
      strictEqual(component.props.position.isInBack, true);
    });

    test('sets position.isInBack to false when the column is not the last scrollable column', function () {
      columns.scrollable = [{ id: 'total_grade' }, { id: 'assignment_2301' }];
      render();
      strictEqual(component.props.position.isInBack, false);
    });

    test('sets position.isInBack to false when the column is not scrollable', function () {
      columns.frozen = [{ id: 'student' }, { id: 'total_grade' }];
      columns.scrollable = [{ id: 'assignment_2301' }];
      render();
      strictEqual(component.props.position.isInBack, false);
    });

    test('sets position.isInFront to true when the column is frozen', function () {
      columns.frozen = [{ id: 'student' }, { id: 'total_grade' }];
      columns.scrollable = [{ id: 'assignment_2301' }];
      render();
      strictEqual(component.props.position.isInFront, true);
    });

    test('sets position.isInFront to false when the column is not frozen', function () {
      render();
      strictEqual(component.props.position.isInFront, false);
    });

    test('includes a callback for moving the column to the end', function () {
      sinon.stub(gradebook, 'moveTotalGradeColumnToEnd');
      render();
      component.props.position.onMoveToBack();
      strictEqual(gradebook.moveTotalGradeColumnToEnd.callCount, 1);
    });

    test('includes a callback for freezing the column', function () {
      sinon.stub(gradebook, 'freezeTotalGradeColumn');
      render();
      component.props.position.onMoveToFront();
      strictEqual(gradebook.freezeTotalGradeColumn.callCount, 1);
    });

    test('includes a callback for removing elements to the Gradebook KeyboardNav', function () {
      sinon.stub(gradebook.keyboardNav, 'removeGradebookElement');
      render();
      component.props.removeGradebookElement();
      strictEqual(gradebook.keyboardNav.removeGradebookElement.callCount, 1);
    });

    test('includes the "Sort by" direction setting', function () {
      render();
      equal(component.props.sortBySetting.direction, 'ascending');
    });

    test('sets the "Sort by" disabled setting to true when assignments are not loaded', function () {
      gradebook.setAssignmentsLoaded(false);
      gradebook.setStudentsLoaded(true);
      gradebook.setSubmissionsLoaded(true);
      render();
      strictEqual(component.props.sortBySetting.disabled, true);
    });

    test('sets the "Sort by" disabled setting to true when students are not loaded', function () {
      gradebook.setAssignmentsLoaded(true);
      gradebook.setStudentsLoaded(false);
      gradebook.setSubmissionsLoaded(true);
      render();
      strictEqual(component.props.sortBySetting.disabled, true);
    });

    test('sets the "Sort by" disabled setting to true when submissions are not loaded', function () {
      gradebook.setAssignmentsLoaded(true);
      gradebook.setStudentsLoaded(true);
      gradebook.setSubmissionsLoaded(false);
      render();
      strictEqual(component.props.sortBySetting.disabled, true);
    });

    test('sets the "Sort by" disabled setting to false when necessary data are loaded', function () {
      gradebook.setAssignmentsLoaded(true);
      gradebook.setStudentsLoaded(true);
      gradebook.setSubmissionsLoaded(true);
      render();
      strictEqual(component.props.sortBySetting.disabled, false);
    });

    test('sets the "Sort by" isSortColumn setting to true when sorting by this column', function () {
      gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending');
      render();
      strictEqual(component.props.sortBySetting.isSortColumn, true);
    });

    test('sets the "Sort by" isSortColumn setting to false when not sorting by this column', function () {
      gradebook.setSortRowsBySetting('student', 'sortable_name', 'ascending');
      render();
      strictEqual(component.props.sortBySetting.isSortColumn, false);
    });

    test('includes the onSortByGradeAscending callback', function () {
      gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending');
      render();
      component.props.sortBySetting.onSortByGradeAscending();
      const expectedSetting = { columnId: column.id, direction: 'ascending', settingKey: 'grade' };
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting);
    });

    test('includes the onSortByGradeDescending callback', function () {
      gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending');
      render();
      component.props.sortBySetting.onSortByGradeDescending();
      const expectedSetting = { columnId: column.id, direction: 'descending', settingKey: 'grade' };
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting);
    });

    test('includes the "Sort by" settingKey', function () {
      gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending');
      render();
      equal(component.props.sortBySetting.settingKey, 'grade');
    });

    test('sets weightedGroups to true when groups are weighted', function () {
      sinon.stub(gradebook, 'weightedGroups').returns(true);
      render();
      strictEqual(component.props.weightedGroups, true);
    });

    test('sets weightedGroups to false when groups are not weighted', function () {
      sinon.stub(gradebook, 'weightedGroups').returns(false);
      render();
      strictEqual(component.props.weightedGroups, false);
    });
  });

  QUnit.module('#destroy', function () {
    test('unmounts the component', function () {
      render();
      renderer.destroy({}, $container);
      const removed = ReactDOM.unmountComponentAtNode($container);
      strictEqual(removed, false, 'the component was already unmounted');
    });
  });
});
