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
  'react',
  'react-addons-test-utils',
  'enzyme',
  'jsx/gradezilla/default_gradebook/components/AssignmentColumnHeader',
], (React, TestUtils, { mount }, AssignmentColumnHeader) => {
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

  QUnit.module('AssignmentColumnHeader - base behavior', {
    setup () {
      const props = {
        assignment: createAssignmentProp(),
        assignmentDetailsAction: {
          disabled: false,
          onSelect: this.stub()
        },
        curveGradesAction: {
          isDisabled: false,
          onSelect: () => {}
        },
        setDefaultGradeAction: {
          disabled: false,
          onSelect: () => {}
        },
        students: createStudentsProp(),
        submissionsLoaded: true
      };
      this.wrapper = mount(<AssignmentColumnHeader {...props} />);
    },

    teardown () {
      this.wrapper.unmount();
    }
  });

  test('renders the assignment name in a link', function () {
    const actualElements = this.wrapper.find('.assignment-name Link');
    const expectedLinkProps = {
      children: [
        undefined,
        createAssignmentProp().name
      ],
      title: undefined,
      href: createAssignmentProp().htmlUrl
    };
    const actualProps = actualElements.props();

    equal(actualElements.length, 1);
    deepEqual(actualProps.children, expectedLinkProps.children);
    equal(actualProps.title, expectedLinkProps.title);
    equal(actualProps.href, expectedLinkProps.href);
  });

  test('renders the points possible', function () {
    const actualElements = this.wrapper.find('.assignment-points-possible');

    equal(actualElements.length, 1);
    equal(actualElements.props().children, 'Out of 13');
  });

  test('renders a PopoverMenu', function () {
    const actualElements = this.wrapper.find('PopoverMenu');

    equal(actualElements.length, 1);
  });

  test('renders an IconMoreSolid inside the PopoverMenu', function () {
    const actualElements = this.wrapper.find('PopoverMenu IconMoreSolid');

    equal(actualElements.length, 1);
  });

  test('renders a title for the More icon based on the assignment name', function () {
    const actualElements = this.wrapper.find('PopoverMenu IconMoreSolid');

    equal(actualElements.props().title, 'Assignment #1 Options');
  });

  QUnit.module('AssignmentColumnHeader - Assignment Details Action', {
    setup () {
      this.onSelectStub = this.stub();
      this.props = {
        assignment: createAssignmentProp(),
        assignmentDetailsAction: {
          disabled: false,
          onSelect: this.onSelectStub
        },
        curveGradesAction: {
          isDisabled: false,
          onSelect: () => {}
        },
        setDefaultGradeAction: {
          disabled: false,
          onSelect: () => {}
        },
        students: createStudentsProp(),
        submissionsLoaded: true
      };
    },

    teardown () {
      this.renderOutput.unmount();
    }
  });

  test('shows the menu item in an enabled state', function () {
    this.renderOutput = mount(<AssignmentColumnHeader {...this.props} />);
    this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');

    const specificMenuItem = document.querySelector('[data-menu-item-id="show-assignment-details"]');

    equal(specificMenuItem.textContent, 'Assignment Details');
    notOk(specificMenuItem.parentElement.parentElement.getAttribute('aria-disabled'));
  });

  test('disables the menu item when the disabled prop is true', function () {
    this.props.assignmentDetailsAction.disabled = true;

    this.renderOutput = mount(<AssignmentColumnHeader {...this.props} />);
    this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');

    const specificMenuItem = document.querySelector('[data-menu-item-id="show-assignment-details"]');

    equal(specificMenuItem.parentElement.parentElement.getAttribute('aria-disabled'), 'true');
  });

  test('clicking the menu item invokes the Assignment Details dialog', function () {
    this.renderOutput = mount(<AssignmentColumnHeader {...this.props} />);
    this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');

    const specificMenuItem = document.querySelector('[data-menu-item-id="show-assignment-details"]');

    specificMenuItem.click();

    equal(this.onSelectStub.callCount, 1);
  });

  QUnit.module('AssignmentColumnHeader - Curve Grades Dialog', {
    setupAndClick ({isDisabled = false, onSelect = () => {}} = {}) {
      this.wrapper = mount(
        <AssignmentColumnHeader
          assignment={createAssignmentProp()}
          assignmentDetailsAction={{ disabled: false, onSelect: () => {} }}
          curveGradesAction={{ isDisabled, onSelect }}
          setDefaultGradeAction={{ disabled: false, onSelect: () => {} }}
          students={createStudentsProp()}
          submissionsLoaded
        />
      );
      this.wrapper.find('.Gradebook__ColumnHeaderAction').simulate('click');
      const menuItem = document.querySelector('[data-menu-item-id="curve-grades"]');
      menuItem.click();
      return menuItem;
    },

    teardown () {
      this.wrapper.unmount();
    }
  });

  test('Curve Grades menu item is present in the popover menu', function () {
    const menuItem = this.setupAndClick();

    equal(menuItem.textContent, 'Curve Grades');
    notOk(menuItem.parentElement.parentElement.getAttribute('aria-disabled'));
  });

  test('Curve Grades menu item is disabled when isDisabled is true', function () {
    const menuItem = this.setupAndClick({ isDisabled: true });
    ok(menuItem.parentElement.parentElement.getAttribute('aria-disabled'));
  });

  test('Curve Grades menu item is enabled when isDisabled is false', function () {
    const menuItem = this.setupAndClick({ isDisabled: false });
    notOk(menuItem.parentElement.parentElement.getAttribute('aria-disabled'));
  });

  test('onSelect is called when menu item is clicked', function () {
    const onSelectSpy = this.spy();
    this.setupAndClick({ onSelect: onSelectSpy });
    ok(onSelectSpy.calledOnce);
  });

  QUnit.module('AssignmentColumnHeader - Message Students Who Menu', {
    setup () {
      this.props = {
        assignment: createAssignmentProp(),
        assignmentDetailsAction: {
          disabled: false,
          onSelect: () => {}
        },
        curveGradesAction: {
          isDisabled: false,
          onSelect: () => {}
        },
        setDefaultGradeAction: {
          disabled: false,
          onSelect: () => {}
        },
        students: createStudentsProp(),
        submissionsLoaded: true
      };
    },

    teardown () {
      this.wrapper.unmount();
    }
  });

  test('shows the menu item in an enabled state', function () {
    this.wrapper = mount(<AssignmentColumnHeader {...this.props} />);
    this.wrapper.find('.Gradebook__ColumnHeaderAction').simulate('click');
    const menuItem = document.querySelector('[data-menu-item-id="message-students-who"]');

    equal(menuItem.textContent, 'Message Students Who');
    notOk(menuItem.parentElement.parentElement.getAttribute('aria-disabled'));
  });

  test('disables the menu item when submissions are not loaded', function () {
    this.props.submissionsLoaded = false;
    this.wrapper = mount(<AssignmentColumnHeader {...this.props} />);
    this.wrapper.find('.Gradebook__ColumnHeaderAction').simulate('click');
    const menuItem = document.querySelector('[data-menu-item-id="message-students-who"]');

    equal(menuItem.parentElement.parentElement.getAttribute('aria-disabled'), 'true');
  });

  test('clicking the menu item invokes the Message Students Who dialog', function () {
    this.wrapper = mount(<AssignmentColumnHeader {...this.props} />);
    this.wrapper.find('.Gradebook__ColumnHeaderAction').simulate('click');
    const messageStudentsStub = this.stub(window, 'messageStudents');
    const menuItem = document.querySelector('[data-menu-item-id="message-students-who"]');
    menuItem.click();

    ok(messageStudentsStub.calledOnce);
  });

  QUnit.module('AssignmentColumnHeader - non-standard assignment', {
    setup () {
      this.assignment = createAssignmentProp();
      this.props = {
        assignment: this.assignment,
        assignmentDetailsAction: {
          disabled: false,
          onSelect: () => {}
        },
        curveGradesAction: {
          isDisabled: false,
          onSelect: () => {}
        },
        setDefaultGradeAction: {
          disabled: false,
          onSelect: () => {}
        },
        students: [],
        submissionsLoaded: false
      };
    },
  });

  test('renders 0 points possible when the assignment has no possible points', function () {
    this.assignment.pointsPossible = undefined;
    this.wrapper = mount(<AssignmentColumnHeader {...this.props} />);
    const actualElements = this.wrapper.find('.assignment-points-possible');

    equal(actualElements.length, 1);
    equal(actualElements.props().children, 'Out of 0');
  });

  test('renders a muted icon when the assignment is muted', function () {
    this.assignment.muted = true;
    this.wrapper = mount(<AssignmentColumnHeader {...this.props} />);
    const actualLinkElements = this.wrapper.find('.assignment-name Link');
    const actualIconElements = actualLinkElements.find('IconMutedSolid');
    const expectedLinkTitle = 'This assignment is muted';

    equal(actualLinkElements.length, 1);
    deepEqual(actualLinkElements.props().title, expectedLinkTitle);
    equal(actualIconElements.length, 1);
    equal(actualIconElements.props().title, expectedLinkTitle);
  });

  test('renders a warning icon when the assignment does not count towards final grade', function () {
    this.assignment.omitFromFinalGrade = true;
    this.wrapper = mount(<AssignmentColumnHeader {...this.props} />);
    const actualLinkElements = this.wrapper.find('.assignment-name Link');
    const actualIconElements = actualLinkElements.find('IconWarningSolid');
    const expectedLinkTitle = 'This assignment does not count toward the final grade';

    equal(actualLinkElements.length, 1);
    deepEqual(actualLinkElements.props().title, expectedLinkTitle);
    equal(actualIconElements.length, 1);
    equal(actualIconElements.props().title, expectedLinkTitle);
  });

  test('renders a warning icon when the assignment is invalid', function () {
    this.assignment.invalid = true;
    this.wrapper = mount(<AssignmentColumnHeader {...this.props} />);
    const actualLinkElements = this.wrapper.find('.assignment-name Link');
    const actualIconElements = actualLinkElements.find('IconWarningSolid');
    const expectedLinkTitle = 'This assignment has no points possible and cannot be included in grade calculation';

    equal(actualLinkElements.length, 1);
    deepEqual(actualLinkElements.props().title, expectedLinkTitle);
    equal(actualIconElements.length, 1);
    equal(actualIconElements.props().title, expectedLinkTitle);
  });

  QUnit.module('AssignmentColumnHeader - Set Default Grade Action', {
    setup () {
      this.onSelect = this.stub();
      this.props = {
        assignment: createAssignmentProp(),
        students: createStudentsProp(),
        submissionsLoaded: true,
        assignmentDetailsAction: {
          disabled: false,
          onSelect: () => {}
        },
        curveGradesAction: {
          isDisabled: false,
          onSelect: () => {}
        },
        setDefaultGradeAction: {
          disabled: false,
          onSelect: this.onSelect
        }
      };
    },

    teardown () {
      this.renderOutput.unmount();
    }
  });

  test('shows the menu item in an enabled state', function () {
    this.renderOutput = mount(<AssignmentColumnHeader {...this.props} />);
    this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');

    const specificMenuItem = document.querySelector('[data-menu-item-id="set-default-grade"]');

    equal(specificMenuItem.textContent, 'Set Default Grade');
    notOk(specificMenuItem.parentElement.getAttribute('aria-disabled'));
  });

  test('disables the menu item when the disabled prop is true', function () {
    this.props.setDefaultGradeAction.disabled = true;

    this.renderOutput = mount(<AssignmentColumnHeader {...this.props} />);
    this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');

    const specificMenuItem = document.querySelector('[data-menu-item-id="set-default-grade"]');

    equal(specificMenuItem.parentElement.parentElement.getAttribute('aria-disabled'), 'true');
  });

  test('clicking the menu item invokes the onSelect handler', function () {
    this.renderOutput = mount(<AssignmentColumnHeader {...this.props} />);
    this.renderOutput.find('.Gradebook__ColumnHeaderAction').simulate('click');

    const specificMenuItem = document.querySelector('[data-menu-item-id="set-default-grade"]');

    specificMenuItem.click();

    equal(this.onSelect.callCount, 1);
  });
});
