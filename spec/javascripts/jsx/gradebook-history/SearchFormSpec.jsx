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

import React from 'react'
import {mount, shallow} from 'enzyme'
import {SearchFormComponent} from 'ui/features/gradebook_history/react/SearchForm'
import {Button} from '@instructure/ui-buttons'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import CanvasAsyncSelect from '@canvas/instui-bindings/react/AsyncSelect'
import {FormFieldGroup} from '@instructure/ui-form-field'
import Fixtures from './Fixtures'
import fakeENV from 'helpers/fakeENV'

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
  shallow(<SearchFormComponent {...defaultProps()} {...props} />)

QUnit.module('SearchForm', {
  setup() {
    this.wrapper = mountComponent()
  },

  teardown() {
    this.wrapper.unmount()
  },
})

test('has a form field group', function () {
  ok(this.wrapper.find(FormFieldGroup).exists())
})

test('has an Autocomplete with id #graders', function () {
  const input = this.wrapper.find('#graders')
  equal(input.length, 1)
  ok(input.is(CanvasAsyncSelect))
})

test('has an Autocomplete with id #students', function () {
  const input = this.wrapper.find('#students')
  equal(input.length, 1)
  ok(input.is(CanvasAsyncSelect))
})

test('has an Autocomplete with id #assignments', function () {
  const input = this.wrapper.find('#assignments')
  equal(input.length, 1)
  ok(input.is(CanvasAsyncSelect))
})

test('has date pickers for from date and to date', function () {
  const inputs = this.wrapper.find(CanvasDateInput)
  equal(inputs.length, 2)
  ok(inputs.every(CanvasDateInput))
})

test('has a Button for submitting', function () {
  ok(this.wrapper.find(Button).exists())
})

test('disables the submit button if To date is before From date', function () {
  this.wrapper.setState(
    {
      selected: {
        from: {value: '2017-05-02T00:00:00-05:00'},
        to: {value: '2017-05-01T00:00:00-05:00'},
      },
    },
    () => {
      const button = this.wrapper.find(Button)
      ok(button.props().disabled)
    }
  )
})

test('does not disable the submit button if To date is after From date', function () {
  this.wrapper.setState(
    {
      selected: {
        from: {value: '2017-05-01T00:00:00-05:00'},
        to: {value: '2017-05-02T00:00:00-05:00'},
      },
    },
    () => {
      const button = this.wrapper.find(Button)
      notOk(button.props().disabled)
    }
  )
})

test('does not disable the submit button when there are no dates selected', function () {
  const {from, to} = this.wrapper.state().selected
  const button = this.wrapper.find(Button)
  notOk(from.value)
  notOk(to.value)
  notOk(button.props().disabled)
})

test('does not disable the submit button when only from date is entered', function () {
  this.wrapper.setState(
    {
      selected: {
        from: {value: '1994-04-08T00:00:00-05:00'},
        to: {value: ''},
      },
    },
    () => {
      const button = this.wrapper.find(Button)
      notOk(button.props().disabled)
    }
  )
})

test('does not disable the submit button when only to date is entered', function () {
  this.wrapper.setState(
    {
      selected: {
        from: {value: ''},
        to: {value: '2017-05-01T00:00:00-05:00'},
      },
    },
    () => {
      const button = this.wrapper.find(Button)
      notOk(button.props().disabled)
    }
  )
})

test('calls getGradebookHistory prop on mount', () => {
  const props = {getGradebookHistory: sinon.stub()}
  const wrapper = mount(<SearchFormComponent {...defaultProps()} {...props} />)
  strictEqual(props.getGradebookHistory.callCount, 1)
  wrapper.unmount()
})

QUnit.module('SearchForm when button is clicked', {
  setup() {
    this.props = {getGradebookHistory: sinon.stub()}
    this.wrapper = mountComponent(this.props)
  },

  teardown() {
    this.wrapper.unmount()
  },
})

