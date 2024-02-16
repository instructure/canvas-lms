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
import TestUtils from 'react-dom/test-utils'
import $ from 'jquery'
import 'jquery-migrate'
import _ from 'lodash'
import GradingStandardCollection from '@canvas/grading-standard-collection'

const {Simulate} = TestUtils

QUnit.module('GradingStandardCollection', {
  setup() {
    sandbox.stub($, 'flashMessage')
    sandbox.stub($, 'flashError')
    sandbox.stub(window, 'confirm')
    this.server = sinon.fakeServer.create()
    ENV.current_user_roles = ['admin', 'teacher']
    ENV.GRADING_STANDARDS_URL = '/courses/1/grading_standards'
    ENV.DEFAULT_GRADING_STANDARD_DATA = [
      ['A', 0.94],
      ['A-', 0.9],
      ['B+', 0.87],
      ['B', 0.84],
      ['B-', 0.8],
      ['C+', 0.77],
      ['C', 0.74],
      ['C-', 0.7],
      ['D+', 0.67],
      ['D', 0.64],
      ['D-', 0.61],
      ['F', 0],
    ]
    this.processedDefaultData = [
      ['A', 94],
      ['A-', 90],
      ['B+', 87],
      ['B', 84],
      ['B-', 80],
      ['C+', 77],
      ['C', 74],
      ['C-', 70],
      ['D+', 67],
      ['D', 64],
      ['D-', 61],
      ['F', 0],
    ]
    this.indexData = [
      {
        grading_standard: {
          id: 1,
          title: 'Hard to Fail',
          data: [
            ['A', 0.2],
            ['F', 0],
          ],
          permissions: {
            read: true,
            manage: true,
          },
        },
      },
    ]
    this.processedIndexData = [
      {
        grading_standard: {
          id: 1,
          title: 'Hard to Fail',
          data: [
            ['A', 20],
            ['F', 0],
          ],
          permissions: {
            read: true,
            manage: true,
          },
        },
      },
    ]
    this.updatedStandard = {
      grading_standard: {
        title: 'Updated Standard',
        id: 1,
        data: [
          ['A', 0.9],
          ['F', 0.5],
        ],
        permissions: {
          read: true,
          manage: true,
        },
      },
    }
    this.createdStandard = {
      grading_standard: {
        title: 'Newly Created Standard',
        id: 2,
        data: ENV.DEFAULT_GRADING_STANDARD_DATA,
        permissions: {
          read: true,
          manage: true,
        },
      },
    }
    this.server.respondWith('GET', `${ENV.GRADING_STANDARDS_URL}.json`, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(this.indexData),
    ])
    this.server.respondWith('POST', ENV.GRADING_STANDARDS_URL, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(this.createdStandard),
    ])
    this.server.respondWith('PUT', `${ENV.GRADING_STANDARDS_URL}/1`, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(this.updatedStandard),
    ])
    const GradingStandardCollectionElement = <GradingStandardCollection />
    this.gradingStandardCollection = TestUtils.renderIntoDocument(GradingStandardCollectionElement)
    return this.server.respond()
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.gradingStandardCollection).parentNode)
    ENV.current_user_roles = null
    ENV.GRADING_STANDARDS_URL = null
    ENV.DEFAULT_GRADING_STANDARD_DATA = null
    return this.server.restore()
  },
})

test('gets the standards data from the grading standards controller, and multiplies data values by 100 (i.e. .20 becomes 20)', function () {
  deepEqual(this.gradingStandardCollection.state.standards, this.processedIndexData)
})

test('getStandardById gets the correct standard by its id', function () {
  deepEqual(this.gradingStandardCollection.getStandardById(1), _.first(this.processedIndexData))
})

test("getStandardById returns undefined for a id that doesn't match a standard", function () {
  deepEqual(this.gradingStandardCollection.getStandardById(10), undefined)
})

test('adds a new standard when the add button is clicked', function () {
  deepEqual(this.gradingStandardCollection.state.standards.length, 1)
  Simulate.click(this.gradingStandardCollection.addButtonRef)
  deepEqual(this.gradingStandardCollection.state.standards.length, 2)
})

