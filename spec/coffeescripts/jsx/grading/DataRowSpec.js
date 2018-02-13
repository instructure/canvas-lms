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
import DataRow from 'jsx/grading/dataRow'

QUnit.module('DataRow not being edited, without a sibling', {
  setup() {
    const props = {
      key: 0,
      uniqueId: 0,
      row: ['A', 92.346],
      editing: false,
      round: number => Math.round(number * 100) / 100
    }
    const DataRowElement = <DataRow {...props} />
    this.dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.dataRow).parentNode)
    $('#fixtures').empty()
  }
})

test('renders in "view" mode (as opposed to "edit" mode)', function() {
  ok(this.dataRow.refs.viewContainer)
})

test('getRowData() returns the correct name', function() {
  deepEqual(this.dataRow.getRowData().name, 'A')
})

test('getRowData() sets max score to 100 if there is no sibling row', function() {
  deepEqual(this.dataRow.getRowData().maxScore, 100)
})

test('renderMinScore() rounds the score if not in editing mode', function() {
  deepEqual(this.dataRow.renderMinScore(), '92.35')
})

test("renderMaxScore() returns a max score of 100 without a '<' sign", function() {
  deepEqual(this.dataRow.renderMaxScore(), '100')
})

QUnit.module('DataRow being edited', {
  setup() {
    this.props = {
      key: 0,
      uniqueId: 0,
      row: ['A', 92.346],
      editing: true,
      round: number => Math.round(number * 100) / 100,
      onRowMinScoreChange() {},
      onRowNameChange() {},
      onDeleteRow() {}
    }
    const DataRowElement = <DataRow {...this.props} />
    this.dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.dataRow).parentNode)
    $('#fixtures').empty()
  }
})

test('renders in "edit" mode (as opposed to "view" mode)', function() {
  ok(this.dataRow.refs.editContainer)
})

test('on change, accepts arbitrary input and saves to state', function() {
  const changeMinScore = this.spy(this.props, 'onRowMinScoreChange')
  const DataRowElement = <DataRow {...this.props} />
  this.dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
  Simulate.change(this.dataRow.minScoreInput, {target: {value: 'A'}})
  deepEqual(this.dataRow.renderMinScore(), 'A')
  Simulate.change(this.dataRow.minScoreInput, {target: {value: '*&@%!'}})
  deepEqual(this.dataRow.renderMinScore(), '*&@%!')
  Simulate.change(this.dataRow.minScoreInput, {target: {value: '3B'}})
  deepEqual(this.dataRow.renderMinScore(), '3B')
  ok(changeMinScore.notCalled)
  changeMinScore.restore()
})

test('on blur, does not call onRowMinScoreChange if the input parsed value is less than 0', function() {
  const changeMinScore = this.spy(this.props, 'onRowMinScoreChange')
  const DataRowElement = <DataRow {...this.props} />
  this.dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
  Simulate.change(this.dataRow.minScoreInput, {target: {value: '-1'}})
  Simulate.blur(this.dataRow.minScoreInput)
  ok(changeMinScore.notCalled)
  changeMinScore.restore()
})

test('on blur, does not call onRowMinScoreChange if the input parsed value is greater than 100', function() {
  const changeMinScore = this.spy(this.props, 'onRowMinScoreChange')
  const DataRowElement = <DataRow {...this.props} />
  this.dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
  Simulate.change(this.dataRow.minScoreInput, {target: {value: '101'}})
  Simulate.blur(this.dataRow.minScoreInput)
  ok(changeMinScore.notCalled)
  changeMinScore.restore()
})

test('on blur, calls onRowMinScoreChange when input parsed value is between 0 and 100', function() {
  const changeMinScore = this.spy(this.props, 'onRowMinScoreChange')
  const DataRowElement = <DataRow {...this.props} />
  this.dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
  Simulate.change(this.dataRow.minScoreInput, {target: {value: '88.'}})
  Simulate.blur(this.dataRow.minScoreInput)
  Simulate.change(this.dataRow.minScoreInput, {target: {value: ''}})
  Simulate.blur(this.dataRow.minScoreInput)
  Simulate.change(this.dataRow.minScoreInput, {target: {value: '100'}})
  Simulate.blur(this.dataRow.minScoreInput)
  Simulate.change(this.dataRow.minScoreInput, {target: {value: '0'}})
  Simulate.blur(this.dataRow.minScoreInput)
  Simulate.change(this.dataRow.minScoreInput, {target: {value: 'A'}})
  Simulate.blur(this.dataRow.minScoreInput)
  Simulate.change(this.dataRow.minScoreInput, {target: {value: '%*@#($'}})
  Simulate.blur(this.dataRow.minScoreInput)
  deepEqual(changeMinScore.callCount, 3)
  changeMinScore.restore()
})

test('on blur, does not call onRowMinScoreChange when input has not changed', function() {
  const changeMinScore = this.spy(this.props, 'onRowMinScoreChange')
  const DataRowElement = <DataRow {...this.props} />
  this.dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
  Simulate.blur(this.dataRow.minScoreInput)
  ok(changeMinScore.notCalled)
  changeMinScore.restore()
})

test('calls onRowNameChange when input changes', function() {
  const changeMinScore = this.spy(this.props, 'onRowNameChange')
  const DataRowElement = <DataRow {...this.props} />
  this.dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
  Simulate.change(this.dataRow.refs.nameInput, {target: {value: 'F'}})
  ok(changeMinScore.calledOnce)
  changeMinScore.restore()
})

test('calls onDeleteRow when the delete button is clicked', function() {
  const deleteRow = this.spy(this.props, 'onDeleteRow')
  const DataRowElement = <DataRow {...this.props} />
  this.dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
  Simulate.click(this.dataRow.refs.deleteButton.getDOMNode())
  ok(deleteRow.calledOnce)
})

QUnit.module('DataRow with a sibling', {
  setup() {
    const props = {
      key: 1,
      row: ['A-', 90],
      siblingRow: ['A', 92.346],
      editing: false,
      round: number => Math.round(number * 100) / 100
    }
    const DataRowElement = <DataRow {...props} />
    this.dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.dataRow).parentNode)
    $('#fixtures').empty()
  }
})

test("shows the max score as the sibling's min score", function() {
  deepEqual(this.dataRow.renderMaxScore(), '< 92.35')
})