test('dispatches with the state of input', function () {
  const selected = {
    assignment: '1',
    grader: '2',
    student: '3',
    from: {value: '2017-05-20T00:00:00-05:00'},
    to: {value: '2017-05-21T00:00:00-05:00'},
  }

  this.wrapper.setState(
    {
      selected,
    },
    () => {
      this.wrapper.find(Button).simulate('click')
      deepEqual(this.props.getGradebookHistory.lastCall.args[0], selected)
    }
  )
})

QUnit.module('SearchForm Autocomplete options', {
  setup() {
    this.props = {...defaultProps(), getSearchOptions: sinon.stub()}
    this.assignments = Fixtures.assignmentArray()
    this.graders = Fixtures.userArray()
    this.students = Fixtures.userArray()
    this.wrapper = mount(<SearchFormComponent {...this.props} />, {
      attachTo: document.getElementById('fixtures'),
    })
  },

  teardown() {
    this.wrapper.unmount()
  },
})

test('selecting a grader from options sets state to its id', function () {
  this.wrapper.setProps({
    graders: {
      fetchStatus: 'success',
      items: this.graders,
      nextPage: '',
    },
  })

  const input = this.wrapper.find('#graders').last().instance()
  input.click()

  const graderNames = this.graders.map(grader => grader.name)
  ;[...document.getElementsByTagName('span')]
    .find(span => graderNames.includes(span.textContent))
    .click()

  strictEqual(this.wrapper.state().selected.grader, this.graders[0].id)
})

test('selecting a student from options sets state to its id', function () {
  this.wrapper.setProps({
    students: {
      fetchStatus: 'success',
      items: this.students,
      nextPage: '',
    },
  })

  const input = this.wrapper.find('#students').last().instance()
  input.click()
  const studentNames = this.students.map(student => student.name)

  ;[...document.getElementsByTagName('span')]
    .find(span => studentNames.includes(span.textContent))
    .click()
  strictEqual(this.wrapper.state().selected.student, this.students[0].id)
})

test('selecting an assignment from options sets state to its id', function () {
  this.wrapper.setProps({
    assignments: {
      fetchStatus: 'success',
      items: this.assignments,
      nextPage: '',
    },
  })

  const input = this.wrapper.find('#assignments').last().instance()
  input.click()

  const assignmentNames = this.assignments.map(assignment => assignment.name)
  ;[...document.getElementsByTagName('span')]
    .find(span => assignmentNames.includes(span.textContent))
    .click()

  strictEqual(this.wrapper.state().selected.assignment, this.assignments[0].id)
})

test('selecting an assignment from options sets that option in the list', function () {
  this.wrapper.setProps({
    assignments: {
      fetchStatus: 'success',
      items: this.assignments,
      nextPage: '',
    },
  })

  const input = this.wrapper.find('#assignments').last().instance()
  input.click()

  const assignmentNames = this.assignments.map(assignment => assignment.name)
  ;[...document.getElementsByTagName('span')]
    .find(span => assignmentNames.includes(span.textContent))
    .click()

  ok(this.props.getSearchOptions.called)
  strictEqual(this.props.getSearchOptions.firstCall.args[0], 'assignments')
  strictEqual(this.props.getSearchOptions.firstCall.args[1], this.assignments[0].name)
})

test('selecting an assignment from options sets showFinalGradeOverridesOnly to false', function () {
  this.wrapper.setState({
    selected: {
      from: {value: ''},
      showFinalGradeOverridesOnly: true,
      to: {value: '2017-05-01T00:00:00-05:00'},
    },
  })

  this.wrapper.setProps({
    assignments: {
      fetchStatus: 'success',
      items: this.assignments,
      nextPage: '',
    },
  })

  const input = this.wrapper.find('#assignments').last().instance()
  input.click()

  const assignmentNames = this.assignments.map(assignment => assignment.name)
  ;[...document.getElementsByTagName('span')]
    .find(span => assignmentNames.includes(span.textContent))
    .click()

  strictEqual(this.wrapper.state().selected.showFinalGradeOverridesOnly, false)
})

