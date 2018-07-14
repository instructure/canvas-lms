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
import StudentColumnHeaderRenderer
from 'jsx/gradezilla/default_gradebook/GradebookGrid/headers/StudentColumnHeaderRenderer'

QUnit.module('StudentColumnHeaderRenderer', function (suiteHooks) {
  let $container;
  let gradebook;
  let renderer;
  let component;

  function render () {
    renderer.render({} /* column */, $container, {} /* gridSupport */, { ref (ref) { component = ref } });
  }

  suiteHooks.beforeEach(function () {
    $container = document.createElement('div');
    document.body.appendChild($container);
    setFixtureHtml($container);

    gradebook = createGradebook({
      login_handle_name: 'a_jones',
      sis_name: 'Example SIS'
    });
    sinon.stub(gradebook, 'saveSettings')
    renderer = new StudentColumnHeaderRenderer(gradebook);
  });

  suiteHooks.afterEach(function() {
    $container.remove();
  });

  QUnit.module('#render', function () {
    test('renders the StudentColumnHeader to the given container node', function () {
      render();
      ok($container.innerText.includes('Student Name'), 'the "Student Name" header is rendered');
    });

    test('calls the "ref" callback option with the component reference', function () {
      render();
      equal(component.constructor.name, 'StudentColumnHeader');
    });

    test('includes a callback for adding elements to the Gradebook KeyboardNav', function () {
      sinon.stub(gradebook.keyboardNav, 'addGradebookElement');
      render();
      component.props.addGradebookElement();
      strictEqual(gradebook.keyboardNav.addGradebookElement.callCount, 1);
    });

    test('sets the component as disabled when students are not loaded', function () {
      gradebook.setStudentsLoaded(false);
      render();
      strictEqual(component.props.disabled, true);
    });

    test('sets the component as not disabled when students are loaded', function () {
      gradebook.setStudentsLoaded(true);
      render();
      strictEqual(component.props.disabled, false);
    });

    test('includes the login handle name from Gradebook', function () {
      render();
      equal(component.props.loginHandleName, 'a_jones');
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
      equal(columnId, 'student');
    });

    test('includes a callback for closing the column header menu', function () {
      sinon.stub(gradebook, 'handleColumnHeaderMenuClose');
      render();
      component.props.onMenuDismiss();
      strictEqual(gradebook.handleColumnHeaderMenuClose.callCount, 1);
    });

    test('includes a callback for selecting the primary info', function () {
      sinon.stub(gradebook, 'setSelectedPrimaryInfo');
      render();
      component.props.onSelectPrimaryInfo();
      strictEqual(gradebook.setSelectedPrimaryInfo.callCount, 1);
    });

    test('includes a callback for selecting the secondary info', function () {
      sinon.stub(gradebook, 'setSelectedSecondaryInfo');
      render();
      component.props.onSelectSecondaryInfo();
      strictEqual(gradebook.setSelectedSecondaryInfo.callCount, 1);
    });

    test('includes a callback for toggling the enrollment filter', function () {
      sinon.stub(gradebook, 'toggleEnrollmentFilter');
      render();
      component.props.onToggleEnrollmentFilter();
      strictEqual(gradebook.toggleEnrollmentFilter.callCount, 1);
    });

    test('includes a callback for removing elements to the Gradebook KeyboardNav', function () {
      sinon.stub(gradebook.keyboardNav, 'removeGradebookElement');
      render();
      component.props.removeGradebookElement();
      strictEqual(gradebook.keyboardNav.removeGradebookElement.callCount, 1);
    });

    test('sets sectionsEnabled to true when sections are in use', function () {
      gradebook.gotSections([{ id: '2001', name: 'Freshmen' }, { id: '2002', name: 'Sophomores' }]);
      render();
      strictEqual(component.props.sectionsEnabled, true);
    });

    test('sets sectionsEnabled to false when sections are not in use', function () {
      render();
      strictEqual(component.props.sectionsEnabled, false);
    });

    test('includes the selected enrollment filters', function () {
      gradebook.toggleEnrollmentFilter('concluded');
      render();
      deepEqual(component.props.selectedEnrollmentFilters, ['concluded']);
    });

    test('includes the selected primary info setting', function () {
      render();
      equal(component.props.selectedPrimaryInfo, 'first_last');
    });

    test('includes the selected secondary info setting', function () {
      render();
      equal(component.props.selectedSecondaryInfo, 'none');
    });

    test('includes the SIS name', function () {
      render();
      equal(component.props.sisName, 'Example SIS');
    });

    test('includes the "Sort by" direction setting', function () {
      render();
      equal(component.props.sortBySetting.direction, 'ascending');
    });

    test('sets the "Sort by" disabled setting to true when students are not loaded', function () {
      gradebook.setStudentsLoaded(false);
      render();
      strictEqual(component.props.sortBySetting.disabled, true);
    });

    test('sets the "Sort by" disabled setting to false when students are loaded', function () {
      gradebook.setStudentsLoaded(true);
      render();
      strictEqual(component.props.sortBySetting.disabled, false);
    });

    test('sets the "Sort by" isSortColumn setting to true when sorting by the student column', function () {
      render();
      strictEqual(component.props.sortBySetting.isSortColumn, true);
    });

    test('sets the "Sort by" isSortColumn setting to false when not sorting by the student column', function () {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending');
      render();
      strictEqual(component.props.sortBySetting.isSortColumn, false);
    });

    test('includes the onSortBySortableNameAscending callback', function () {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending');
      render();
      component.props.sortBySetting.onSortBySortableNameAscending();
      const expectedSetting = { columnId: 'student', direction: 'ascending', settingKey: 'sortable_name' };
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting);
    });

    test('includes the onSortBySortableNameDescending callback', function () {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending');
      render();
      component.props.sortBySetting.onSortBySortableNameDescending();
      const expectedSetting = { columnId: 'student', direction: 'descending', settingKey: 'sortable_name' };
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting);
    });

    test('includes the "Sort by" settingKey', function () {
      render();
      equal(component.props.sortBySetting.settingKey, 'sortable_name');
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
