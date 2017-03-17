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

import React from 'react'
import { mount, ReactWrapper } from 'enzyme'
import AssignmentColumnHeader from 'jsx/gradezilla/default_gradebook/components/AssignmentColumnHeader'

function createAssignmentProp () {
  return {
    courseId: '42',
    htmlUrl: 'http://assignment_htmlUrl',
    id: '1',
    invalid: false,
    muted: false,
    name: 'Assignment #1',
    omitFromFinalGrade: false,
    pointsPossible: 13,
    submissionTypes: ['online_text_entry']
  };
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

function createExampleProps () {
  return {
    assignment: createAssignmentProp(),
    assignmentDetailsAction: {
      disabled: false,
      onSelect () {},
    },
    curveGradesAction: {
      isDisabled: false,
      onSelect () {}
    },
    downloadSubmissionsAction: {
      hidden: false,
      onSelect () {}
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
    sortBySetting: {
      direction: 'ascending',
      disabled: false,
      isSortColumn: true,
      onSortByGradeAscending () {},
      onSortByGradeDescending () {},
      onSortByLate () {},
      onSortByMissing () {},
      onSortByUnposted () {},
      settingKey: 'grade'
    },
    students: createStudentsProp(),
    submissionsLoaded: true
  };
}

function mountComponent (props) {
  return mount(<AssignmentColumnHeader {...props} />);
}

function mountAndOpenOptions (props) {
  const wrapper = mountComponent(props);
  wrapper.find('.Gradebook__ColumnHeaderAction').simulate('click');
  return wrapper;
}

QUnit.module('AssignmentColumnHeader - base behavior', {
  setup () {
    const props = createExampleProps();
    this.wrapper = mountComponent(props);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('renders the assignment name in a link', function () {
  const link = this.wrapper.find('.assignment-name Link');

  equal(link.length, 1);
  equal(link.text(), 'Assignment #1');
  equal(link.props().href, 'http://assignment_htmlUrl');
});

test('renders the points possible', function () {
  const pointsPossible = this.wrapper.find('.assignment-points-possible');

  equal(pointsPossible.length, 1);
  equal(pointsPossible.text(), 'Out of 13');
});

test('renders a PopoverMenu', function () {
  const optionsMenu = this.wrapper.find('PopoverMenu');

  equal(optionsMenu.length, 1);
});

test('renders an IconMoreSolid inside the PopoverMenu', function () {
  const optionsMenuTrigger = this.wrapper.find('PopoverMenu IconMoreSolid');

  equal(optionsMenuTrigger.length, 1);
});

test('renders a title for the More icon based on the assignment name', function () {
  const optionsMenuTrigger = this.wrapper.find('PopoverMenu IconMoreSolid');

  equal(optionsMenuTrigger.props().title, 'Assignment #1 Options');
});

QUnit.module('AssignmentColumnHeader - Sort by Settings', {
  setup () {
    this.props = createExampleProps();
  },

  getMenuItem (index) {
    const menuItemGroup = new ReactWrapper([this.wrapper.node.optionsMenuContent], this.wrapper.node);
    return menuItemGroup.find('MenuItem').at(index);
  },

  getSelectedMenuItem () {
    const menuItemGroup = new ReactWrapper([this.wrapper.node.optionsMenuContent], this.wrapper.node);
    return menuItemGroup.find('MenuItem').findWhere(menuItem => menuItem.prop('selected'));
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('includes the "Sort by" group', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const optionsMenu = new ReactWrapper([this.wrapper.node.optionsMenuContent], this.wrapper.node);
  const menuItemGroup = optionsMenu.find('MenuItemGroup').at(0);
  equal(menuItemGroup.length, 1, '"Sort by" group exists');
  equal(menuItemGroup.prop('label'), 'Sort by');
});

test('includes "Grade - Low to High" sort setting', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(0);
  equal(menuItem.text(), 'Grade - Low to High');
});

test('selects "Grade - Low to High" when sorting by grade ascending', function () {
  this.props.sortBySetting.settingKey = 'grade';
  this.props.sortBySetting.direction = 'ascending';
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getSelectedMenuItem();
  equal(menuItem.length, 1, 'only one menu item is selected');
  equal(menuItem.text(), 'Grade - Low to High', '"Grade - Low to High" is selected');
});

test('does not select "Grade - Low to High" when isSortColumn is false', function () {
  this.props.sortBySetting.settingKey = 'grade';
  this.props.sortBySetting.direction = 'ascending';
  this.props.sortBySetting.isSortColumn = false;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(0);
  equal(menuItem.prop('selected'), false);
});

test('clicking "Grade - Low to High" calls onSortByGradeAscending', function () {
  this.props.sortBySetting.onSortByGradeAscending = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(0).simulate('click');
  equal(this.props.sortBySetting.onSortByGradeAscending.callCount, 1);
});

test('"Grade - Low to High" is optionally disabled', function () {
  this.props.sortBySetting.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(0);
  equal(menuItem.prop('disabled'), true);
});

test('clicking "Grade - Low to High" when disabled does not call onSortByGradeAscending', function () {
  this.props.sortBySetting.disabled = true;
  this.props.sortBySetting.onSortByGradeAscending = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(0).simulate('click');
  equal(this.props.sortBySetting.onSortByGradeAscending.callCount, 0);
});

test('includes "Grade - High to Low" sort setting', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(1);
  equal(menuItem.text(), 'Grade - High to Low');
});

test('selects "Grade - High to Low" when sorting by grade descending', function () {
  this.props.sortBySetting.settingKey = 'grade';
  this.props.sortBySetting.direction = 'descending';
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getSelectedMenuItem();
  equal(menuItem.length, 1, 'only one menu item is selected');
  equal(menuItem.text(), 'Grade - High to Low', '"Grade - High to Low" is selected');
});

test('does not select "Grade - High to Low" when isSortColumn is false', function () {
  this.props.sortBySetting.settingKey = 'grade';
  this.props.sortBySetting.direction = 'descending';
  this.props.sortBySetting.isSortColumn = false;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(1);
  equal(menuItem.prop('selected'), false);
});

test('clicking "Grade - High to Low" calls onSortByGradeDescending', function () {
  this.props.sortBySetting.onSortByGradeDescending = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(1).simulate('click');
  equal(this.props.sortBySetting.onSortByGradeDescending.callCount, 1);
});

test('"Grade - High to Low" is optionally disabled', function () {
  this.props.sortBySetting.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(1);
  equal(menuItem.prop('disabled'), true);
});

test('clicking "Grade - High to Low" when disabled does not call onSortByGradeDescending', function () {
  this.props.sortBySetting.disabled = true;
  this.props.sortBySetting.onSortByGradeDescending = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(1).simulate('click');
  equal(this.props.sortBySetting.onSortByGradeDescending.callCount, 0);
});

test('includes "Missing" sort setting', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(2);
  equal(menuItem.text(), 'Missing');
});

test('selects "Missing" when sorting by missing', function () {
  this.props.sortBySetting.settingKey = 'missing';
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getSelectedMenuItem();
  equal(menuItem.length, 1, 'only one menu item is selected');
  equal(menuItem.text(), 'Missing', '"Missing" is selected');
});

test('does not select "Missing" when isSortColumn is false', function () {
  this.props.sortBySetting.settingKey = 'missing';
  this.props.sortBySetting.isSortColumn = false;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(2);
  equal(menuItem.prop('selected'), false);
});

test('clicking "Missing" calls onSortByMissing', function () {
  this.props.sortBySetting.onSortByMissing = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(2).simulate('click');
  equal(this.props.sortBySetting.onSortByMissing.callCount, 1);
});

test('"Missing" is optionally disabled', function () {
  this.props.sortBySetting.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(2);
  equal(menuItem.prop('disabled'), true);
});

test('clicking "Missing" when disabled does not call onSortByMissing', function () {
  this.props.sortBySetting.disabled = true;
  this.props.sortBySetting.onSortByMissing = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(2).simulate('click');
  equal(this.props.sortBySetting.onSortByMissing.callCount, 0);
});

test('includes "Late" sort setting', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(3);
  equal(menuItem.text(), 'Late');
});

test('selects "Late" when sorting by late', function () {
  this.props.sortBySetting.settingKey = 'late';
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getSelectedMenuItem();
  equal(menuItem.length, 1, 'only one menu item is selected');
  equal(menuItem.text(), 'Late', '"Late" is selected');
});

test('does not select "Late" when isSortColumn is false', function () {
  this.props.sortBySetting.settingKey = 'late';
  this.props.sortBySetting.isSortColumn = false;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(3);
  equal(menuItem.prop('selected'), false);
});

test('clicking "Late" calls onSortByLate', function () {
  this.props.sortBySetting.onSortByLate = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(3).simulate('click');
  equal(this.props.sortBySetting.onSortByLate.callCount, 1);
});

test('"Late" is optionally disabled', function () {
  this.props.sortBySetting.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(3);
  equal(menuItem.prop('disabled'), true);
});

test('clicking "Late" when disabled does not call onSortByLate', function () {
  this.props.sortBySetting.disabled = true;
  this.props.sortBySetting.onSortByLate = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(3).simulate('click');
  equal(this.props.sortBySetting.onSortByLate.callCount, 0);
});

test('includes "Unposted" sort setting', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(4);
  equal(menuItem.text(), 'Unposted');
});

test('selects "Unposted" when sorting by unposted', function () {
  this.props.sortBySetting.settingKey = 'unposted';
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getSelectedMenuItem();
  equal(menuItem.length, 1, 'only one menu item is selected');
  equal(menuItem.text(), 'Unposted', '"Unposted" is selected');
});

test('does not select "Unposted" when isSortColumn is false', function () {
  this.props.sortBySetting.settingKey = 'unposted';
  this.props.sortBySetting.isSortColumn = false;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(4);
  equal(menuItem.prop('selected'), false);
});

test('clicking "Unposted" calls onSortByUnposted', function () {
  this.props.sortBySetting.onSortByUnposted = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(4).simulate('click');
  equal(this.props.sortBySetting.onSortByUnposted.callCount, 1);
});

test('"Unposted" is optionally disabled', function () {
  this.props.sortBySetting.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = this.getMenuItem(4);
  equal(menuItem.prop('disabled'), true);
});

test('clicking "Unposted" when disabled does not call onSortByUnposted', function () {
  this.props.sortBySetting.disabled = true;
  this.props.sortBySetting.onSortByUnposted = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  this.getMenuItem(4).simulate('click');
  equal(this.props.sortBySetting.onSortByUnposted.callCount, 0);
});

QUnit.module('AssignmentColumnHeader - Assignment Details Action', {
  setup () {
    this.props = createExampleProps();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('shows the menu item in an enabled state', function () {
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="show-assignment-details"]');

  equal(specificMenuItem.textContent, 'Assignment Details');
  notOk(specificMenuItem.parentElement.parentElement.getAttribute('aria-disabled'));
});

test('disables the menu item when the disabled prop is true', function () {
  this.props.assignmentDetailsAction.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="show-assignment-details"]');

  equal(specificMenuItem.parentElement.parentElement.getAttribute('aria-disabled'), 'true');
});

test('clicking the menu item invokes the Assignment Details dialog', function () {
  this.props.assignmentDetailsAction.onSelect = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="show-assignment-details"]');
  specificMenuItem.click();

  equal(this.props.assignmentDetailsAction.onSelect.callCount, 1);
});

QUnit.module('AssignmentColumnHeader - Curve Grades Dialog', {
  setup () {
    this.props = createExampleProps();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('Curve Grades menu item is present in the popover menu', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = document.querySelector('[data-menu-item-id="curve-grades"]');
  equal(menuItem.textContent, 'Curve Grades');
  notOk(menuItem.parentElement.parentElement.getAttribute('aria-disabled'));
});

test('Curve Grades menu item is disabled when isDisabled is true', function () {
  this.props.curveGradesAction.isDisabled = true;
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = document.querySelector('[data-menu-item-id="curve-grades"]');
  ok(menuItem.parentElement.parentElement.getAttribute('aria-disabled'));
});

test('Curve Grades menu item is enabled when isDisabled is false', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = document.querySelector('[data-menu-item-id="curve-grades"]');
  notOk(menuItem.parentElement.parentElement.getAttribute('aria-disabled'));
});

test('onSelect is called when menu item is clicked', function () {
  this.props.curveGradesAction.onSelect = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);
  const menuItem = document.querySelector('[data-menu-item-id="curve-grades"]');
  menuItem.click();
  equal(this.props.curveGradesAction.onSelect.callCount, 1);
});

QUnit.module('AssignmentColumnHeader - Message Students Who Action', {
  setup () {
    this.props = createExampleProps();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('shows the menu item in an enabled state', function () {
  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="message-students-who"]');

  equal(menuItem.textContent, 'Message Students Who');
  notOk(menuItem.parentElement.parentElement.getAttribute('aria-disabled'));
});

test('disables the menu item when submissions are not loaded', function () {
  this.props.submissionsLoaded = false;
  this.wrapper = mountAndOpenOptions(this.props);

  const menuItem = document.querySelector('[data-menu-item-id="message-students-who"]');

  equal(menuItem.parentElement.parentElement.getAttribute('aria-disabled'), 'true');
});

test('clicking the menu item invokes the Message Students Who dialog', function () {
  this.wrapper = mountAndOpenOptions(this.props);
  this.stub(window, 'messageStudents');

  const menuItem = document.querySelector('[data-menu-item-id="message-students-who"]');
  menuItem.click();

  equal(window.messageStudents.callCount, 1);
});

QUnit.module('AssignmentColumnHeader - Mute/Unmute Assignment Action', {
  setup () {
    this.props = createExampleProps();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('shows the enabled "Mute Assignment" option when assignment is not muted', function () {
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="assignment-muter"]');

  equal(specificMenuItem.textContent, 'Mute Assignment');
  notOk(specificMenuItem.parentElement.parentElement.getAttribute('aria-disabled'));
});

test('shows the enabled "Unmute Assignment" option when assignment is muted', function () {
  this.props.assignment.muted = true;
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="assignment-muter"]');

  equal(specificMenuItem.textContent, 'Unmute Assignment');
  notOk(specificMenuItem.parentElement.parentElement.getAttribute('aria-disabled'));
});

test('disables the option when prop muteAssignmentAction.disabled is truthy', function () {
  this.props.muteAssignmentAction.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="assignment-muter"]');

  equal(specificMenuItem.parentElement.parentElement.getAttribute('aria-disabled'), 'true');
});

test('clicking the option invokes prop muteAssignmentAction.onSelect', function () {
  this.props.muteAssignmentAction.onSelect = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="assignment-muter"]');
  specificMenuItem.click();

  equal(this.props.muteAssignmentAction.onSelect.callCount, 1);
});

QUnit.module('AssignmentColumnHeader - non-standard assignment', {
  setup () {
    this.props = createExampleProps();
  },
});

test('renders 0 points possible when the assignment has no possible points', function () {
  this.props.assignment.pointsPossible = undefined;
  this.wrapper = mountComponent(this.props);
  const pointsPossible = this.wrapper.find('.assignment-points-possible');

  equal(pointsPossible.length, 1);
  equal(pointsPossible.text(), 'Out of 0');
});

test('renders a muted icon when the assignment is muted', function () {
  this.props.assignment.muted = true;
  this.wrapper = mountComponent(this.props);
  const link = this.wrapper.find('.assignment-name Link');
  const icon = link.find('IconMutedSolid');
  const expectedLinkTitle = 'This assignment is muted';

  equal(link.length, 1);
  deepEqual(link.props().title, expectedLinkTitle);
  equal(icon.length, 1);
  equal(icon.props().title, expectedLinkTitle);
});

test('renders a warning icon when the assignment does not count towards final grade', function () {
  this.props.assignment.omitFromFinalGrade = true;
  this.wrapper = mountComponent(this.props);
  const link = this.wrapper.find('.assignment-name Link');
  const icon = link.find('IconWarningSolid');
  const expectedLinkTitle = 'This assignment does not count toward the final grade';

  equal(link.length, 1);
  deepEqual(link.props().title, expectedLinkTitle);
  equal(icon.length, 1);
  equal(icon.props().title, expectedLinkTitle);
});

test('renders a warning icon when the assignment is invalid', function () {
  this.props.assignment.invalid = true;
  this.wrapper = mountComponent(this.props);
  const link = this.wrapper.find('.assignment-name Link');
  const icon = link.find('IconWarningSolid');
  const expectedLinkTitle = 'This assignment has no points possible and cannot be included in grade calculation';

  equal(link.length, 1);
  deepEqual(link.props().title, expectedLinkTitle);
  equal(icon.length, 1);
  equal(icon.props().title, expectedLinkTitle);
});

QUnit.module('AssignmentColumnHeader - Set Default Grade Action', {
  setup () {
    this.props = createExampleProps();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('shows the menu item in an enabled state', function () {
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="set-default-grade"]');

  equal(specificMenuItem.textContent, 'Set Default Grade');
  strictEqual(specificMenuItem.parentElement.parentElement.getAttribute('aria-disabled'), null);
});

test('disables the menu item when the disabled prop is true', function () {
  this.props.setDefaultGradeAction.disabled = true;
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="set-default-grade"]');

  equal(specificMenuItem.parentElement.parentElement.getAttribute('aria-disabled'), 'true');
});

test('clicking the menu item invokes the onSelect handler', function () {
  this.props.setDefaultGradeAction.onSelect = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="set-default-grade"]');
  specificMenuItem.click();

  equal(this.props.setDefaultGradeAction.onSelect.callCount, 1);
});

QUnit.module('AssignmentColumnHeader - Download Submissions Action', {
  setup () {
    this.props = createExampleProps();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('shows the menu item in an enabled state', function () {
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="download-submissions"]');

  equal(specificMenuItem.textContent, 'Download Submissions');
  notOk(specificMenuItem.parentElement.parentElement.getAttribute('aria-disabled'));
});

test('does not render the menu item when the hidden prop is true', function () {
  this.props.downloadSubmissionsAction.hidden = true;
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="download-submissions"]');

  equal(specificMenuItem, null);
});

test('clicking the menu item invokes the onSelect handler', function () {
  this.props.downloadSubmissionsAction.onSelect = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="download-submissions"]');
  specificMenuItem.click();

  equal(this.props.downloadSubmissionsAction.onSelect.callCount, 1);
});

QUnit.module('AssignmentColumnHeader - Reupload Submissions Action', {
  setup () {
    this.props = createExampleProps();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('shows the menu item in an enabled state', function () {
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="reupload-submissions"]');

  equal(specificMenuItem.textContent, 'Re-Upload Submissions');
  strictEqual(specificMenuItem.parentElement.getAttribute('aria-disabled'), null);
});

test('does not render the menu item when the hidden prop is true', function () {
  this.props.reuploadSubmissionsAction.hidden = true;
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="reupload-submissions"]');

  equal(specificMenuItem, null);
});

test('clicking the menu item invokes the onSelect property', function () {
  this.props.reuploadSubmissionsAction.onSelect = this.stub();
  this.wrapper = mountAndOpenOptions(this.props);

  const specificMenuItem = document.querySelector('[data-menu-item-id="reupload-submissions"]');
  specificMenuItem.click();

  equal(this.props.reuploadSubmissionsAction.onSelect.callCount, 1);
});