test('selecting a grader from options sets that option in the list', function () {
  this.wrapper.setProps({
    graders: {
      fetchStatus: 'success',
      items: this.graders,
      nextPage: '',
    },
  })

  const input = this.wrapper.find('#graders').last().instance()
  input.click()

  const graderNames = this.graders.map(grader => grader.name)
  ;[...document.getElementsByTagName('span')]
    .find(span => graderNames.includes(span.textContent))
    .click()

  ok(this.props.getSearchOptions.called)
  strictEqual(this.props.getSearchOptions.firstCall.args[0], 'graders')
  strictEqual(this.props.getSearchOptions.firstCall.args[1], this.graders[0].name)
})

test('selecting a student from options sets that option in the list', function () {
  this.wrapper.setProps({
    students: {
      fetchStatus: 'success',
      items: this.students,
      nextPage: '',
    },
  })

  const input = this.wrapper.find('#students').last().instance()
  input.click()

  const studentNames = this.students.map(student => student.name)

  ;[...document.getElementsByTagName('span')]
    .find(span => studentNames.includes(span.textContent))
    .click()
  ok(this.props.getSearchOptions.called)
  strictEqual(this.props.getSearchOptions.firstCall.args[0], 'students')
  strictEqual(this.props.getSearchOptions.firstCall.args[1], this.students[0].name)
})

QUnit.module('SearchForm "Show Final Grade Overrides Only" checkbox', () => {
  QUnit.module('when the OVERRIDE_GRADES_ENABLED environment variable is set to true', hooks => {
    const clickOverrideGradeCheckbox = wrapper =>
      wrapper.find('#show_final_grade_overrides_only').last().simulate('change')

    const fullMount = (props = {}) => mount(<SearchFormComponent {...defaultProps()} {...props} />)

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

    hooks.beforeEach(() => {
      fakeENV.setup({OVERRIDE_GRADES_ENABLED: true})
    })

    hooks.afterEach(() => {
      fakeENV.teardown()
    })

    test('is shown', () => {
      const wrapper = fullMount()
      ok(wrapper.exists('#show_final_grade_overrides_only'))
      wrapper.unmount()
    })

    test('clears the text of the Assignment input when enabled', () => {
      const wrapper = fullMount({assignments: assignmentData})
      wrapper.setState(initialState)

      wrapper.find('input#assignments').instance().value = 'a search string'
      clickOverrideGradeCheckbox(wrapper)

      strictEqual(wrapper.find('input#assignments').instance().value, '')
      wrapper.unmount()
    })

    test('sets the value of showFinalGradeOverridesOnly to the corresponding value when clicked', () => {
      const wrapper = fullMount()
      clickOverrideGradeCheckbox(wrapper)

      strictEqual(wrapper.state().selected.showFinalGradeOverridesOnly, true)
      wrapper.unmount()
    })

    test('clears the selected assignment when checked', () => {
      const wrapper = fullMount({assignments: assignmentData})
      wrapper.setState(initialState)

      clickOverrideGradeCheckbox(wrapper)

      strictEqual(wrapper.state().selected.assignment, '')
      wrapper.unmount()
    })

    test('calls clearSearchOptions on the list of assignments when checked', () => {
      const wrapper = fullMount({assignments: assignmentData, clearSearchOptions: sinon.stub()})
      wrapper.setState(initialState)

      clickOverrideGradeCheckbox(wrapper)

      const [target] = wrapper.prop('clearSearchOptions').firstCall.args
      strictEqual(target, 'assignments')
      wrapper.unmount()
    })
  })

  test('is not shown if the OVERRIDE_GRADES_ENABLED environment variable is set to false', () => {
    fakeENV.setup({OVERRIDE_GRADES_ENABLED: false})

    const wrapper = mountComponent()
    notOk(wrapper.exists('#show_final_grade_overrides_only'))
    wrapper.unmount()

    fakeENV.teardown()
  })
})
