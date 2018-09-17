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

import React from 'react';
import { mount } from 'enzyme';
import AssignmentColumnHeader from 'jsx/gradezilla/default_gradebook/GradebookGrid/headers/AssignmentColumnHeader'
import CurveGradesDialogManager from 'jsx/gradezilla/default_gradebook/CurveGradesDialogManager';
import AssignmentMuterDialogManager from 'jsx/gradezilla/shared/AssignmentMuterDialogManager';
import SetDefaultGradeDialogManager from 'jsx/gradezilla/shared/SetDefaultGradeDialogManager';
import {getMenuItem} from './columnHeaderHelpers'

function createAssignmentProp ({ assignment } = {}) {
  return {
    anonymizeStudents: false,
    courseId: '42',
    htmlUrl: 'http://assignment_htmlUrl',
    id: '1',
    invalid: false,
    muted: false,
    name: 'Assignment #1',
    omitFromFinalGrade: false,
    pointsPossible: 13,
    published: true,
    submissionTypes: ['online_text_entry'],
    ...assignment
  };
}

function createStudentsProp () {
  return [
    {
      id: '11',
      name: 'Clark Kent',
      isInactive: false,
      submission: {
        excused: false,
        score: 7,
        submittedAt: null
      }
    },
    {
      id: '13',
      name: 'Barry Allen',
      isInactive: false,
      submission: {
        excused: false,
        score: 8,
        submittedAt: new Date('Thu Feb 02 2017 16:33:19 GMT-0500 (EST)')
      }
    },
    {
      id: '15',
      name: 'Bruce Wayne',
      isInactive: false,
      submission: {
        excused: false,
        score: undefined,
        submittedAt: undefined
      }
    }
  ];
}

function defaultProps ({ props, sortBySetting, assignment, curveGradesAction } = {}) {
  return {
    assignment: createAssignmentProp({ assignment }),
    assignmentDetailsAction: {
      disabled: false,
      onSelect () {},
    },
    curveGradesAction: {
      isDisabled: false,
      onSelect () {},
      ...curveGradesAction
    },
    downloadSubmissionsAction: {
      hidden: false,
      onSelect () {}
    },
    enterGradesAsSetting: {
      hidden: false,
      onSelect () {},
      selected: 'points',
      showGradingSchemeOption: true
    },
    muteAssignmentAction: {
      disabled: false,
      onSelect () {}
    },
    reuploadSubmissionsAction: {
      hidden: false,
      onSelect () {}
    },
    setDefaultGradeAction: {
      disabled: false,
      onSelect () {}
    },
    showUnpostedMenuItem: true,
    sortBySetting: {
      direction: 'ascending',
      disabled: false,
      isSortColumn: true,
      onSortByGradeAscending: sinon.stub(),
      onSortByGradeDescending: sinon.stub(),
      onSortByLate: sinon.stub(),
      onSortByMissing: sinon.stub(),
      onSortByUnposted: sinon.stub(),
      settingKey: 'grade',
      ...sortBySetting
    },
    students: createStudentsProp(),
    submissionsLoaded: true,
    addGradebookElement () {},
    removeGradebookElement () {},
    onMenuDismiss () {},
    ...props
  };
}

function mountComponent (props, mountOptions = {}) {
  return mount(<AssignmentColumnHeader {...props} />, mountOptions);
}

function mountAndOpenOptions (props, mountOptions = {}) {
  const wrapper = mountComponent(props, mountOptions);
  wrapper.find('.Gradebook__ColumnHeaderAction button').simulate('click');
  return wrapper;
}

function getOptionsMenuItem(wrapper, ...path) {
  return getMenuItem(wrapper.instance().optionsMenuContent, ...path)
}

