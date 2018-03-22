/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import {Simulate} from 'react-addons-test-utils'
import $ from 'jquery'
import GradingStandard from 'jsx/grading/gradingStandard'

QUnit.module('GradingStandard not being edited', {
  setup() {
    this.props = {
      key: 1,
      standard: {
        id: 1,
        title: 'Test Grading Standard',
        data: [['A', 0.92], ['A-', 0.9], ['F', 0]]
      },
      permissions: {manage: true},
      editing: false,
      justAdded: false,
      othersEditing: false,
      round(number) {
        return Math.round(number * 100) / 100
      },
      onSetEditingStatus() {},
      onDeleteGradingStandard() {},
      onSaveGradingStandard() {}
    }
    this.mountPoint = $('<div>').appendTo('#fixtures')[0]
    const GradingStandardElement = <GradingStandard {...this.props} />
    this.gradingStandard = ReactDOM.render(GradingStandardElement, this.mountPoint)
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(this.mountPoint)
    $('#fixtures').empty()
  }
})

test('returns false for assessedAssignment', function() {
  deepEqual(this.gradingStandard.assessedAssignment(), false)
})

test('renders the correct title', function() {
  // 'Grading standard title' is wrapped in a screenreader-only span that this
  // test suite does not ignore. 'Grading standadr title' is not actually displayed
  deepEqual(
    this.gradingStandard.refs.title.textContent,
    'Grading standard titleTest Grading Standard'
  )
})

test('renders the correct id name', function() {
  deepEqual(this.gradingStandard.renderIdNames(), 'grading_standard_1')
})

test('renders the edit button', function() {
  ok(this.gradingStandard.refs.editButton)
})

test('calls onSetEditingStatus when edit button is clicked', function() {
  const setEditingStatus = this.spy(this.props, 'onSetEditingStatus')
  const GradingStandardElement = <GradingStandard {...this.props} />
  this.gradingStandard = ReactDOM.render(GradingStandardElement, this.mountPoint)
  Simulate.click(this.gradingStandard.refs.editButton)
  ok(setEditingStatus.calledOnce)
  return setEditingStatus.restore()
})

test('renders the delete button', function() {
  ok(this.gradingStandard.refs.deleteButton)
})

test('calls onDeleteGradingStandard when delete button is clicked', function() {
  const deleteGradingStandard = this.spy(this.props, 'onDeleteGradingStandard')
  const GradingStandardElement = <GradingStandard {...this.props} />
  this.gradingStandard = ReactDOM.render(GradingStandardElement, this.mountPoint)
  Simulate.click(this.gradingStandard.refs.deleteButton)
  ok(deleteGradingStandard.calledOnce)
  return deleteGradingStandard.restore()
})

test('does not show a message about not being able to manage', function() {
  deepEqual(this.gradingStandard.refs.cannotManageMessage, undefined)
})

test('does not show the save button', function() {
  deepEqual(this.gradingStandard.refs.saveButton, undefined)
})

test('does not show the cancel button', function() {
  deepEqual(this.gradingStandard.refs.cancelButton, undefined)
})

QUnit.module("GradingStandard without 'manage' permissions", {
  setup() {
    const props = {
      key: 1,
      standard: {
        id: 1,
        title: 'Test Grading Standard',
        data: [['A', 0.92], ['A-', 0.9], ['F', 0]],
        context_type: 'Account'
      },
      permissions: {manage: false},
      editing: false,
      justAdded: false,
      othersEditing: false,
      round(number) {
        return Math.round(number * 100) / 100
      },
      onSetEditingStatus() {},
      onDeleteGradingStandard() {},
      onSaveGradingStandard() {}
    }
    const GradingStandardElement = <GradingStandard {...props} />
    this.gradingStandard = ReactDOM.render(
      GradingStandardElement,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.gradingStandard).parentNode)
    $('#fixtures').empty()
  }
})

test('displays a cannot manage message', function() {
  ok(this.gradingStandard.refs.cannotManageMessage)
})

test('disables edit and delete buttons', function() {
  ok(this.gradingStandard.refs.disabledButtons)
})

