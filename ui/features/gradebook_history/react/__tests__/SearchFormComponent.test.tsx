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
import {shallow} from 'enzyme'
import {render} from '@testing-library/react'
import {SearchFormComponent} from '../SearchForm'
import {Button} from '@instructure/ui-buttons'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
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
  // @ts-expect-error
  shallow(<SearchFormComponent {...defaultProps()} {...props} />)

describe('SearchForm', () => {
  let wrapper: any
  beforeEach(() => {
    wrapper = mountComponent()
  })

  test('has a form field group', function () {
    expect(wrapper.find(FormFieldGroup).exists()).toBeTruthy()
  })

  test('has an Autocomplete with id #graders', function () {
    const input = wrapper.find('#graders')
    expect(input.exists()).toBeTruthy()
    expect(input.is(CanvasAsyncSelect)).toBeTruthy()
  })

  test('has an Autocomplete with id #students', function () {
    const input = wrapper.find('#students')
    expect(input.exists()).toBeTruthy()
    expect(input.is(CanvasAsyncSelect)).toBeTruthy()
  })

  test('has an Autocomplete with id #assignments', function () {
    const input = wrapper.find('#assignments')
    expect(input.exists()).toBeTruthy()
    expect(input.is(CanvasAsyncSelect)).toBeTruthy()
  })

  test('has date pickers for from date and to date', function () {
    const inputs = wrapper.find(CanvasDateInput)
    expect(inputs.length).toBe(2)
    expect(inputs.every(CanvasDateInput)).toBeTruthy()
  })

  test('has a Button for submitting', function () {
    expect(wrapper.find(Button).exists()).toBeTruthy()
  })

  test('disables the submit button if To date is before From date', function () {
    wrapper.setState(
      {
        selected: {
          from: {value: '2017-05-02T00:00:00-05:00'},
          to: {value: '2017-05-01T00:00:00-05:00'},
        },
      },
      () => {
        const button = wrapper.find(Button)
        expect(button.props().disabled).toBeTruthy()
      }
    )
  })

  test('does not disable the submit button if To date is after From date', function () {
    wrapper.setState(
      {
        selected: {
          from: {value: '2017-05-01T00:00:00-05:00'},
          to: {value: '2017-05-02T00:00:00-05:00'},
        },
      },
      () => {
        const button = wrapper.find(Button)
        expect(button.props().disabled).toBeFalsy()
      }
    )
  })

  test('does not disable the submit button when there are no dates selected', function () {
    const {from, to} = wrapper.state().selected
    const button = wrapper.find(Button)
    expect(from.value).toBeFalsy()
    expect(to.value).toBeFalsy()
    expect(button.props().disabled).toBeFalsy()
  })

  test('does not disable the submit button when only from date is entered', function () {
    wrapper.setState(
      {
        selected: {
          from: {value: '1994-04-08T00:00:00-05:00'},
          to: {value: ''},
        },
      },
      () => {
        const button = wrapper.find(Button)
        expect(button.props().disabled).toBeFalsy()
      }
    )
  })

  test('does not disable the submit button when only to date is entered', function () {
    wrapper.setState(
      {
        selected: {
          from: {value: ''},
          to: {value: '2017-05-01T00:00:00-05:00'},
        },
      },
      () => {
        const button = wrapper.find(Button)
        expect(button.props().disabled).toBeFalsy()
      }
    )
  })

  test('calls getGradebookHistory prop on mount', () => {
    const props = {getGradebookHistory: jest.fn()}
    render(<SearchFormComponent {...defaultProps()} {...props} />)
    expect(props.getGradebookHistory).toHaveBeenCalledTimes(1)
  })

  describe('SearchForm when button is clicked', () => {
    let props: any
    beforeEach(() => {
      props = {getGradebookHistory: jest.fn()}
      wrapper = mountComponent(props)
    })
    test('dispatches with the state of input', function () {
      const selected = {
        assignment: '1',
        grader: '2',
        student: '3',
        from: {value: '2017-05-20T00:00:00-05:00'},
        to: {value: '2017-05-21T00:00:00-05:00'},
      }

      wrapper.setState(
        {
          selected,
        },
        () => {
          wrapper.find(Button).simulate('click')
          expect(props.getGradebookHistory).toHaveBeenCalledWith(selected)
        }
      )
    })

    describe('SearchForm Autocomplete options', () => {
      let assignments: any
      let graders: any
      let students: any
      let ref: React.RefObject<any>

      beforeEach(() => {
        props = {...defaultProps(), getSearchOptions: jest.fn()}
        assignments = Fixtures.assignmentArray()
        graders = Fixtures.userArray()
        students = Fixtures.userArray()
        ref = React.createRef()
        wrapper = render(<SearchFormComponent {...props} ref={ref} />)
      })

      test('selecting a grader from options sets state to its id', function () {
        const gradersProp = {
          fetchStatus: 'success',
          items: graders,
          nextPage: '',
        }
        wrapper.rerender(<SearchFormComponent {...props} graders={gradersProp} ref={ref} />)

        const inputs = wrapper.container.querySelectorAll('#graders')
        const input = inputs[inputs.length - 1]
        input.click()

        const graderNames = graders.map((grader: any) => grader.name)
        Array.from(document.getElementsByTagName('span'))
          .find(span => graderNames.includes(span.textContent))
          ?.click()
        expect(ref.current.state.selected.grader).toBe(graders[0].id)
      })

      test('selecting a student from options sets state to its id', function () {
        const studentsProp = {
          fetchStatus: 'success',
          items: students,
          nextPage: '',
        }
        wrapper.rerender(<SearchFormComponent {...props} students={studentsProp} ref={ref} />)

        const inputs = wrapper.container.querySelectorAll('#students')
        const input = inputs[inputs.length - 1]
        input.click()
        const studentNames = students.map((student: any) => student.name)
        Array.from(document.getElementsByTagName('span'))
          .find(span => studentNames.includes(span.textContent))
          ?.click()
        expect(ref.current.state.selected.student).toBe(students[0].id)
      })

      test('selecting an assignment from options sets state to its id', function () {
        const assignmentsProp = {
          fetchStatus: 'success',
          items: assignments,
          nextPage: '',
        }
        wrapper.rerender(<SearchFormComponent {...props} assignments={assignmentsProp} ref={ref} />)

        const inputs = wrapper.container.querySelectorAll('#assignments')
        const input = inputs[inputs.length - 1]
        input.click()

        const assignmentNames = assignments.map((assignment: any) => assignment.name)
        Array.from(document.getElementsByTagName('span'))
          .find(span => assignmentNames.includes(span.textContent))
          ?.click()

        expect(ref.current.state.selected.assignment).toBe(assignments[0].id)
      })

      test('selecting an assignment from options sets that option in the list', function () {
        const assignmentsProp = {
          fetchStatus: 'success',
          items: assignments,
          nextPage: '',
        }
        wrapper.rerender(<SearchFormComponent {...props} assignments={assignmentsProp} ref={ref} />)

        const inputs = wrapper.container.querySelectorAll('#assignments')
        const input = inputs[inputs.length - 1]
        input.click()

        const assignmentNames = assignments.map((assignment: any) => assignment.name)
        Array.from(document.getElementsByTagName('span'))
          .find(span => assignmentNames.includes(span.textContent))
          ?.click()

        expect(props.getSearchOptions).toHaveBeenCalledTimes(1)
        expect(props.getSearchOptions).toHaveBeenCalledWith('assignments', assignments[0].name)
      })

      test('selecting an assignment from options sets showFinalGradeOverridesOnly to false', function () {
        ref.current.setState({
          selected: {
            from: {value: ''},
            showFinalGradeOverridesOnly: true,
            to: {value: '2017-05-01T00:00:00-05:00'},
          },
        })
        const assignmentsProp = {
          fetchStatus: 'success',
          items: assignments,
          nextPage: '',
        }
        wrapper.rerender(<SearchFormComponent {...props} assignments={assignmentsProp} ref={ref} />)

        const inputs = wrapper.container.querySelectorAll('#assignments')
        const input = inputs[inputs.length - 1]
        input.click()

        const assignmentNames = assignments.map((assignment: any) => assignment.name)
        Array.from(document.getElementsByTagName('span'))
          .find(span => assignmentNames.includes(span.textContent))
          ?.click()

        expect(ref.current.state.selected.showFinalGradeOverridesOnly).toBeFalsy()
      })

      test('selecting a grader from options sets that option in the list', function () {
        const gradersProp = {
          fetchStatus: 'success',
          items: graders,
          nextPage: '',
        }
        wrapper.rerender(<SearchFormComponent {...props} graders={gradersProp} ref={ref} />)

        const inputs = wrapper.container.querySelectorAll('#graders')
        const input = inputs[inputs.length - 1]
        input.click()

        const graderNames = graders.map((grader: any) => grader.name)
        Array.from(document.getElementsByTagName('span'))
          .find(span => graderNames.includes(span.textContent))
          ?.click()

        expect(props.getSearchOptions).toHaveBeenCalledTimes(1)
        expect(props.getSearchOptions).toHaveBeenCalledWith('graders', graders[0].name)
      })

      test('selecting a student from options sets that option in the list', function () {
        const studentsProp = {
          fetchStatus: 'success',
          items: students,
          nextPage: '',
        }
        wrapper.rerender(<SearchFormComponent {...props} students={studentsProp} ref={ref} />)

        const inputs = wrapper.container.querySelectorAll('#students')
        const input = inputs[inputs.length - 1]
        input.click()

        const studentNames = students.map((student: any) => student.name)
        Array.from(document.getElementsByTagName('span'))
          .find(span => studentNames.includes(span.textContent))
          ?.click()

        expect(props.getSearchOptions).toHaveBeenCalledTimes(1)
        expect(props.getSearchOptions).toHaveBeenCalledWith('students', students[0].name)
      })

      describe('SearchForm "Show Final Grade Overrides Only" checkbox', () => {
        describe('when the OVERRIDE_GRADES_ENABLED environment variable is set to true', () => {
          const clickOverrideGradeCheckbox = (_wrapper: any) => {
            const overrides = _wrapper.container.querySelectorAll(
              '#show_final_grade_overrides_only'
            )
            overrides[overrides.length - 1].click()
          }

          const fullMount = (_props = {}) => {
            ref = React.createRef()
            return render(<SearchFormComponent {...defaultProps()} {..._props} ref={ref} />)
          }

          const assignmentData = {
            fetchStatus: 'success',
            items: [{id: '1', name: 'Just an assignment'}],
            nextPage: '',
          }

          const initialState = {
            selected: {
              assignment: '1',
              from: {value: '2017-05-02T00:00:00-05:00'},
              showFinalGradeOverridesOnly: false,
              to: {value: '2017-05-01T00:00:00-05:00'},
            },
          }

          beforeEach(() => {
            // @ts-expect-error
            window.ENV = {OVERRIDE_GRADES_ENABLED: true}
          })

          test('is shown', () => {
            const _wrapper = fullMount()
            expect(
              _wrapper.container.querySelector('#show_final_grade_overrides_only')
            ).toBeTruthy()
          })

          test('clears the text of the Assignment input when enabled', () => {
            const _wrapper = fullMount({assignments: assignmentData})
            ref.current.setState(initialState)

            const el = _wrapper.container.querySelector('input#assignments') as HTMLInputElement
            el.value = 'a search string'
            clickOverrideGradeCheckbox(_wrapper)

            expect(el.value).toBe('')
          })

          test('sets the value of showFinalGradeOverridesOnly to the corresponding value when clicked', () => {
            const _wrapper = fullMount()
            clickOverrideGradeCheckbox(_wrapper)

            expect(ref.current.state.selected.showFinalGradeOverridesOnly).toBeTruthy()
          })

          test('clears the selected assignment when checked', () => {
            const _wrapper = fullMount({assignments: assignmentData})
            ref.current.setState(initialState)

            clickOverrideGradeCheckbox(_wrapper)

            expect(ref.current.state.selected.assignment).toBe('')
          })

          test('calls clearSearchOptions on the list of assignments when checked', () => {
            const _wrapper = fullMount({assignments: assignmentData, clearSearchOptions: jest.fn()})
            ref.current.setState(initialState)
            clickOverrideGradeCheckbox(_wrapper)
            expect(ref.current.props.clearSearchOptions).toHaveBeenCalledWith('assignments')
          })
        })

        test('is not shown if the OVERRIDE_GRADES_ENABLED environment variable is set to false', () => {
          // @ts-expect-error
          window.ENV = {OVERRIDE_GRADES_ENABLED: false}
          const _wrapper = mountComponent()
          expect(_wrapper.exists('#show_final_grade_overrides_only')).toBeFalsy()
        })
      })
    })
  })
})