test('adds the default standard when the add button is clicked', function () {
  Simulate.click(this.gradingStandardCollection.addButtonRef)
  const newStandard = _.first(this.gradingStandardCollection.state.standards).grading_standard
  deepEqual(newStandard.data, this.processedDefaultData)
})

test('does not save the new standard on the backend when the add button is clicked', function () {
  const saveGradingStandard = sandbox.spy(this.gradingStandardCollection, 'saveGradingStandard')
  Simulate.click(this.gradingStandardCollection.addButtonRef)
  ok(saveGradingStandard.notCalled)
})

test("standardNotCreated returns true for a new standard that hasn't been saved yet", function () {
  Simulate.click(this.gradingStandardCollection.addButtonRef)
  const newStandard = _.first(this.gradingStandardCollection.state.standards).grading_standard
  ok(this.gradingStandardCollection.standardNotCreated(newStandard))
})

test('standardNotCreated returns false for standards that have been saved on the backend', function () {
  Simulate.click(this.gradingStandardCollection.addButtonRef)
  const unsavedStandard = _.first(this.gradingStandardCollection.state.standards).grading_standard
  ok(this.gradingStandardCollection.standardNotCreated(unsavedStandard))
  this.gradingStandardCollection.saveGradingStandard(unsavedStandard)
  this.server.respond()
  const savedStandard = _.first(this.gradingStandardCollection.state.standards).grading_standard
  deepEqual(savedStandard.title, 'Newly Created Standard')
  deepEqual(this.gradingStandardCollection.standardNotCreated(savedStandard), false)
})

test('saveGradingStandard updates an already-saved grading standard', function () {
  const savedStandard = _.first(this.gradingStandardCollection.state.standards).grading_standard
  this.gradingStandardCollection.saveGradingStandard(savedStandard)
  this.server.respond()
  const updatedStandard = _.first(this.gradingStandardCollection.state.standards).grading_standard
  deepEqual(updatedStandard.title, 'Updated Standard')
})

test('setEditingStatus removes the standard if the user clicks "Cancel" on a not-yet-saved standard', function () {
  Simulate.click(this.gradingStandardCollection.addButtonRef)
  deepEqual(this.gradingStandardCollection.state.standards.length, 2)
  deepEqual(
    _.first(this.gradingStandardCollection.state.standards).grading_standard.data,
    this.processedDefaultData
  )
  this.gradingStandardCollection.setEditingStatus(-1, false)
  deepEqual(this.gradingStandardCollection.state.standards.length, 1)
  deepEqual(
    _.first(this.gradingStandardCollection.state.standards).grading_standard.data,
    _.first(this.processedIndexData).grading_standard.data
  )
})

test('setEditingStatus sets the editing status to true on a saved standard, when true is passed in', function () {
  this.gradingStandardCollection.setEditingStatus(1, true)
  deepEqual(_.first(this.gradingStandardCollection.state.standards).editing, true)
})

test('setEditingStatus sets the editing status to false on a saved standard, when false is passed in', function () {
  this.gradingStandardCollection.setEditingStatus(1, false)
  deepEqual(_.first(this.gradingStandardCollection.state.standards).editing, false)
})

test('anyStandardBeingEdited returns false if no standards are being edited', function () {
  deepEqual(this.gradingStandardCollection.anyStandardBeingEdited(), false)
})

test('anyStandardBeingEdited returns true after the user clicks "Add grading scheme"', function () {
  Simulate.click(this.gradingStandardCollection.addButtonRef)
  deepEqual(this.gradingStandardCollection.anyStandardBeingEdited(), true)
})

test('anyStandardBeingEdited returns false if the user clicks "Add grading scheme" and then clicks "Cancel"', function () {
  Simulate.click(this.gradingStandardCollection.addButtonRef)
  this.gradingStandardCollection.setEditingStatus(-1, false)
  deepEqual(this.gradingStandardCollection.anyStandardBeingEdited(), false)
})