QUnit.module('GradingStandard being edited', {
  setup() {
    this.props = {
      key: 1,
      standard: {
        id: 1,
        title: 'Test Grading Standard',
        data: [['A', 0.92], ['A-', 0.9], ['F', 0]]
      },
      permissions: {manage: true},
      editing: true,
      justAdded: false,
      othersEditing: false,
      round(number) {
        return Math.round(number * 100) / 100
      },
      onSetEditingStatus() {},
      onDeleteGradingStandard() {},
      onSaveGradingStandard: sinon.spy()
    }
    this.mountPoint = $('<div>').appendTo('#fixtures')[0]
    const GradingStandardElement = <GradingStandard {...this.props} />
    this.gradingStandard = ReactDOM.render(GradingStandardElement, this.mountPoint)
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(this.mountPoint)
  }
})

test('does not render the edit button', function() {
  deepEqual(this.gradingStandard.refs.editButton, undefined)
})

test('does not render the delete button', function() {
  deepEqual(this.gradingStandard.refs.deleteButton, undefined)
})

test('renders the save button', function() {
  ok(this.gradingStandard.refs.saveButton)
})

test('rowNamesAreValid() returns true with non-empty, unique row names', function() {
  deepEqual(this.gradingStandard.rowNamesAreValid(), true)
})

test('rowDataIsValid() returns true with non-empty, unique, non-overlapping row values', function() {
  deepEqual(this.gradingStandard.rowDataIsValid(), true)
})

test('calls onSaveGradingStandard save button is clicked', function() {
  Simulate.click(this.gradingStandard.refs.saveButton)
  ok(this.gradingStandard.props.onSaveGradingStandard.calledOnce)
})

test('sets the state to saving when the save button is clicked', function() {
  deepEqual(this.gradingStandard.state.saving, false)
  Simulate.click(this.gradingStandard.refs.saveButton)
  deepEqual(this.gradingStandard.state.saving, true)
})

test('shows the cancel button', function() {
  ok(this.gradingStandard.refs.cancelButton)
})

test('calls onSetEditingStatus when the cancel button is clicked', function() {
  const setEditingStatus = this.spy(this.props, 'onSetEditingStatus')
  const GradingStandardElement = <GradingStandard {...this.props} />
  this.gradingStandard = ReactDOM.render(GradingStandardElement, this.mountPoint)
  Simulate.click(this.gradingStandard.refs.cancelButton)
  ok(setEditingStatus.calledOnce)
  return setEditingStatus.restore()
})

test('deletes the correct row on the editingStandard when deleteDataRow is called', function() {
  this.gradingStandard.deleteDataRow(1)
  deepEqual(this.gradingStandard.state.editingStandard.data, [['A', 0.92], ['F', 0]])
})

test('does not delete the row if it is the last data row remaining', function() {
  this.gradingStandard.deleteDataRow(1)
  deepEqual(this.gradingStandard.state.editingStandard.data, [['A', 0.92], ['F', 0]])
  this.gradingStandard.deleteDataRow(0)
  deepEqual(this.gradingStandard.state.editingStandard.data, [['F', 0]])
  this.gradingStandard.deleteDataRow(0)
  deepEqual(this.gradingStandard.state.editingStandard.data, [['F', 0]])
})

test('inserts the correct row on the editingStandard when insertGradingStandardRow is called', function() {
  this.gradingStandard.insertGradingStandardRow(1)
  deepEqual(this.gradingStandard.state.editingStandard.data, [
    ['A', 0.92],
    ['A-', 0.9],
    ['', ''],
    ['F', 0]
  ])
})

test('changes the title on the editingStandard when title input changes', function() {
  Simulate.change(this.gradingStandard.refs.title, {target: {value: 'Brand new title'}})
  deepEqual(this.gradingStandard.state.editingStandard.title, 'Brand new title')
})

test('changes the min score on the editingStandard when changeRowMinScore is called', function() {
  this.gradingStandard.changeRowMinScore(2, '23')
  deepEqual(this.gradingStandard.state.editingStandard.data[2], ['F', '23'])
})

test('changes the row name on the editingStandard when changeRowName is called', function() {
  this.gradingStandard.changeRowName(2, 'Q')
  deepEqual(this.gradingStandard.state.editingStandard.data[2], ['Q', 0])
})

