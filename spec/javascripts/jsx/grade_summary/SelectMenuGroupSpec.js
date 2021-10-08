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

import React from 'react'
import {mount} from 'enzyme'
import {makeSelection, getSelect, getSelectMenuOptions, isSelectDisabled} from './SelectMenuHelpers'

import SelectMenuGroup from 'ui/features/grade_summary/react/SelectMenuGroup.js'

QUnit.module('SelectMenuGroup', suiteHooks => {
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    const assignmentSortOptions = [
      ['Assignment Group', 'assignment_group'],
      ['Due Date', 'due_date'],
      ['Title', 'title']
    ]

    const courses = [
      {id: '2', nickname: 'Autos', url: '/courses/2/grades', gradingPeriodSetId: null},
      {id: '14', nickname: 'Woodworking', url: '/courses/14/grades', gradingPeriodSetId: null},
      {id: '21', nickname: 'Airbending', url: '/courses/21/grades', gradingPeriodSetId: '3'},
      {id: '42', nickname: 'Waterbending', url: '/courses/42/grades', gradingPeriodSetId: '3'},
      {id: '51', nickname: 'Earthbending', url: '/courses/51/grades', gradingPeriodSetId: null},
      {id: '60', nickname: 'Firebending', url: '/courses/60/grades', gradingPeriodSetId: '4'}
    ]

    const gradingPeriods = [
      {id: '9', title: 'Fall Semester'},
      {id: '12', title: 'Spring Semester'}
    ]

    const students = [
      {id: '7', name: 'Bob Smith'},
      {id: '11', name: 'Jane Doe'}
    ]

    props = {
      assignmentSortOptions,
      courses,
      currentUserID: '3',
      displayPageContent() {},
      goToURL() {},
      gradingPeriods,
      saveAssignmentOrder() {},
      selectedAssignmentSortOrder: 'due_date',
      selectedCourseID: '2',
      selectedGradingPeriodID: '9',
      selectedStudentID: '11',
      students
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    document.getElementById('fixtures').innerHTML = ''
  })

  test('renders a student select menu if the students prop has more than 1 student', () => {
    wrapper = mount(<SelectMenuGroup {...props} />)
    strictEqual(wrapper.find('SelectMenu#student_select_menu').length, 1)
  })

  test('does not render a student select menu if the students prop has only 1 student', () => {
    wrapper = mount(<SelectMenuGroup {...props} students={[{id: '11', name: 'Jane Doe'}]} />)
    strictEqual(wrapper.find('SelectMenu#student_select_menu').length, 0)
  })

  test('disables the student select menu if the course select menu has changed', () => {
    wrapper = mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    makeSelection(wrapper, 'course_select_menu', '14')
    strictEqual(isSelectDisabled(wrapper, 'student_select_menu'), true)
  })

  test('renders a grading period select menu if passed any grading periods', () => {
    wrapper = mount(<SelectMenuGroup {...props} />)
    strictEqual(wrapper.find('SelectMenu#grading_period_select_menu').length, 1)
  })

  test('includes "All Grading Periods" as an option in the grading period select menu', () => {
    wrapper = mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    const options = getSelectMenuOptions(wrapper, 'grading_period_select_menu')
    strictEqual(options[0].textContent, 'All Grading Periods')
  })

  test('does not render a grading period select menu if passed no grading periods', () => {
    wrapper = mount(<SelectMenuGroup {...props} gradingPeriods={[]} />, {
      attachTo: document.getElementById('fixtures')
    })
    strictEqual(wrapper.find('SelectMenu#grading_period_select_menu').length, 0)
  })

  test('disables the grading period select menu if the course select menu has changed', () => {
    wrapper = mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    makeSelection(wrapper, 'course_select_menu', '14')
    strictEqual(isSelectDisabled(wrapper, 'grading_period_select_menu'), true)
  })

  test('renders a course select menu if the courses prop has more than 1 course', () => {
    wrapper = mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    strictEqual(wrapper.find('SelectMenu#course_select_menu').length, 1)
  })

  test('does not render a course select menu if the courses prop has only 1 course', () => {
    wrapper = mount(
      <SelectMenuGroup
        {...props}
        courses={[{id: '2', nickname: 'Autos', url: '/courses/2/grades'}]}
      />,
      {attachTo: document.getElementById('fixtures')}
    )
    strictEqual(wrapper.find('SelectMenu#course_select_menu').length, 0)
  })

  test('disables the course select menu if the student select menu has changed', () => {
    wrapper = mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    makeSelection(wrapper, 'student_select_menu', '7')
    strictEqual(isSelectDisabled(wrapper, 'course_select_menu'), true)
  })

  test('disables the course select menu if the grading period select menu has changed', () => {
    wrapper = mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    makeSelection(wrapper, 'grading_period_select_menu', '12')
    strictEqual(
      wrapper
        .find('#course_select_menu')
        .last()
        .getDOMNode().disabled,
      true
    )
  })

  test('disables the course select menu if the assignment sort order select menu has changed', () => {
    wrapper = mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    makeSelection(wrapper, 'assignment_sort_order_select_menu', 'title')
    strictEqual(isSelectDisabled(wrapper, 'course_select_menu'), true)
  })

  test('renders an assignment sort order select menu', () => {
    wrapper = mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    const select = getSelect(wrapper, 'SelectMenu#assignment_sort_order_select_menu')
    ok(select)
  })

  test('disables the assignment sort order select menu if the course select menu has changed', () => {
    wrapper = mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    makeSelection(wrapper, 'course_select_menu', '14')
    strictEqual(isSelectDisabled(wrapper, 'assignment_sort_order_select_menu'), true)
  })

  test('renders a submit button', () => {
    wrapper = mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    strictEqual(wrapper.find('button#apply_select_menus').length, 1)
  })

  test('disables the submit button if no select menu options have changed', () => {
    wrapper = mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    const submitButton = wrapper.find('button#apply_select_menus')
    strictEqual(submitButton.prop('disabled'), true)
  })

  test('enables the submit button if a select menu options is changed', () => {
    wrapper = mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    const submitButton = wrapper
      .find('#apply_select_menus')
      .hostNodes()
      .getDOMNode()

    strictEqual(submitButton.disabled, true)
    makeSelection(wrapper, 'student_select_menu', '7')
    strictEqual(submitButton.disabled, false)
  })

  test('disables the submit button after it is clicked', () => {
    wrapper = mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    makeSelection(wrapper, 'student_select_menu', '7')
    wrapper.find('button#apply_select_menus').simulate('click')
    strictEqual(wrapper.find('button#apply_select_menus').prop('disabled'), true)
  })

  test('calls saveAssignmentOrder when the button is clicked, if assignment order has changed', () => {
    const stub = sinon.stub().resolves()
    wrapper = mount(<SelectMenuGroup {...props} saveAssignmentOrder={stub} />, {
      attachTo: document.getElementById('fixtures')
    })
    makeSelection(wrapper, 'assignment_sort_order_select_menu', 'title')
    const submitButton = wrapper.find('button#apply_select_menus')
    submitButton.simulate('click')
    strictEqual(stub.callCount, 1)
  })

  test('does not call saveAssignmentOrder when the button is clicked, if assignment is unchanged', () => {
    props.saveAssignmentOrder = sinon.stub().resolves()
    wrapper = mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    makeSelection(wrapper, 'student_select_menu', '7')
    const submitButton = wrapper.find('button#apply_select_menus').last()
    submitButton.simulate('click')
    strictEqual(props.saveAssignmentOrder.callCount, 0)
  })

  QUnit.module('clicking the submit button', hooks => {
    let submitButton

    function mountComponent() {
      return mount(<SelectMenuGroup {...props} />, {attachTo: document.getElementById('fixtures')})
    }

    hooks.beforeEach(() => {
      props.goToURL = sinon.stub()
    })

    QUnit.module('when the student has changed', contextHooks => {
      contextHooks.beforeEach(() => {
        wrapper = mountComponent()
        submitButton = wrapper.find('button#apply_select_menus').last()
        makeSelection(wrapper, 'student_select_menu', '7')
        submitButton.simulate('click')
      })

      test('reloads the page', () => {
        strictEqual(props.goToURL.callCount, 1)
      })

      test('takes you to the grades page for that student', () => {
        deepEqual(props.goToURL.firstCall.args, ['/courses/2/grades/7'])
      })
    })

    QUnit.module('when the current course has no grading period set', () => {
      QUnit.module('when changing to another without a grading period set', contextHooks => {
        contextHooks.beforeEach(() => {
          props.selectedCourseID = '2'
          wrapper = mountComponent()
          submitButton = wrapper.find('button#apply_select_menus').last()
          makeSelection(wrapper, 'course_select_menu', '14')
          submitButton.simulate('click')
        })

        test('reloads the page', () => {
          strictEqual(props.goToURL.callCount, 1)
        })

        test('takes you to the grades page for that course', () => {
          deepEqual(props.goToURL.firstCall.args, ['/courses/14/grades/11'])
        })
      })

      QUnit.module('when changing to one with a grading period set', contextHooks => {
        contextHooks.beforeEach(() => {
          props.selectedCourseID = '2'
          wrapper = mountComponent()
          submitButton = wrapper.find('button#apply_select_menus').last()
          makeSelection(wrapper, 'course_select_menu', '21')
          submitButton.simulate('click')
        })

        test('reloads the page', () => {
          strictEqual(props.goToURL.callCount, 1)
        })

        test('takes you to the grades page for that course', () => {
          deepEqual(props.goToURL.firstCall.args, ['/courses/21/grades/11'])
        })
      })
    })

    QUnit.module('when the current course has a grading period set', () => {
      QUnit.module('when changing to one without a grading period set', contextHooks => {
        contextHooks.beforeEach(() => {
          props.selectedCourseID = '21'
          wrapper = mountComponent()
          submitButton = wrapper.find('button#apply_select_menus').last()
          makeSelection(wrapper, 'course_select_menu', '2')
          submitButton.simulate('click')
        })

        test('reloads the page', () => {
          strictEqual(props.goToURL.callCount, 1)
        })

        test('takes you to the grades page for that course and does not pass along the selected grading period', () => {
          deepEqual(props.goToURL.firstCall.args, ['/courses/2/grades/11'])
        })
      })

      QUnit.module('when changing to one with the same grading period set', contextHooks => {
        contextHooks.beforeEach(() => {
          props.selectedCourseID = '21'
          wrapper = mountComponent()
          submitButton = wrapper.find('button#apply_select_menus').last()
          makeSelection(wrapper, 'course_select_menu', '42')
          submitButton.simulate('click')
        })

        test('reloads the page', () => {
          strictEqual(props.goToURL.callCount, 1)
        })

        test('takes you to the grades page for that course and passes the currently selected grading period', () => {
          deepEqual(props.goToURL.firstCall.args, ['/courses/42/grades/11?grading_period_id=9'])
        })
      })

      QUnit.module('when changing to one with a different grading period set', contextHooks => {
        contextHooks.beforeEach(() => {
          props.selectedCourseID = '21'
          wrapper = mountComponent()
          submitButton = wrapper.find('button#apply_select_menus').last()
          makeSelection(wrapper, 'course_select_menu', '60')
          submitButton.simulate('click')
        })

        test('reloads the page', () => {
          strictEqual(props.goToURL.callCount, 1)
        })

        test('takes you to the grades page for that course and does not pass the currently selected grading period', () => {
          deepEqual(props.goToURL.firstCall.args, ['/courses/60/grades/11'])
        })
      })
    })
  })
})