QUnit.module('AssignmentColumnHeader', {
  setup () {
    this.props = defaultProps({
      props: {
        addGradebookElement: sinon.stub(),
        removeGradebookElement: sinon.stub(),
        onMenuDismiss: sinon.stub()
      }
    });
    this.wrapper = mountComponent(this.props);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('renders the assignment name in a link', function () {
  const link = this.wrapper.find('.assignment-name Link');

  equal(link.length, 1);
  equal(link.text().trim(), 'Assignment #1');
  equal(link.props().href, 'http://assignment_htmlUrl');
});

test('renders the points possible', function () {
  const pointsPossible = this.wrapper.find('.assignment-points-possible');

  equal(pointsPossible.length, 1);
  equal(pointsPossible.text().trim(), 'Out of 13');
});

test('renders a Menu', function () {
  const optionsMenu = this.wrapper.find('Menu');

  equal(optionsMenu.length, 1);
});

test('does not render a Menu if assignment is not published', function () {
  const props = defaultProps({ assignment: { published: false } });
  const wrapper = mountComponent(props);
  const optionsMenu = wrapper.find('Menu');
  equal(optionsMenu.length, 0);
});

test('renders a Menu with a trigger', function () {
  const optionsMenuTrigger = this.wrapper.find('.Gradebook__ColumnHeaderAction button');

  equal(optionsMenuTrigger.length, 1);
});

test('calls addGradebookElement prop on open', function () {
  notOk(this.props.addGradebookElement.called);

  this.wrapper.find('.Gradebook__ColumnHeaderAction button').simulate('click');

  ok(this.props.addGradebookElement.called);
});

test('calls removeGradebookElement prop on close', function () {
  notOk(this.props.removeGradebookElement.called);

  this.wrapper.find('.Gradebook__ColumnHeaderAction button').simulate('click');
  this.wrapper.find('.Gradebook__ColumnHeaderAction button').simulate('click');

  ok(this.props.removeGradebookElement.called);
});

test('calls onMenuDismiss prop on close', function () {
  this.wrapper.find('.Gradebook__ColumnHeaderAction button').simulate('click');
  this.wrapper.find('.Gradebook__ColumnHeaderAction button').simulate('click');

  strictEqual(this.props.onMenuDismiss.callCount, 1);
});

test('adds a class to the action container when the Menu is opened', function () {
  const actionContainer = this.wrapper.find('.Gradebook__ColumnHeaderAction');
  actionContainer.find('button').simulate('click');
  const {classList} = actionContainer.getDOMNode()
  ok(classList.contains('menuShown'));
});

test('renders a title for the More icon based on the assignment name', function () {
  const optionsMenuTrigger = this.wrapper.find('Button ScreenReaderContent');
  equal(optionsMenuTrigger.text(), 'Assignment #1 Options');
});

QUnit.module('AssignmentColumnHeader: "Enter Grades as" Settings', function (hooks) {
  let props;
  let wrapper;

  function mountAndOpenMenu () {
    wrapper = mountAndOpenOptions(props);
  }

  function getEnterGradesAsOption(label) {
    return getOptionsMenuItem(wrapper, 'Enter Grades as', label)
  }

  hooks.beforeEach(function () {
    props = defaultProps();
  });

  hooks.afterEach(function () {
    wrapper.unmount();
  });

  test('renders when "hidden" is false', function () {
    wrapper = mountAndOpenOptions(props);
    ok(getMenuItem(wrapper.instance().optionsMenuContent, 'Enter Grades as'))
  });

  test('does not render when "hidden" is true', function () {
    props.enterGradesAsSetting.hidden = true;
    wrapper = mountAndOpenOptions(props);
    notOk(getMenuItem(wrapper.instance().optionsMenuContent, 'Enter Grades as'))
  });

  test('includes the "Points" option', function () {
    mountAndOpenMenu();
    ok(getEnterGradesAsOption('Points'))
  });

  test('includes the "Percentage" option', function () {
    mountAndOpenMenu();
    ok(getEnterGradesAsOption('Percentage'))
  });

  test('includes the "Grading Scheme" option when "showGradingSchemeOption" is true', function () {
    props.enterGradesAsSetting.showGradingSchemeOption = true;
    mountAndOpenMenu();
    ok(getEnterGradesAsOption('Grading Scheme'))
  });

  test('excludes the "Grading Scheme" option when "showGradingSchemeOption" is false', function () {
    props.enterGradesAsSetting.showGradingSchemeOption = false;
    mountAndOpenMenu();
    notOk(getEnterGradesAsOption('Grading Scheme'))
  });

  test('optionally renders the "Points" option as selected', function () {
    props.enterGradesAsSetting.selected = 'points';
    mountAndOpenMenu();
    strictEqual(getEnterGradesAsOption('Points').getAttribute('aria-checked'), 'true');
  });

  test('optionally renders the "Percentage" option as selected', function () {
    props.enterGradesAsSetting.selected = 'percent';
    mountAndOpenMenu();
    strictEqual(getEnterGradesAsOption('Percentage').getAttribute('aria-checked'), 'true');
  });

  test('optionally renders the "Grading Scheme" option as selected', function () {
    props.enterGradesAsSetting.showGradingSchemeOption = true;
    props.enterGradesAsSetting.selected = 'gradingScheme';
    mountAndOpenMenu();
    strictEqual(getEnterGradesAsOption('Grading Scheme').getAttribute('aria-checked'), 'true');
  });

  test('calls the onSelect callback with "points" when "Points" is selected', function () {
    let selected;
    props.enterGradesAsSetting.selected = 'percent';
    props.enterGradesAsSetting.onSelect = (value) => { selected = value };
    mountAndOpenMenu();
    getEnterGradesAsOption('Points').click();
    equal(selected, 'points');
  });

  test('calls the onSelect callback with "percent" when "Percentage" is selected', function () {
    let selected;
    props.enterGradesAsSetting.onSelect = (value) => { selected = value };
    mountAndOpenMenu();
    getEnterGradesAsOption('Percentage').click();
    equal(selected, 'percent');
  });

  test('calls the onSelect callback with "gradingScheme" when "Grading Scheme" is selected', function () {
    let selected;
    props.enterGradesAsSetting.showGradingSchemeOption = true;
    props.enterGradesAsSetting.onSelect = (value) => { selected = value };
    mountAndOpenMenu();
    getEnterGradesAsOption('Grading Scheme').click();
    equal(selected, 'gradingScheme');
  });
});

QUnit.module('AssignmentColumnHeader: Sort by Settings', {
  teardown () {
    this.wrapper.unmount();
  }
});

test('selects "Grade - Low to High" when sorting by grade ascending', function () {
  const props = defaultProps({ sortBySetting: { direction: 'ascending' } });
  this.wrapper = mountAndOpenOptions(props);
  const $menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Grade - Low to High');
  strictEqual($menuItem.getAttribute('aria-checked'), 'true');
});

test('does not select "Grade - Low to High" when isSortColumn is false', function () {
  const props = defaultProps({ sortBySetting: { isSortColumn: false } });
  this.wrapper = mountAndOpenOptions(props);
  const $menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Grade - Low to High');
  strictEqual($menuItem.getAttribute('aria-checked'), 'false');
});

test('clicking "Grade - Low to High" calls onSortByGradeAscending', function () {
  const onSortByGradeAscending = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortByGradeAscending } });
  this.wrapper = mountAndOpenOptions(props)
  getOptionsMenuItem(this.wrapper, 'Sort by', 'Grade - Low to High').click();
  strictEqual(onSortByGradeAscending.callCount, 1);
});

