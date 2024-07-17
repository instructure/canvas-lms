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
import {Simulate} from 'react-dom/test-utils'
import $ from 'jquery'
import 'jquery-migrate'
import DataRow from '@canvas/grading-standard-collection/react/dataRow'
import sinon from 'sinon'

const sandbox = sinon.createSandbox()

const ok = x => expect(x).toBeTruthy()
const deepEqual = (x, y) => expect(x).toEqual(y)

let dataRow
let props

const fixturesDiv = document.createElement('div')
fixturesDiv.id = 'fixtures'
document.body.appendChild(fixturesDiv)

describe('DataRow not being edited, without a sibling', () => {
  beforeEach(() => {
    const props = {
      key: 0,
      uniqueId: 0,
      row: ['A', 92.346],
      editing: false,
      round: number => Math.round(number * 100) / 100,
      onRowMinScoreChange() {},
    }
    const DataRowElement = <DataRow {...props} />
    dataRow = ReactDOM.render(DataRowElement, $('<tbody>').appendTo('#fixtures')[0])
  })
  afterEach(() => {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(dataRow).parentNode)
    $('#fixtures').empty()
  })

  test('renders in "view" mode (as opposed to "edit" mode)', function () {
    ok(dataRow.refs.viewContainer)
  })

  test('getRowData() returns the correct name', function () {
    deepEqual(dataRow.getRowData().name, 'A')
  })

  test('getRowData() sets max score to 100 if there is no sibling row', function () {
    deepEqual(dataRow.getRowData().maxScore, 100)
  })

  test('renderMinScore() rounds the score if not in editing mode', function () {
    deepEqual(dataRow.renderMinScore(), '92.35')
  })

  test("renderMaxScore() returns a max score of 100 without a '<' sign", function () {
    deepEqual(dataRow.renderMaxScore(), '100')
  })
})

