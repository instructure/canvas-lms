/* * Copyright (C) 2017 - present Instructure, Inc.
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

import SelectMenuGroup from 'jsx/grade_summary/SelectMenuGroup';

QUnit.module('SelectMenuGroup', function (hooks) {
  let props;
  let wrapper;

  function mountComponent () {
    return mount(<SelectMenuGroup {...props} />);
  }

  hooks.beforeEach(function () {
    const assignmentSortOptions = [
      ['Assignment Group', 'assignment_group'],
      ['Due Date', 'due_date'],
      ['Title', 'title']
    ];

    const courses = [
      { id: '2', nickname: 'Autos', url: '/courses/2/grades' },
      { id: '14', nickname: 'Woodworking', url: '/courses/14/grades' }
    ];

    const gradingPeriods = [
      { id: '9', title: 'Fall Semester' },
      { id: '12', title: 'Spring Semester' }
    ];

    const students = [
      { id: '7', name: 'Bob Smith' },
      { id: '11', name: 'Jane Doe' }
    ];

    props = {
      assignmentSortOptions,
      courses,
      currentUserID: '3',
      displayPageContent () {},
      goToURL () {},
      gradingPeriods,
      saveAssignmentOrder () {},
      selectedAssignmentSortOrder: 'due_date',
      selectedCourseID: '2',
      selectedGradingPeriodID: '9',
      selectedStudentID: '11',
      students
    };
  });

  hooks.afterEach(function () {
    wrapper.unmount();
    document.getElementById('fixtures').innerHTML = '';
  });

  test('renders a student select menu if the students prop has more than 1 student', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('#student_select_menu').length, 1);
  });

  test('does not render a student select menu if the students prop has only 1 student', function () {
    props.students = [{ id: '11', name: 'Jane Doe' }];
    wrapper = mountComponent();
    strictEqual(wrapper.find('#student_select_menu').length, 0);
  });

  test('disables the student select menu if the course select menu has changed', function () {
    wrapper = mountComponent();
    wrapper.find('#course_select_menu').simulate('change', { target: { value: '14' } });
    const menu = wrapper.find('#student_select_menu').node;
    strictEqual(menu.getAttribute('aria-disabled'), 'true');
  });

  test('renders a grading period select menu if passed any grading periods', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('#grading_period_select_menu').length, 1);
  });

  test('includes "All Grading Periods" as an option in the grading period select menu', function () {
    wrapper = mountComponent();
    const option = wrapper.find('#grading_period_select_menu').node.options[0];
    strictEqual(option.innerText, 'All Grading Periods');
  });

  test('does not render a grading period select menu if passed no grading periods', function () {
    props.gradingPeriods = [];
    wrapper = mountComponent();
    strictEqual(wrapper.find('#grading_period_select_menu').length, 0);
  });

  test('disables the grading period select menu if the course select menu has changed', function () {
    wrapper = mountComponent();
    wrapper.find('#course_select_menu').simulate('change', { target: { value: '14' } });
    const menu = wrapper.find('#grading_period_select_menu').node;
    strictEqual(menu.getAttribute('aria-disabled'), 'true');
  });

  test('renders a course select menu if the courses prop has more than 1 course', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('#course_select_menu').length, 1);
  });

  test('does not render a course select menu if the courses prop has only 1 course', function () {
    props.courses = [{ id: '2', nickname: 'Autos', url: '/courses/2/grades' }];
    wrapper = mountComponent();
    strictEqual(wrapper.find('#course_select_menu').length, 0);
  });

  test('disables the course select menu if the student select menu has changed', function () {
    wrapper = mountComponent();
    wrapper.find('#student_select_menu').simulate('change', { target: { value: '7' } });
    const menu = wrapper.find('#course_select_menu').node;
    strictEqual(menu.getAttribute('aria-disabled'), 'true');
  });

  test('disables the course select menu if the grading period select menu has changed', function () {
    wrapper = mountComponent();
    wrapper.find('#grading_period_select_menu').simulate('change', { target: { value: '12' } });
    const menu = wrapper.find('#course_select_menu').node;
    strictEqual(menu.getAttribute('aria-disabled'), 'true');
  });

  test('disables the course select menu if the assignment sort order select menu has changed', function () {
    wrapper = mountComponent();
    wrapper.find('#assignment_sort_order_select_menu').simulate('change', { target: { value: 'title' } });
    const menu = wrapper.find('#course_select_menu').node;
    strictEqual(menu.getAttribute('aria-disabled'), 'true');
  });

  test('renders an assignment sort order select menu', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('#assignment_sort_order_select_menu').length, 1);
  });

  test('disables the assignment sort order select menu if the course select menu has changed', function () {
    wrapper = mountComponent();
    wrapper.find('#course_select_menu').simulate('change', { target: { value: '14' } });
    const menu = wrapper.find('#assignment_sort_order_select_menu').node;
    strictEqual(menu.getAttribute('aria-disabled'), 'true');
  });

  test('renders a submit button', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('#apply_select_menus').length, 1);
  });

  test('disables the submit button if no select menu options have changed', function () {
    wrapper = mountComponent();
    const submitButton = wrapper.find('#apply_select_menus').node;
    strictEqual(submitButton.getAttribute('aria-disabled'), 'true');
  });

  test('enables the submit button if a select menu options is changed', function () {
    wrapper = mountComponent();
    wrapper.find('#student_select_menu').simulate('change', { target: { value: '7' } });
    const submitButton = wrapper.find('#apply_select_menus').node;
    strictEqual(submitButton.getAttribute('aria-disabled'), null);
  });

  test('disables the submit button after it is clicked', function () {
    wrapper = mountComponent();
    wrapper.find('#student_select_menu').simulate('change', { target: { value: '7' } });
    const submitButton = wrapper.find('#apply_select_menus');
    submitButton.simulate('click');
    strictEqual(submitButton.node.getAttribute('aria-disabled'), 'true');
  });

  test('calls saveAssignmentOrder when the button is clicked, if assignment order has changed', function () {
    props.saveAssignmentOrder = sinon.stub().resolves();
    wrapper = mountComponent();
    wrapper.find('#assignment_sort_order_select_menu').simulate('change', { target: { value: 'title' } });
    const submitButton = wrapper.find('#apply_select_menus');
    submitButton.simulate('click');
    strictEqual(props.saveAssignmentOrder.callCount, 1);
  });

  test('does not call saveAssignmentOrder when the button is clicked, if assignment is unchanged', function () {
    props.saveAssignmentOrder = sinon.stub().resolves();
    wrapper = mountComponent();
        wrapper.find('#student_select_menu').simulate('change', { target: { value: '7' } });
    const submitButton = wrapper.find('#apply_select_menus');
    submitButton.simulate('click');
    strictEqual(props.saveAssignmentOrder.callCount, 0);
  });

  test('reloads the page when the submit button is clicked', function () {
    props.goToURL = sinon.stub();
    wrapper = mountComponent();
    wrapper.find('#student_select_menu').simulate('change', { target: { value: '7' } });
    const submitButton = wrapper.find('#apply_select_menus');
    submitButton.simulate('click');
    strictEqual(props.goToURL.callCount, 1);
  });
});