test('clicking "Grade - Low to High" focuses menu trigger', function () {
  const onSortByGradeAscending = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortByGradeAscending } });
  this.wrapper = mountAndOpenOptions(props)
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Grade - Low to High');
  const focusStub = sandbox.stub(this.wrapper.instance(), 'focusAtEnd')

  menuItem.click();

  equal(focusStub.callCount, 1);
});

test('"Grade - Low to High" is optionally disabled', function () {
  const props = defaultProps({ sortBySetting: { disabled: true } });
  this.wrapper = mountAndOpenOptions(props)
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Grade - Low to High');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('selects "Grade - High to Low" when sorting by grade descending', function () {
  const props = defaultProps({ sortBySetting: { direction: 'descending' } });
  this.wrapper = mountAndOpenOptions(props)
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Grade - High to Low');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('does not select "Grade - High to Low" when isSortColumn is false', function () {
  const props = defaultProps({ sortBySetting: { isSortColumn: false } });
  this.wrapper = mountAndOpenOptions(props)
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Grade - High to Low');
  strictEqual(menuItem.getAttribute('aria-checked'), 'false');
});

test('clicking "Grade - High to Low" calls onSortByGradeDescending', function () {
  const onSortByGradeDescending = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortByGradeDescending } });
  this.wrapper = mountAndOpenOptions(props)
  getOptionsMenuItem(this.wrapper, 'Sort by', 'Grade - High to Low').click();
  strictEqual(onSortByGradeDescending.callCount, 1);
});