describe('DataRow being edited', () => {
  beforeEach(() => {
    props = {
      key: 0,
      uniqueId: 0,
      row: ['A', 92.346],
      editing: true,
      round: number => Math.round(number * 100) / 100,
      onRowMinScoreChange() {},
      onRowNameChange() {},
      onDeleteRow() {},
    }
    const DataRowElement = <DataRow {...props} />
    dataRow = ReactDOM.render(DataRowElement, $('<tbody>').appendTo('#fixtures')[0])
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(dataRow).parentNode)
    $('#fixtures').empty()
  })

  test('renders in "edit" mode (as opposed to "view" mode)', function () {
    ok(dataRow.refs.editContainer)
  })

  test('on change, accepts arbitrary input and saves to state', function () {
    const changeMinScore = sandbox.spy(props, 'onRowMinScoreChange')
    const DataRowElement = <DataRow {...props} />
    dataRow = ReactDOM.render(DataRowElement, $('<tbody>').appendTo('#fixtures')[0])
    Simulate.change(dataRow.minScoreInput, {target: {value: 'A'}})
    deepEqual(dataRow.renderMinScore(), 'A')
    Simulate.change(dataRow.minScoreInput, {target: {value: '*&@%!'}})
    deepEqual(dataRow.renderMinScore(), '*&@%!')
    Simulate.change(dataRow.minScoreInput, {target: {value: '3B'}})
    deepEqual(dataRow.renderMinScore(), '3B')
    ok(changeMinScore.notCalled)
    changeMinScore.restore()
  })

  test('screenreader text contains contextual label describing inserting row', () => {
    const screenreaderTexts = [...document.getElementsByClassName('screenreader-only')]
    ok(
      screenreaderTexts.find(
        screenreaderText => screenreaderText.textContent === 'Insert row below A'
      )
    )
  })

  test('screenreader text contains contextual label describing removing row', () => {
    const screenreaderTexts = [...document.getElementsByClassName('screenreader-only')]
    ok(screenreaderTexts.find(screenreaderText => screenreaderText.textContent === 'Remove row A'))
  })

  test('on blur, does not call onRowMinScoreChange if the input parsed value is less than 0', function () {
    const changeMinScore = sandbox.spy(props, 'onRowMinScoreChange')
    const DataRowElement = <DataRow {...props} />
    dataRow = ReactDOM.render(DataRowElement, $('<tbody>').appendTo('#fixtures')[0])
    Simulate.change(dataRow.minScoreInput, {target: {value: '-1'}})
    Simulate.blur(dataRow.minScoreInput)
    ok(changeMinScore.notCalled)
    changeMinScore.restore()
  })

  test('on blur, does not call onRowMinScoreChange if the input parsed value is greater than 100', function () {
    const changeMinScore = sandbox.spy(props, 'onRowMinScoreChange')
    const DataRowElement = <DataRow {...props} />
    dataRow = ReactDOM.render(DataRowElement, $('<tbody>').appendTo('#fixtures')[0])
    Simulate.change(dataRow.minScoreInput, {target: {value: '101'}})
    Simulate.blur(dataRow.minScoreInput)
    ok(changeMinScore.notCalled)
    changeMinScore.restore()
  })

  test('on blur, calls onRowMinScoreChange when input parsed value is between 0 and 100', function () {
    const changeMinScore = sandbox.spy(props, 'onRowMinScoreChange')
    const DataRowElement = <DataRow {...props} />
    dataRow = ReactDOM.render(DataRowElement, $('<tbody>').appendTo('#fixtures')[0])
    Simulate.change(dataRow.minScoreInput, {target: {value: '88.'}})
    Simulate.blur(dataRow.minScoreInput)
    Simulate.change(dataRow.minScoreInput, {target: {value: ''}})
    Simulate.blur(dataRow.minScoreInput)
    Simulate.change(dataRow.minScoreInput, {target: {value: '100'}})
    Simulate.blur(dataRow.minScoreInput)
    Simulate.change(dataRow.minScoreInput, {target: {value: '0'}})
    Simulate.blur(dataRow.minScoreInput)
    Simulate.change(dataRow.minScoreInput, {target: {value: 'A'}})
    Simulate.blur(dataRow.minScoreInput)
    Simulate.change(dataRow.minScoreInput, {target: {value: '%*@#($'}})
    Simulate.blur(dataRow.minScoreInput)
    deepEqual(changeMinScore.callCount, 3)
    changeMinScore.restore()
  })

  test('on blur, does not call onRowMinScoreChange when input has not changed', function () {
    const changeMinScore = sandbox.spy(props, 'onRowMinScoreChange')
    const DataRowElement = <DataRow {...props} />
    dataRow = ReactDOM.render(DataRowElement, $('<tbody>').appendTo('#fixtures')[0])
    Simulate.blur(dataRow.minScoreInput)
    ok(changeMinScore.notCalled)
    changeMinScore.restore()
  })

  test('calls onRowNameChange when input changes', function () {
    const changeMinScore = sandbox.spy(props, 'onRowNameChange')
    const DataRowElement = <DataRow {...props} />
    dataRow = ReactDOM.render(DataRowElement, $('<tbody>').appendTo('#fixtures')[0])
    Simulate.change(dataRow.refs.nameInput, {target: {value: 'F'}})
    ok(changeMinScore.calledOnce)
    changeMinScore.restore()
  })

  test('calls onDeleteRow when the delete button is clicked', function () {
    const deleteRow = sandbox.spy(props, 'onDeleteRow')
    const DataRowElement = <DataRow {...props} />
    dataRow = ReactDOM.render(DataRowElement, $('<tbody>').appendTo('#fixtures')[0])
    Simulate.click(dataRow.deleteButtonRef)
    ok(deleteRow.calledOnce)
  })
})

describe('DataRow with a sibling', () => {
  beforeEach(() => {
    const props = {
      key: 1,
      row: ['A-', 90],
      siblingRow: ['A', 92.346],
      uniqueId: 1,
      editing: false,
      round: number => Math.round(number * 100) / 100,
      onRowMinScoreChange() {},
    }
    const DataRowElement = <DataRow {...props} />
    dataRow = ReactDOM.render(DataRowElement, $('<tbody>').appendTo('#fixtures')[0])
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(dataRow).parentNode)
    $('#fixtures').empty()
  })

  test("shows the max score as the sibling's min score", function () {
    deepEqual(dataRow.renderMaxScore(), '< 92.35')
  })
})
