/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, screen, cleanup} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {SearchFormComponent} from '../SearchForm'
import {Button} from '@instructure/ui-buttons'
import CanvasDateInput2 from '@canvas/datetime/react/components/DateInput2'
import CanvasAsyncSelect from '@canvas/instui-bindings/react/AsyncSelect'
import {FormFieldGroup} from '@instructure/ui-form-field'
import Fixtures from './Fixtures'

const defaultProps = () => ({
  fetchHistoryStatus: 'started',
  getGradebookHistory() {},
  clearSearchOptions() {},
  getSearchOptions() {},
  getSearchOptionsNextPage() {},
  assignments: {
    fetchStatus: 'started',
    items: [],
    nextPage: '',
  },
  graders: {
    fetchStatus: 'started',
    items: [],
    nextPage: '',
  },
  students: {
    fetchStatus: 'started',
    items: [],
    nextPage: '',
  },
})

const liveRegion = document.createElement('div')
liveRegion.id = 'flash_screenreader_holder'
liveRegion.setAttribute('role', 'alert')
document.body.appendChild(liveRegion)

const mountComponent = (props = {}) =>
  render(<SearchFormComponent {...defaultProps()} {...props} />)

describe('SearchForm', () => {
  afterEach(() => {
    cleanup()
  })

  test('has a form field group', function () {
    mountComponent()
    expect(screen.getByText('Search Form')).toBeInTheDocument()
  })

  test('has an Autocomplete with id #graders', function () {
    mountComponent()
    expect(document.querySelector('#graders')).toBeInTheDocument()
  })

  test('has an Autocomplete with id #students', function () {
    mountComponent()
    expect(document.querySelector('#students')).toBeInTheDocument()
  })

  test('has an Autocomplete with id #assignments', function () {
    mountComponent()
    expect(document.querySelector('#assignments')).toBeInTheDocument()
  })

  test('has date pickers for from date and to date', function () {
    mountComponent()
    expect(screen.getByLabelText('Start Date')).toBeInTheDocument()
    expect(screen.getByLabelText('End Date')).toBeInTheDocument()
  })

  test('has a Button for submitting', function () {
    mountComponent()
    expect(screen.getByRole('button', {name: 'Filter'})).toBeInTheDocument()
  })

  test('disables the submit button if To date is before From date', async function () {
    const user = userEvent.setup()
    mountComponent()

    const fromDateInputs = screen.getAllByLabelText('Start Date')
    const toDateInputs = screen.getAllByLabelText('End Date')

    // Clear and set the from date to be after the to date
    await user.clear(fromDateInputs[0])
    await user.type(fromDateInputs[0], '05/02/2017')
    await user.tab() // Trigger blur

    await user.clear(toDateInputs[0])
    await user.type(toDateInputs[0], '05/01/2017')
    await user.tab() // Trigger blur

    // Wait for the state to update
    await new Promise(resolve => setTimeout(resolve, 100))

    const buttons = screen.getAllByRole('button', {name: 'Filter'})
    expect(buttons[0]).toBeDisabled()
  })

  test('does not disable the submit button if To date is after From date', async function () {
    const user = userEvent.setup()
    mountComponent()

    const fromDateInputs = screen.getAllByLabelText('Start Date')
    const toDateInputs = screen.getAllByLabelText('End Date')

    await user.type(fromDateInputs[0], '05/01/2017')
    await user.type(toDateInputs[0], '05/02/2017')

    const buttons = screen.getAllByRole('button', {name: 'Filter'})
    expect(buttons[0]).not.toBeDisabled()
  })

  test('does not disable the submit button when there are no dates selected', function () {
    mountComponent()
    const buttons = screen.getAllByRole('button', {name: 'Filter'})
    expect(buttons[0]).not.toBeDisabled()
  })

  test('does not disable the submit button when only from date is entered', async function () {
    const user = userEvent.setup()
    mountComponent()

    const fromDateInputs = screen.getAllByLabelText('Start Date')
    await user.type(fromDateInputs[0], '04/08/1994')

    const buttons = screen.getAllByRole('button', {name: 'Filter'})
    expect(buttons[0]).not.toBeDisabled()
  })

  test('does not disable the submit button when only to date is entered', async function () {
    const user = userEvent.setup()
    mountComponent()

    const toDateInputs = screen.getAllByLabelText('End Date')
    await user.type(toDateInputs[0], '05/01/2017')

    const buttons = screen.getAllByRole('button', {name: 'Filter'})
    expect(buttons[0]).not.toBeDisabled()
  })

  test('calls getGradebookHistory prop on mount', () => {
    const props = {getGradebookHistory: jest.fn()}
    render(<SearchFormComponent {...defaultProps()} {...props} />)
    expect(props.getGradebookHistory).toHaveBeenCalledTimes(1)
  })

  describe('SearchForm when button is clicked', () => {
    test('dispatches with the state of input', async function () {
      const user = userEvent.setup()
      const props = {getGradebookHistory: jest.fn()}
      mountComponent(props)

      const buttons = screen.getAllByRole('button', {name: 'Filter'})
      await user.click(buttons[0])

      expect(props.getGradebookHistory).toHaveBeenCalled()
    })

    describe('SearchForm Autocomplete options', () => {
      let assignments: any
      let graders: any
      let students: any
      let props: any

      beforeEach(() => {
        props = {...defaultProps(), getSearchOptions: jest.fn()}
        assignments = Fixtures.assignmentArray()
        graders = Fixtures.userArray()
        students = Fixtures.userArray()
      })

      test('selecting a grader from options calls getSearchOptions', async function () {
        const user = userEvent.setup()
        const gradersProp = {
          fetchStatus: 'success',
          items: graders,
          nextPage: '',
        }
        const {rerender} = render(<SearchFormComponent {...props} graders={gradersProp} />)

        const input = document.querySelector('#graders') as HTMLInputElement
        await user.click(input)

        const graderNames = graders.map((grader: any) => grader.name)
        const graderOption = Array.from(document.getElementsByTagName('span')).find(span =>
          graderNames.includes(span.textContent),
        )

        if (graderOption) {
          await user.click(graderOption)
          expect(props.getSearchOptions).toHaveBeenCalledWith('graders', graders[0].name)
        }
      })

      test('selecting a student from options calls getSearchOptions', async function () {
        const user = userEvent.setup()
        const studentsProp = {
          fetchStatus: 'success',
          items: students,
          nextPage: '',
        }
        render(<SearchFormComponent {...props} students={studentsProp} />)

        const input = document.querySelector('#students') as HTMLInputElement
        await user.click(input)

        const studentNames = students.map((student: any) => student.name)
        const studentOption = Array.from(document.getElementsByTagName('span')).find(span =>
          studentNames.includes(span.textContent),
        )

        if (studentOption) {
          await user.click(studentOption)
          expect(props.getSearchOptions).toHaveBeenCalledWith('students', students[0].name)
        }
      })

      test('selecting an assignment from options calls getSearchOptions', async function () {
        const user = userEvent.setup()
        const assignmentsProp = {
          fetchStatus: 'success',
          items: assignments,
          nextPage: '',
        }
        render(<SearchFormComponent {...props} assignments={assignmentsProp} />)

        const input = document.querySelector('#assignments') as HTMLInputElement
        await user.click(input)

        const assignmentNames = assignments.map((assignment: any) => assignment.name)
        const assignmentOption = Array.from(document.getElementsByTagName('span')).find(span =>
          assignmentNames.includes(span.textContent),
        )

        if (assignmentOption) {
          await user.click(assignmentOption)
          expect(props.getSearchOptions).toHaveBeenCalledWith('assignments', assignments[0].name)
        }
      })

      describe('SearchForm "Show Final Grade Overrides Only" checkbox', () => {
        describe('when the OVERRIDE_GRADES_ENABLED environment variable is set to true', () => {
          const assignmentData = {
            fetchStatus: 'success',
            items: [{id: '1', name: 'Just an assignment'}],
            nextPage: '',
          }

          beforeEach(() => {
            // @ts-expect-error
            window.ENV = {OVERRIDE_GRADES_ENABLED: true}
          })

          test('is shown', () => {
            render(<SearchFormComponent {...defaultProps()} />)
            expect(document.querySelector('#show_final_grade_overrides_only')).toBeInTheDocument()
          })

          test('calls clearSearchOptions when checked', async () => {
            const user = userEvent.setup()
            const mockClearSearchOptions = jest.fn()
            render(
              <SearchFormComponent
                {...defaultProps()}
                assignments={assignmentData}
                clearSearchOptions={mockClearSearchOptions}
              />,
            )

            const checkbox = document.querySelector(
              '#show_final_grade_overrides_only',
            ) as HTMLInputElement
            await user.click(checkbox)

            expect(mockClearSearchOptions).toHaveBeenCalledWith('assignments')
          })
        })

        test('is not shown if the OVERRIDE_GRADES_ENABLED environment variable is set to false', () => {
          // @ts-expect-error
          window.ENV = {OVERRIDE_GRADES_ENABLED: false}
          mountComponent()
          expect(document.querySelector('#show_final_grade_overrides_only')).not.toBeInTheDocument()
        })
      })
    })
  })
})