test('anyStandardBeingEdited returns false if the user clicks "Add grading scheme" and then clicks "Save"', function () {
  Simulate.click(this.gradingStandardCollection.addButtonRef)
  const unsavedStandard = _.first(this.gradingStandardCollection.state.standards).grading_standard
  this.gradingStandardCollection.saveGradingStandard(unsavedStandard)
  this.server.respond()
  deepEqual(this.gradingStandardCollection.anyStandardBeingEdited(), false)
})

test('anyStandardBeingEdited returns true if any standards are being edited', function () {
  this.gradingStandardCollection.setEditingStatus(1, true)
  deepEqual(this.gradingStandardCollection.anyStandardBeingEdited(), true)
})

test('roundToTwoDecimalPlaces rounds correctly', function () {
  deepEqual(this.gradingStandardCollection.roundToTwoDecimalPlaces(20), 20)
  deepEqual(this.gradingStandardCollection.roundToTwoDecimalPlaces(20.7), 20.7)
  deepEqual(this.gradingStandardCollection.roundToTwoDecimalPlaces(20.23), 20.23)
  deepEqual(this.gradingStandardCollection.roundToTwoDecimalPlaces(20.234123), 20.23)
  deepEqual(this.gradingStandardCollection.roundToTwoDecimalPlaces(20.23523), 20.24)
})

test('dataFormattedForCreate formats the grading standard correctly for the create AJAX call', function () {
  const gradingStandard = _.first(this.gradingStandardCollection.state.standards).grading_standard
  deepEqual(this.gradingStandardCollection.dataFormattedForCreate(gradingStandard), {
    grading_standard: {
      id: 1,
      title: 'Hard to Fail',
      data: [
        ['A', 0.2],
        ['F', 0],
      ],
      permissions: {
        manage: true,
        read: true,
      },
    },
  })
})

test('dataFormattedForUpdate formats the grading standard correctly for the update AJAX call', function () {
  const gradingStandard = _.first(this.gradingStandardCollection.state.standards).grading_standard
  deepEqual(this.gradingStandardCollection.dataFormattedForUpdate(gradingStandard), {
    grading_standard: {
      title: 'Hard to Fail',
      standard_data: {
        scheme_0: {
          name: 'A',
          value: 20,
        },
        scheme_1: {
          name: 'F',
          value: 0,
        },
      },
    },
  })
})

test('hasAdminOrTeacherRole returns true if the user has an admin or teacher role', function () {
  ENV.current_user_roles = []
  deepEqual(this.gradingStandardCollection.hasAdminOrTeacherRole(), false)
  ENV.current_user_roles = ['teacher']
  deepEqual(this.gradingStandardCollection.hasAdminOrTeacherRole(), true)
  ENV.current_user_roles = ['admin']
  deepEqual(this.gradingStandardCollection.hasAdminOrTeacherRole(), true)
  ENV.current_user_roles = ['teacher', 'admin']
  deepEqual(this.gradingStandardCollection.hasAdminOrTeacherRole(), true)
})

test('disables the "Add grading scheme" button if any standards are being edited', function () {
  this.gradingStandardCollection.setEditingStatus(1, true)
  ok(this.gradingStandardCollection.getAddButtonCssClasses().indexOf('disabled') > -1)
})

test('disables the "Add grading scheme" button if the user is not a teacher or admin', function () {
  ENV.current_user_roles = []
  ok(this.gradingStandardCollection.getAddButtonCssClasses().indexOf('disabled') > -1)
})

test('shows a message that says "No grading schemes to display" if there are no standards', function () {
  deepEqual(this.gradingStandardCollection.noSchemesMessageRef, undefined)
  this.gradingStandardCollection.setState({standards: []})
  ok(this.gradingStandardCollection.noSchemesMessageRef)
})

test('deleteGradingStandard calls confirmDelete', function () {
  const confirmDelete = sandbox.spy($.fn, 'confirmDelete')
  const deleteButton = this.gradingStandardCollection.gradingStandard1Ref.deleteButtonRef
  Simulate.click(deleteButton)
  ok(confirmDelete.calledOnce)
})
