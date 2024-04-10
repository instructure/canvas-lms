/* * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import SelectMenuGroup from '../SelectMenuGroup'

describe('SelectMenuGroup', () => {
  let props: any
  let wrapper: any

  async function selectOptionFromMenu(user: any, menuSelector: string, optionValue: string) {
    await user.click(wrapper.container.querySelector(menuSelector))
    const options = screen.getAllByTestId('select-menu-option')
    const option = options.find(_option => _option.getAttribute('value') === optionValue)
    await user.click(option!)
  }

  beforeEach(() => {
    const assignmentSortOptions = [
      ['Assignment Group', 'assignment_group'],
      ['Due Date', 'due_date'],
      ['Name', 'title'],
    ]

    const courses = [
      {id: '2', nickname: 'Autos', url: '/courses/2/grades', gradingPeriodSetId: null},
      {id: '14', nickname: 'Woodworking', url: '/courses/14/grades', gradingPeriodSetId: null},
      {id: '21', nickname: 'Airbending', url: '/courses/21/grades', gradingPeriodSetId: '3'},
      {id: '42', nickname: 'Waterbending', url: '/courses/42/grades', gradingPeriodSetId: '3'},
      {id: '51', nickname: 'Earthbending', url: '/courses/51/grades', gradingPeriodSetId: null},
      {id: '60', nickname: 'Firebending', url: '/courses/60/grades', gradingPeriodSetId: '4'},
    ]

    const gradingPeriods = [
      {id: '9', title: 'Fall Semester'},
      {id: '12', title: 'Spring Semester'},
    ]

    const students = [
      {id: '7', name: 'Bob Smith'},
      {id: '11', name: 'Jane Doe'},
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
      students,
    }
  })

  //   suiteHooks.afterEach(() => {
  //     wrapper.unmount()
  //     document.getElementById('fixtures').innerHTML = ''
  //   })

  test('renders a student select menu if the students prop has more than 1 student', () => {
    wrapper = render(<SelectMenuGroup {...props} />)
    expect(wrapper.container.querySelector('#student_select_menu')).toBeInTheDocument()
  })

  test('does not render a student select menu if the students prop has only 1 student', () => {
    wrapper = render(<SelectMenuGroup {...props} students={[{id: '11', name: 'Jane Doe'}]} />)
    expect(wrapper.container.querySelector('#student_select_menu')).not.toBeInTheDocument()
  })

  test('disables the student select menu if the course select menu has changed', async () => {
    const user = userEvent.setup({delay: null})
    wrapper = render(<SelectMenuGroup {...props} />)
    await selectOptionFromMenu(user, '#course_select_menu', '14')
    expect(wrapper.container.querySelector('#student_select_menu')).toBeDisabled()
  })

  test('renders a grading period select menu if passed any grading periods', () => {
    wrapper = render(<SelectMenuGroup {...props} />)
    expect(wrapper.container.querySelector('#grading_period_select_menu')).toBeInTheDocument()
  })

  test('includes "All Grading Periods" as an option in the grading period select menu', async () => {
    const user = userEvent.setup()
    wrapper = render(<SelectMenuGroup {...props} />)
    await user.click(wrapper.container.querySelector('#grading_period_select_menu'))
    const options = screen.getAllByTestId('select-menu-option')
    expect(options[0].textContent).toBe('All Grading Periods')
  })

  test('does not render a grading period select menu if passed no grading periods', () => {
    wrapper = render(<SelectMenuGroup {...props} gradingPeriods={[]} />)
    expect(wrapper.container.querySelector('#grading_period_select_menu')).not.toBeInTheDocument()
  })

  test('disables the grading period select menu if the course select menu has changed', async () => {
    const user = userEvent.setup()
    wrapper = render(<SelectMenuGroup {...props} />)
    await selectOptionFromMenu(user, '#course_select_menu', '14')
    expect(wrapper.container.querySelector('#grading_period_select_menu')).toBeDisabled()
  })

  test('renders a course select menu if the courses prop has more than 1 course', () => {
    wrapper = render(<SelectMenuGroup {...props} />)
    expect(wrapper.container.querySelector('#course_select_menu')).toBeInTheDocument()
  })

  test('does not render a course select menu if the courses prop has only 1 course', () => {
    wrapper = render(
      <SelectMenuGroup
        {...props}
        courses={[{id: '2', nickname: 'Autos', url: '/courses/2/grades'}]}
      />
    )
    expect(wrapper.container.querySelector('#course_select_menu')).not.toBeInTheDocument()
  })

  test('disables the course select menu if the student select menu has changed', async () => {
    const user = userEvent.setup()
    wrapper = render(<SelectMenuGroup {...props} />)
    await selectOptionFromMenu(user, '#student_select_menu', '7')
    expect(wrapper.container.querySelector('#course_select_menu')).toBeDisabled()
  })

  test('disables the course select menu if the grading period select menu has changed', async () => {
    const user = userEvent.setup()
    wrapper = render(<SelectMenuGroup {...props} />)
    await selectOptionFromMenu(user, '#grading_period_select_menu', '12')
    expect(wrapper.container.querySelector('#course_select_menu')).toBeDisabled()
  })

  test('disables the course select menu if the assignment sort order select menu has changed', async () => {
    const user = userEvent.setup()
    wrapper = render(<SelectMenuGroup {...props} />)
    await selectOptionFromMenu(user, '#assignment_sort_order_select_menu', 'title')
    expect(wrapper.container.querySelector('#course_select_menu')).toBeDisabled()
  })

  test('renders an assignment sort order select menu', () => {
    wrapper = render(<SelectMenuGroup {...props} />)
    const select = wrapper.container.querySelector('#assignment_sort_order_select_menu')
    expect(select).toBeInTheDocument()
  })

  test('disables the assignment sort order select menu if the course select menu has changed', async () => {
    const user = userEvent.setup()
    wrapper = render(<SelectMenuGroup {...props} />)
    await selectOptionFromMenu(user, '#course_select_menu', '14')
    expect(wrapper.container.querySelector('#assignment_sort_order_select_menu')).toBeDisabled()
  })

  test('renders a submit button', () => {
    wrapper = render(<SelectMenuGroup {...props} />)
    expect(wrapper.container.querySelector('button#apply_select_menus')).toBeInTheDocument()
  })

  test('disables the submit button if no select menu options have changed', () => {
    wrapper = render(<SelectMenuGroup {...props} />)
    const submitButton = wrapper.container.querySelector('button#apply_select_menus')
    expect(submitButton).toBeInTheDocument()
  })

  test('enables the submit button if a select menu options is changed', async () => {
    const user = userEvent.setup()
    wrapper = render(<SelectMenuGroup {...props} />)
    const submitButton = wrapper.container.querySelector('button#apply_select_menus')

    expect(submitButton).toBeDisabled()
    await selectOptionFromMenu(user, '#student_select_menu', '7')
    expect(submitButton).not.toBeDisabled()
  })

  test('disables the submit button after it is clicked', async () => {
    const user = userEvent.setup()
    wrapper = render(<SelectMenuGroup {...props} />)
    const submitButton = wrapper.container.querySelector('button#apply_select_menus')
    await selectOptionFromMenu(user, '#student_select_menu', '7')
    await user.click(submitButton)
    expect(submitButton).toBeDisabled()
  })

  test('calls saveAssignmentOrder when the button is clicked, if assignment order has changed', async () => {
    const stub = jest.fn(() => Promise.resolve())
    const user = userEvent.setup()
    wrapper = render(<SelectMenuGroup {...props} saveAssignmentOrder={stub} />)
    await selectOptionFromMenu(user, '#assignment_sort_order_select_menu', 'title')
    const submitButton = wrapper.container.querySelector('button#apply_select_menus')
    await user.click(submitButton)
    expect(stub).toHaveBeenCalledTimes(1)
  })

  test('does not call saveAssignmentOrder when the button is clicked, if assignment is unchanged', async () => {
    const user = userEvent.setup()
    props.saveAssignmentOrder = jest.fn()
    wrapper = render(<SelectMenuGroup {...props} />)
    await selectOptionFromMenu(user, '#student_select_menu', '7')
    const submitButton = wrapper.container.querySelector('button#apply_select_menus')
    await user.click(submitButton)
    expect(props.saveAssignmentOrder).toHaveBeenCalledTimes(0)
  })

  describe('clicking the submit button', () => {
    let submitButton

    function mountComponent() {
      return render(<SelectMenuGroup {...props} />)
    }

    beforeEach(() => {
      props.goToURL = jest.fn()
    })

    describe('when the student has changed', () => {
      test('reloads the page', async () => {
        const user = userEvent.setup()
        wrapper = mountComponent()
        submitButton = wrapper.container.querySelector('button#apply_select_menus')
        await selectOptionFromMenu(user, '#student_select_menu', '7')
        await user.click(submitButton)
        expect(props.goToURL).toHaveBeenCalledTimes(1)
      })

      test('takes you to the grades page for that student', async () => {
        const user = userEvent.setup()
        wrapper = mountComponent()
        submitButton = wrapper.container.querySelector('button#apply_select_menus')
        await selectOptionFromMenu(user, '#student_select_menu', '7')
        await user.click(submitButton)
        expect(props.goToURL).toHaveBeenCalledWith('/courses/2/grades/7')
      })
    })

    describe('when the current course has no grading period set', () => {
      describe('when changing to another without a grading period set', () => {
        test('reloads the page', async () => {
          const user = userEvent.setup()
          props.selectedCourseID = '2'
          wrapper = mountComponent()
          submitButton = wrapper.container.querySelector('button#apply_select_menus')
          await selectOptionFromMenu(user, '#course_select_menu', '14')
          await user.click(submitButton)
          expect(props.goToURL).toHaveBeenCalledTimes(1)
        })

        test('takes you to the grades page for that course', async () => {
          const user = userEvent.setup()
          props.selectedCourseID = '2'
          wrapper = mountComponent()
          submitButton = wrapper.container.querySelector('button#apply_select_menus')
          await selectOptionFromMenu(user, '#course_select_menu', '14')
          await user.click(submitButton)
          expect(props.goToURL).toHaveBeenCalledWith('/courses/14/grades/11')
        })
      })

      describe('when changing to one with a grading period set', () => {
        test('reloads the page', async () => {
          const user = userEvent.setup()
          props.selectedCourseID = '2'
          wrapper = mountComponent()
          submitButton = wrapper.container.querySelector('button#apply_select_menus')
          await selectOptionFromMenu(user, '#course_select_menu', '21')
          await user.click(submitButton)
          expect(props.goToURL).toHaveBeenCalledTimes(1)
        })

        test('takes you to the grades page for that course', async () => {
          const user = userEvent.setup()
          props.selectedCourseID = '2'
          wrapper = mountComponent()
          submitButton = wrapper.container.querySelector('button#apply_select_menus')
          await selectOptionFromMenu(user, '#course_select_menu', '21')
          await user.click(submitButton)
          expect(props.goToURL).toHaveBeenCalledWith('/courses/21/grades/11')
        })
      })
    })

    describe('when the current course has a grading period set', () => {
      describe('when changing to one without a grading period set', () => {
        test('reloads the page', async () => {
          const user = userEvent.setup()
          props.selectedCourseID = '21'
          wrapper = mountComponent()
          submitButton = wrapper.container.querySelector('button#apply_select_menus')
          await selectOptionFromMenu(user, '#course_select_menu', '2')
          await user.click(submitButton)
          expect(props.goToURL).toHaveBeenCalledTimes(1)
        })

        test('takes you to the grades page for that course and does not pass along the selected grading period', async () => {
          const user = userEvent.setup()
          props.selectedCourseID = '21'
          wrapper = mountComponent()
          submitButton = wrapper.container.querySelector('button#apply_select_menus')
          await selectOptionFromMenu(user, '#course_select_menu', '2')
          await user.click(submitButton)
          expect(props.goToURL).toHaveBeenCalledWith('/courses/2/grades/11')
        })
      })

      describe('when changing to one with the same grading period set', () => {
        test('reloads the page', async () => {
          const user = userEvent.setup()
          props.selectedCourseID = '21'
          wrapper = mountComponent()
          submitButton = wrapper.container.querySelector('button#apply_select_menus')
          await selectOptionFromMenu(user, '#course_select_menu', '42')
          await user.click(submitButton)
          expect(props.goToURL).toHaveBeenCalledTimes(1)
        })

        test('takes you to the grades page for that course and passes the currently selected grading period', async () => {
          const user = userEvent.setup()
          props.selectedCourseID = '21'
          wrapper = mountComponent()
          submitButton = wrapper.container.querySelector('button#apply_select_menus')
          await selectOptionFromMenu(user, '#course_select_menu', '42')
          await user.click(submitButton)
          expect(props.goToURL).toHaveBeenCalledWith('/courses/42/grades/11?grading_period_id=9')
        })
      })

      describe('when changing to one with a different grading period set', () => {
        test('reloads the page', async () => {
          const user = userEvent.setup()
          props.selectedCourseID = '21'
          wrapper = mountComponent()
          submitButton = wrapper.container.querySelector('button#apply_select_menus')
          await selectOptionFromMenu(user, '#course_select_menu', '60')
          await user.click(submitButton)
          expect(props.goToURL).toHaveBeenCalledTimes(1)
        })

        test('takes you to the grades page for that course and does not pass the currently selected grading period', async () => {
          const user = userEvent.setup()
          props.selectedCourseID = '21'
          wrapper = mountComponent()
          submitButton = wrapper.container.querySelector('button#apply_select_menus')
          await selectOptionFromMenu(user, '#course_select_menu', '60')
          await user.click(submitButton)
          expect(props.goToURL).toHaveBeenCalledWith('/courses/60/grades/11')
        })
      })
    })
  })
})