test('clicking "Grade - High to Low" focuses menu trigger', function () {
  const onSortByGradeDescending = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortByGradeDescending } });
  this.wrapper = mountAndOpenOptions(props)
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Grade - High to Low');
  const focusStub = sandbox.stub(this.wrapper.instance(), 'focusAtEnd')

  menuItem.click();

  equal(focusStub.callCount, 1);
});

test('"Grade - High to Low" is optionally disabled', function () {
  const props = defaultProps({ sortBySetting: { disabled: true } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Grade - High to Low');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('selects "Missing" when sorting by missing', function () {
  const props = defaultProps({ sortBySetting: { settingKey: 'missing' } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Missing');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('does not select "Missing" when isSortColumn is false', function () {
  const props = defaultProps({ sortBySetting: { settingKey: 'missing', isSortColumn: false } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Grade - High to Low');
  strictEqual(menuItem.getAttribute('aria-checked'), 'false');
});

test('clicking "Missing" calls onSortByMissing', function () {
  const onSortByMissing = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortByMissing } });
  this.wrapper = mountAndOpenOptions(props);
  getOptionsMenuItem(this.wrapper, 'Sort by', 'Missing').click();
  strictEqual(onSortByMissing.callCount, 1);
});

test('clicking "Missing" focuses menu trigger', function () {
  const onSortByMissing = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortByMissing } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Missing');
  const focusStub = sandbox.stub(this.wrapper.instance(), 'focusAtEnd')

  menuItem.click();

  equal(focusStub.callCount, 1);
});

test('"Missing" is optionally disabled', function () {
  const props = defaultProps({ sortBySetting: { disabled: true } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Missing');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('selects "Late" when sorting by late', function () {
  const props = defaultProps({ sortBySetting: { settingKey: 'late' } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Late');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('does not select "Late" when isSortColumn is false', function () {
  const props = defaultProps({ sortBySetting: { settingKey: 'late', isSortColumn: false } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Grade - High to Low');
  strictEqual(menuItem.getAttribute('aria-checked'), 'false');
});

test('clicking "Late" calls onSortByLate', function () {
  const onSortByLate = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortByLate } });
  this.wrapper = mountAndOpenOptions(props);
  getOptionsMenuItem(this.wrapper, 'Sort by', 'Late').click();
  strictEqual(onSortByLate.callCount, 1);
});

test('clicking "Late" focuses menu trigger', function () {
  const onSortByLate = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortByLate } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Late');
  const focusStub = sandbox.stub(this.wrapper.instance(), 'focusAtEnd')

  menuItem.click();

  equal(focusStub.callCount, 1);
});

test('"Late" is optionally disabled', function () {
  const props = defaultProps({ sortBySetting: { disabled: true } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Late');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('selects "Unposted" when sorting by unposted', function () {
  const props = defaultProps({ sortBySetting: { settingKey: 'unposted' } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Unposted');
  strictEqual(menuItem.getAttribute('aria-checked'), 'true');
});

test('does not select "Unposted" when isSortColumn is false', function () {
  const props = defaultProps({ sortBySetting: { settingKey: 'unposted', isSortColumn: false } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Grade - High to Low');
  strictEqual(menuItem.getAttribute('aria-checked'), 'false');
});

test('clicking "Unposted" calls onSortByUnposted', function () {
  const onSortByUnposted = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortByUnposted } });
  this.wrapper = mountAndOpenOptions(props);
  getOptionsMenuItem(this.wrapper, 'Sort by', 'Unposted').click();
  strictEqual(onSortByUnposted.callCount, 1);
});

test('clicking "Unposted" focuses menu trigger', function () {
  const onSortByUnposted = sinon.stub();
  const props = defaultProps({ sortBySetting: { onSortByUnposted } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Unposted');
  const focusStub = sandbox.stub(this.wrapper.instance(), 'focusAtEnd')

  menuItem.click();

  equal(focusStub.callCount, 1);
});

test('"Unposted" is optionally disabled', function () {
  const props = defaultProps({ sortBySetting: { disabled: true } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Unposted');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('"Unposted" menu item is optionally excluded from the menu', function () {
  const props = defaultProps({ props: { showUnpostedMenuItem: false } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Sort by', 'Unposted');
  notOk(menuItem);
});

QUnit.module('AssignmentColumnHeader: Curve Grades', {
  teardown () {
    this.wrapper.unmount();
  }
});

test('"Curve Grades" menu item is present in the options menu', function () {
  this.wrapper = mountAndOpenOptions(defaultProps());
  ok(getOptionsMenuItem(this.wrapper, 'Curve Grades'));
});

test('menu item is disabled when .curveGradesAction.isDisabled is true', function () {
  const props = defaultProps({ curveGradesAction: { isDisabled: true } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Curve Grades');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('menu item is not disabled when .curveGradesAction.isDisabled is false', function () {
  this.wrapper = mountAndOpenOptions(defaultProps());
  const menuItem = getOptionsMenuItem(this.wrapper, 'Curve Grades');
  strictEqual(menuItem.getAttribute('aria-disabled'), null);
});

test('clicking the menu item invokes onSelect with correct callback', function () {
  const onSelect = sinon.stub();
  const props = defaultProps({ curveGradesAction: { onSelect } });
  this.wrapper = mountAndOpenOptions(props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Curve Grades');

  menuItem.click();

  equal(onSelect.callCount, 1);
  equal(onSelect.getCall(0).args[0], this.wrapper.instance().focusAtEnd);
});

test('the Curve Grades dialog has focus when it is invoked', function () {
  const props = defaultProps();
  const curveGradesActionOptions = {
    isAdmin: true,
    contextUrl: 'http://contextUrl',
    submissionsLoaded: true
  };
  const curveGradesProps = CurveGradesDialogManager.createCurveGradesAction(
    props.assignment, props.students, curveGradesActionOptions
  );

  props.curveGradesAction.onSelect = curveGradesProps.onSelect;
  this.wrapper = mountAndOpenOptions(props, { attachTo: document.querySelector('#fixtures') });

  const menuItem = getOptionsMenuItem(this.wrapper, 'Curve Grades');
  menuItem.click();

  const allDialogCloseButtons = document.querySelectorAll('.ui-dialog-titlebar-close.ui-state-focus');
  const dialogCloseButton = allDialogCloseButtons[allDialogCloseButtons.length - 1];

  equal(document.activeElement, dialogCloseButton);

  dialogCloseButton.click();
});

QUnit.module('AssignmentColumnHeader: Message Students Who', {
  setup () {
    this.props = defaultProps();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('"Message Students Who" menu item in present in the options menu', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  ok(getOptionsMenuItem(this.wrapper, 'Message Students Who'));
});

test('menu item is disabled when submissions are not loaded', function () {
  this.props.submissionsLoaded = false;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Message Students Who');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('menu item is not disabled when submissions are loaded', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Message Students Who');
  strictEqual(menuItem.getAttribute('aria-disabled'), null);
});

test('clicking the menu item invokes the Message Students Who dialog with correct callback', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const messageStudents = sandbox.stub(window, 'messageStudents');
  const menuItem = getOptionsMenuItem(this.wrapper, 'Message Students Who');

  menuItem.click();

  equal(messageStudents.callCount, 1);
  equal(messageStudents.getCall(0).args[0].onClose, this.wrapper.instance().focusAtEnd);
});

QUnit.module('AssignmentColumnHeader: Mute/Unmute Assignment', {
  setup () {
    this.props = defaultProps();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('"Mute Assignment" menu item is present when the assignment is not muted', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  ok(getOptionsMenuItem(this.wrapper, 'Mute Assignment'));
});

test('"Mute Assignment" menu item is disabled when .muteAssignmentAction.disabled is true', function () {
  this.props.muteAssignmentAction.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Mute Assignment');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('"Mute Assignment" menu item is not disabled when .muteAssignmentAction.disabled is false', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Mute Assignment');
  strictEqual(menuItem.getAttribute('aria-disabled'), null);
});

test('"Unmute Assignment" menu item is present when the assignment is muted', function () {
  this.props.assignment.muted = true
  this.wrapper = mountAndOpenOptions(this.props);
  ok(getOptionsMenuItem(this.wrapper, 'Unmute Assignment'));
});

test('"Unmute Assignment" menu item is disabled when .muteAssignmentAction.disabled is true', function () {
  this.props.assignment.muted = true
  this.props.muteAssignmentAction.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Unmute Assignment');
  strictEqual(menuItem.getAttribute('aria-disabled'), 'true');
});

test('"Unmute Assignment" menu item is not disabled when .muteAssignmentAction.disabled is false', function () {
  this.props.assignment.muted = true
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = getOptionsMenuItem(this.wrapper, 'Unmute Assignment');
  strictEqual(menuItem.getAttribute('aria-disabled'), null);
});

test('clicking the menu item invokes onSelect with correct callback', function () {
  this.props.muteAssignmentAction.onSelect = sinon.stub();
  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="assignment-muter"]');
  menuItem.click();

  equal(this.props.muteAssignmentAction.onSelect.callCount, 1);
  equal(this.props.muteAssignmentAction.onSelect.getCall(0).args[0], this.wrapper.instance().focusAtEnd);
});

test('the Assignment Muting dialog has focus when it is invoked', function () {
  const dialogManager = new AssignmentMuterDialogManager(this.props.assignment, 'http://url', true);

  this.props.muteAssignmentAction.onSelect = dialogManager.showDialog;
  this.wrapper = mountAndOpenOptions(this.props, { attachTo: document.querySelector('#fixtures') });

  const menuItem = document.querySelector('[data-menu-item-id="assignment-muter"]');
  menuItem.click();

  const allDialogCloseButtons = document.querySelectorAll('.ui-dialog-titlebar-close.ui-state-focus');
  const dialogCloseButton = allDialogCloseButtons[allDialogCloseButtons.length - 1];

  equal(document.activeElement, dialogCloseButton);

  dialogCloseButton.click();
});

QUnit.module('AssignmentColumnHeader: non-standard assignment', function (hooks) {
  let props;
  let wrapper;

  hooks.beforeEach(function () {
    props = defaultProps();
  });

  hooks.afterEach(function () {
    wrapper.unmount();
  });

  test('renders a muted status when the assignment is muted', function () {
    props.assignment.muted = true;
    wrapper = mountComponent(props);
    const secondaryDetail = wrapper.find('.Gradebook__ColumnHeaderDetail--secondary');
    ok(secondaryDetail.text().includes('Muted'));
  });

  test('renders an unpublished status when the assignment is unpublished', function () {
    props.assignment.published = false;
    wrapper = mountComponent(props);
    const secondaryDetail = wrapper.find('.Gradebook__ColumnHeaderDetail--secondary');
    strictEqual(secondaryDetail.text(), 'Unpublished');
  });

  test('renders an unpublished status when the assignment is unpublished and muted', function () {
    props.assignment.muted = true;
    props.assignment.published = false;
    wrapper = mountComponent(props);
    const secondaryDetail = wrapper.find('.Gradebook__ColumnHeaderDetail--secondary');
    strictEqual(secondaryDetail.text(), 'Unpublished');
  });

  test('renders an unpublished status when the assignment is unpublished and anonymously graded', function () {
    props.assignment.published = false;
    props.assignment.anonymizeStudents = true;
    wrapper = mountComponent(props);
    const secondaryDetail = wrapper.find('.Gradebook__ColumnHeaderDetail--secondary');
    strictEqual(secondaryDetail.text(), 'Unpublished');
  });

  test('renders an anonymous status when the assignment is anonymously graded', function() {
    props.assignment.anonymizeStudents = true;
    wrapper = mountComponent(props);
    const secondaryDetail = wrapper.find('.Gradebook__ColumnHeaderDetail--secondary');
    strictEqual(secondaryDetail.text(), 'Anonymous');
  });

  test('does not render points possible when the assignment is unpublished', function () {
    props.assignment.published = false;
    wrapper = mountComponent(props);
    const pointsPossible = wrapper.find('.assignment-points-possible');
    strictEqual(pointsPossible.length, 0);
  });

  test('renders 0 points possible when the assignment has no possible points', function () {
    props.assignment.pointsPossible = undefined;
    wrapper = mountComponent(props);
    const pointsPossible = wrapper.find('.assignment-points-possible');

    equal(pointsPossible.length, 1);
    equal(pointsPossible.text().trim(), 'Out of 0');
  });
});

QUnit.module('AssignmentColumnHeader: Set Default Grade Action', {
  setup () {
    this.props = defaultProps();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('shows the menu item in an enabled state', function () {
  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="set-default-grade"]');

  equal(menuItem.textContent, 'Set Default Grade');
  strictEqual(menuItem.parentElement.parentElement.parentElement.getAttribute('aria-disabled'), null);
});

test('disables the menu item when the disabled prop is true', function () {
  this.props.setDefaultGradeAction.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="set-default-grade"]');

  equal(menuItem.parentElement.parentElement.parentElement.getAttribute('aria-disabled'), 'true');
});

test('clicking the menu item invokes onSelect with correct callback', function () {
  this.props.setDefaultGradeAction.onSelect = sinon.stub();
  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="set-default-grade"]');
  menuItem.click();

  equal(this.props.setDefaultGradeAction.onSelect.callCount, 1);
  equal(this.props.setDefaultGradeAction.onSelect.getCall(0).args[0], this.wrapper.instance().focusAtEnd);
});

test('the Set Default Grade dialog has focus when it is invoked', function () {
  const dialogManager =
    new SetDefaultGradeDialogManager(this.props.assignment, this.props.students, 1, '1', true, true);

  this.props.setDefaultGradeAction.onSelect = dialogManager.showDialog;
  this.wrapper = mountAndOpenOptions(this.props, { attachTo: document.querySelector('#fixtures') });

  const menuItem = document.querySelector('[data-menu-item-id="set-default-grade"]');
  menuItem.click();

  const allDialogCloseButtons = document.querySelectorAll('.ui-dialog-titlebar-close.ui-state-focus');
  const dialogCloseButton = allDialogCloseButtons[allDialogCloseButtons.length - 1];

  equal(document.activeElement, dialogCloseButton);

  dialogCloseButton.click();
});

QUnit.module('AssignmentColumnHeader: Download Submissions Action', {
  setup () {
    this.props = defaultProps();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('shows the menu item in an enabled state', function () {
  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="download-submissions"]');

  equal(menuItem.textContent, 'Download Submissions');
  notOk(menuItem.parentElement.parentElement.parentElement.getAttribute('aria-disabled'));
});

test('does not render the menu item when the hidden prop is true', function () {
  this.props.downloadSubmissionsAction.hidden = true;
  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="download-submissions"]');

  equal(menuItem, null);
});

test('clicking the menu item invokes onSelect with correct callback', function () {
  this.props.downloadSubmissionsAction.onSelect = sinon.stub();
  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="download-submissions"]');
  menuItem.click();

  equal(this.props.downloadSubmissionsAction.onSelect.callCount, 1);
  equal(this.props.downloadSubmissionsAction.onSelect.getCall(0).args[0], this.wrapper.instance().focusAtEnd);
});

QUnit.module('AssignmentColumnHeader: Reupload Submissions Action', {
  setup () {
    this.props = defaultProps();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('shows the menu item in an enabled state', function () {
  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="reupload-submissions"]');

  equal(menuItem.textContent, 'Re-Upload Submissions');
  strictEqual(menuItem.parentElement.getAttribute('aria-disabled'), null);
});

test('does not render the menu item when the hidden prop is true', function () {
  this.props.reuploadSubmissionsAction.hidden = true;
  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="reupload-submissions"]');

  equal(menuItem, null);
});

test('clicking the menu item invokes the onSelect property with correct callback', function () {
  this.props.reuploadSubmissionsAction.onSelect = sinon.stub();
  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="reupload-submissions"]');
  menuItem.click();

  equal(this.props.reuploadSubmissionsAction.onSelect.callCount, 1);
  equal(this.props.reuploadSubmissionsAction.onSelect.getCall(0).args[0], this.wrapper.instance().focusAtEnd);
});

QUnit.module('AssignmentColumnHeader#handleKeyDown', function (hooks) {
  hooks.beforeEach(function () {
    this.wrapper = mountComponent(defaultProps(), { attachTo: document.querySelector('#fixtures') });
    this.preventDefault = sinon.spy();
  });

  hooks.afterEach(function () {
    this.wrapper.unmount();
  });

  this.handleKeyDown = function (which, shiftKey = false) {
    return this.wrapper.instance().handleKeyDown({ which, shiftKey, preventDefault: this.preventDefault });
  };

  QUnit.module('with focus on assignment link', {
    setup () {
      this.wrapper.instance().assignmentLink.focus();
    }
  });

  test('Tab sets focus on options menu trigger', function () {
    this.handleKeyDown(9, false); // Tab
    equal(document.activeElement, this.wrapper.instance().optionsMenuTrigger);
  });

  test('prevents default behavior for Tab', function () {
    this.handleKeyDown(9, false); // Tab
    strictEqual(this.preventDefault.callCount, 1);
  });

  test('returns false for Tab', function () {
    // This prevents additional behavior in Grid Support Navigation.
    const returnValue = this.handleKeyDown(9, false); // Tab
    strictEqual(returnValue, false);
  });

  test('does not handle Shift+Tab', function () {
    // This allows Grid Support Navigation to handle navigation.
    const returnValue = this.handleKeyDown(9, true); // Shift+Tab
    equal(typeof returnValue, 'undefined');
  });

  QUnit.module('with focus on options menu trigger', {
    setup () {
      this.wrapper.instance().optionsMenuTrigger.focus();
    }
  });

  test('Shift+Tab sets focus on assignment link', function () {
    this.handleKeyDown(9, true); // Shift+Tab
    strictEqual(this.wrapper.instance().assignmentLink.focused, true);
  });

  test('prevents default behavior for Shift+Tab', function () {
    this.handleKeyDown(9, true); // Shift+Tab
    strictEqual(this.preventDefault.callCount, 1);
  });

  test('returns false for Shift+Tab', function () {
    // This prevents additional behavior in Grid Support Navigation.
    const returnValue = this.handleKeyDown(9, true); // Shift+Tab
    strictEqual(returnValue, false);
  });

  test('does not handle Tab', function () {
    // This allows Grid Support Navigation to handle navigation.
    const returnValue = this.handleKeyDown(9, false); // Tab
    equal(typeof returnValue, 'undefined');
  });

  test('Enter opens the options menu', function () {
    this.handleKeyDown(13); // Enter
    const optionsMenu = this.wrapper.find('Menu');
    strictEqual(optionsMenu.instance().shown, true);
  });

  test('returns false for Enter on options menu', function () {
    // This prevents additional behavior in Grid Support Navigation.
    const returnValue = this.handleKeyDown(13); // Enter
    strictEqual(returnValue, false);
  });

  QUnit.module('without focus');

  test('does not handle Tab', function () {
    const returnValue = this.handleKeyDown(9, false); // Tab
    equal(typeof returnValue, 'undefined');
  });

  test('does not handle Shift+Tab', function () {
    const returnValue = this.handleKeyDown(9, true); // Shift+Tab
    equal(typeof returnValue, 'undefined');
  });

  test('does not handle Enter', function () {
    const returnValue = this.handleKeyDown(13); // Enter
    equal(typeof returnValue, 'undefined');
  });
});

QUnit.module('AssignmentColumnHeader: focus', {
  setup () {
    this.wrapper = mountComponent(defaultProps(), { attachTo: document.querySelector('#fixtures') });
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('#focusAtStart sets focus on the assignment link', function () {
  this.wrapper.instance().focusAtStart();
  strictEqual(this.wrapper.instance().assignmentLink.focused, true);
});

test('#focusAtEnd sets focus on the options menu trigger', function () {
  this.wrapper.instance().focusAtEnd();
  equal(document.activeElement, this.wrapper.instance().optionsMenuTrigger);
});

test('applies the "focused" class when the assignment title has focus', function(assert) {
  const done = assert.async();
  this.wrapper.setState({ hasFocus: true }, () => {
    const {classList} = this.wrapper.getDOMNode();
    ok(classList.contains('focused'));
    done();
  });
})

test('removes the "focused" class when the header blurs', function(assert) {
  const done = assert.async()
  this.wrapper.setState({ hasFocus: true }, () => {
    this.wrapper.setState({ hasFocus: false }, () => {
      const {classList} = this.wrapper.getDOMNode();
      notOk(classList.contains('focused'));
      done();
    });
  });
})