QUnit.module('GradingStandard being edited with blank names', {
  setup() {
    const props = {
      key: 1,
      standard: {
        id: 1,
        title: 'Test Grading Standard',
        data: [['A', 0.92], ['', 0.9], ['F', 0]]
      },
      permissions: {manage: true},
      editing: true,
      justAdded: false,
      othersEditing: false,
      round(number) {
        return Math.round(number * 100) / 100
      },
      onSetEditingStatus() {},
      onDeleteGradingStandard() {},
      onSaveGradingStandard() {}
    }
    const GradingStandardElement = <GradingStandard {...props} />
    this.gradingStandard = ReactDOM.render(
      GradingStandardElement,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.gradingStandard).parentNode)
    $('#fixtures').empty()
  }
})

test('rowNamesAreValid() returns false with empty row names', function() {
  deepEqual(this.gradingStandard.rowNamesAreValid(), false)
})

test('alerts the user that the input is invalid when they try to save', function() {
  Simulate.click(this.gradingStandard.refs.saveButton)
  ok(this.gradingStandard.refs.invalidStandardAlert)
})

test('shows a messsage describing why the input is invalid', function() {
  Simulate.click(this.gradingStandard.refs.saveButton)
  deepEqual(
    this.gradingStandard.refs.invalidStandardAlert.textContent,
    "Cannot have duplicate or empty row names. Fix the names and try clicking 'Save' again."
  )
})

QUnit.module('GradingStandard being edited with duplicate names', {
  setup() {
    const props = {
      key: 1,
      standard: {
        id: 1,
        title: 'Test Grading Standard',
        data: [['A', 0.92], ['A', 0.9], ['F', 0]]
      },
      permissions: {manage: true},
      editing: true,
      justAdded: false,
      othersEditing: false,
      round(number) {
        return Math.round(number * 100) / 100
      },
      onSetEditingStatus() {},
      onDeleteGradingStandard() {},
      onSaveGradingStandard() {}
    }
    const GradingStandardElement = <GradingStandard {...props} />
    this.gradingStandard = ReactDOM.render(
      GradingStandardElement,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.gradingStandard).parentNode)
    $('#fixtures').empty()
  }
})

test('rowNamesAreValid() returns false with duplicate row names', function() {
  deepEqual(this.gradingStandard.rowNamesAreValid(), false)
})

test('alerts the user that the input is invalid when they try to save', function() {
  Simulate.click(this.gradingStandard.refs.saveButton)
  ok(this.gradingStandard.refs.invalidStandardAlert)
})

test('shows a messsage describing why the input is invalid', function() {
  Simulate.click(this.gradingStandard.refs.saveButton)
  deepEqual(
    this.gradingStandard.refs.invalidStandardAlert.textContent,
    "Cannot have duplicate or empty row names. Fix the names and try clicking 'Save' again."
  )
})

QUnit.module('GradingStandard being edited with empty values', {
  setup() {
    const props = {
      key: 1,
      standard: {
        id: 1,
        title: 'Test Grading Standard',
        data: [['A', 0.92], ['B', 0.9], ['F', '']]
      },
      permissions: {manage: true},
      editing: true,
      justAdded: false,
      othersEditing: false,
      round(number) {
        return Math.round(number * 100) / 100
      },
      onSetEditingStatus() {},
      onDeleteGradingStandard() {},
      onSaveGradingStandard() {}
    }
    const GradingStandardElement = <GradingStandard {...props} />
    this.gradingStandard = ReactDOM.render(
      GradingStandardElement,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.gradingStandard).parentNode)
    $('#fixtures').empty()
  }
})

test('rowDataIsValid() returns false with empty values', function() {
  deepEqual(this.gradingStandard.rowDataIsValid(), false)
})

test('alerts the user that the input is invalid when they try to save', function() {
  Simulate.click(this.gradingStandard.refs.saveButton)
  ok(this.gradingStandard.refs.invalidStandardAlert)
})

test('shows a messsage describing why the input is invalid', function() {
  Simulate.click(this.gradingStandard.refs.saveButton)
  deepEqual(
    this.gradingStandard.refs.invalidStandardAlert.textContent,
    "Cannot have overlapping or empty ranges. Fix the ranges and try clicking 'Save' again."
  )
})

QUnit.module('GradingStandard being edited with duplicate values', {
  setup() {
    const props = {
      key: 1,
      standard: {
        id: 1,
        title: 'Test Grading Standard',
        data: [['A', 0.92], ['B', 0.92], ['F', 0]]
      },
      permissions: {manage: true},
      editing: true,
      justAdded: false,
      othersEditing: false,
      round(number) {
        return Math.round(number * 100) / 100
      },
      onSetEditingStatus() {},
      onDeleteGradingStandard() {},
      onSaveGradingStandard() {}
    }
    const GradingStandardElement = <GradingStandard {...props} />
    this.gradingStandard = ReactDOM.render(
      GradingStandardElement,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.gradingStandard).parentNode)
    $('#fixtures').empty()
  }
})

test('rowDataIsValid() returns false with duplicate values', function() {
  deepEqual(this.gradingStandard.rowDataIsValid(), false)
})

test('alerts the user that the input is invalid when they try to save', function() {
  Simulate.click(this.gradingStandard.refs.saveButton)
  ok(this.gradingStandard.refs.invalidStandardAlert)
})

test('shows a messsage describing why the input is invalid', function() {
  Simulate.click(this.gradingStandard.refs.saveButton)
  deepEqual(
    this.gradingStandard.refs.invalidStandardAlert.textContent,
    "Cannot have overlapping or empty ranges. Fix the ranges and try clicking 'Save' again."
  )
})

QUnit.module('GradingStandard being edited with values that round to the same number', {
  setup() {
    const props = {
      key: 1,
      standard: {
        id: 1,
        title: 'Test Grading Standard',
        data: [['A', 0.92], ['B', 0.91996], ['F', 0]]
      },
      permissions: {manage: true},
      editing: true,
      justAdded: false,
      othersEditing: false,
      round(number) {
        return Math.round(number * 100) / 100
      },
      onSetEditingStatus() {},
      onDeleteGradingStandard() {},
      onSaveGradingStandard() {}
    }
    const GradingStandardElement = <GradingStandard {...props} />
    this.gradingStandard = ReactDOM.render(
      GradingStandardElement,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.gradingStandard).parentNode)
    $('#fixtures').empty()
  }
})

test('rowDataIsValid() returns false with if values round to the same number (91.996 rounds to 92)', function() {
  deepEqual(this.gradingStandard.rowDataIsValid(), false)
})

test('alerts the user that the input is invalid when they try to save', function() {
  Simulate.click(this.gradingStandard.refs.saveButton)
  ok(this.gradingStandard.refs.invalidStandardAlert)
})

test('shows a messsage describing why the input is invalid', function() {
  Simulate.click(this.gradingStandard.refs.saveButton)
  deepEqual(
    this.gradingStandard.refs.invalidStandardAlert.textContent,
    "Cannot have overlapping or empty ranges. Fix the ranges and try clicking 'Save' again."
  )
})

QUnit.module('GradingStandard being edited with overlapping values', {
  setup() {
    const props = {
      key: 1,
      standard: {
        id: 1,
        title: 'Test Grading Standard',
        data: [['A', 0.92], ['B', 0.93], ['F', 0]]
      },
      permissions: {manage: true},
      editing: true,
      justAdded: false,
      othersEditing: false,
      round(number) {
        return Math.round(number * 100) / 100
      },
      onSetEditingStatus() {},
      onDeleteGradingStandard() {},
      onSaveGradingStandard() {}
    }
    const GradingStandardElement = <GradingStandard {...props} />
    this.gradingStandard = ReactDOM.render(
      GradingStandardElement,
      $('<div>').appendTo('#fixtures')[0]
    )
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.gradingStandard).parentNode)
    $('#fixtures').empty()
  }
})

test('rowDataIsValid() returns false if scheme values overlap', function() {
  deepEqual(this.gradingStandard.rowDataIsValid(), false)
})

test('alerts the user that the input is invalid when they try to save', function() {
  Simulate.click(this.gradingStandard.refs.saveButton)
  ok(this.gradingStandard.refs.invalidStandardAlert)
})

test('shows a messsage describing why the input is invalid', function() {
  Simulate.click(this.gradingStandard.refs.saveButton)
  deepEqual(
    this.gradingStandard.refs.invalidStandardAlert.textContent,
    "Cannot have overlapping or empty ranges. Fix the ranges and try clicking 'Save' again."
  )
})
