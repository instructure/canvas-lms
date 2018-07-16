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
import TestUtils from 'react-addons-test-utils'
import $ from 'jquery'
import GradingPeriodCollection from 'jsx/grading/gradingPeriodCollection'
import fakeENV from 'helpers/fakeENV'
import 'jquery.instructure_misc_plugins'
import 'compiled/jquery.rails_flash_notifications'

QUnit.module('GradingPeriodCollection', {
  setup() {
    sandbox.stub($, 'flashMessage')
    sandbox.stub($, 'flashError')
    sandbox.stub(window, 'confirm').returns(true)
    this.server = sinon.fakeServer.create()
    fakeENV.setup()
    ENV.current_user_roles = ['admin']
    ENV.GRADING_PERIODS_URL = '/api/v1/accounts/1/grading_periods'
    ENV.GRADING_PERIODS_WEIGHTED = true
    this.indexData = {
      grading_periods: [
        {
          id: '1',
          title: 'Spring',
          start_date: '2015-03-01T06:00:00Z',
          end_date: '2015-05-31T05:00:00Z',
          close_date: '2015-06-07T05:00:00Z',
          weight: null,
          permissions: {
            update: true,
            delete: true
          }
        },
        {
          id: '2',
          title: 'Summer',
          start_date: '2015-06-01T05:00:00Z',
          end_date: '2015-08-31T05:00:00Z',
          close_date: '2015-09-07T05:00:00Z',
          weight: null,
          permissions: {
            update: true,
            delete: true
          }
        }
      ],
      grading_periods_read_only: false,
      can_create_grading_periods: true
    }
    this.formattedIndexData = {
      grading_periods: [
        {
          id: '1',
          title: 'Spring',
          startDate: new Date('2015-03-01T06:00:00Z'),
          endDate: new Date('2015-05-31T05:00:00Z'),
          closeDate: new Date('2015-06-07T05:00:00Z'),
          weight: null,
          permissions: {
            update: true,
            delete: true
          }
        },
        {
          id: '2',
          title: 'Summer',
          startDate: new Date('2015-06-01T05:00:00Z'),
          endDate: new Date('2015-08-31T05:00:00Z'),
          closeDate: new Date('2015-09-07T05:00:00Z'),
          weight: null,
          permissions: {
            update: true,
            delete: true
          }
        }
      ],
      grading_periods_read_only: false,
      can_create_grading_periods: true
    }
    this.createdPeriodData = {
      grading_periods: [
        {
          id: '3',
          title: 'New Period!',
          start_date: '2015-04-20T05:00:00Z',
          end_date: '2015-04-21T05:00:00Z',
          close_date: '2015-04-28T05:00:00Z',
          weight: null,
          permissions: {
            update: true,
            delete: true
          }
        }
      ]
    }
    this.server.respondWith('GET', ENV.GRADING_PERIODS_URL, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(this.indexData)
    ])
    this.server.respondWith('POST', ENV.GRADING_PERIODS_URL, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(this.createdPeriodData)
    ])
    this.server.respondWith('DELETE', `${ENV.GRADING_PERIODS_URL}/1`, [204, {}, ''])
    const GradingPeriodCollectionElement = <GradingPeriodCollection />
    this.gradingPeriodCollection = TestUtils.renderIntoDocument(GradingPeriodCollectionElement)
    return this.server.respond()
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(this.gradingPeriodCollection.getDOMNode().parentNode)
    fakeENV.teardown()
    return this.server.restore()
  }
})

test('gets the grading periods from the grading periods controller', function() {
  deepEqual(this.gradingPeriodCollection.state.periods, this.formattedIndexData.grading_periods)
})

test('getPeriods requests the index data from the server', function() {
  sandbox.spy($, 'ajax')
  this.gradingPeriodCollection.getPeriods()
  ok($.ajax.calledOnce)
})

test("renders grading periods with 'readOnly' set to the returned value (false)", function() {
  equal(this.gradingPeriodCollection.refs.grading_period_1.props.readOnly, false)
  equal(this.gradingPeriodCollection.refs.grading_period_2.props.readOnly, false)
})

test("renders grading periods with 'weighted' set to the ENV variable (true)", function() {
  equal(this.gradingPeriodCollection.refs.grading_period_1.props.weighted, true)
  equal(this.gradingPeriodCollection.refs.grading_period_2.props.weighted, true)
})

test("renders grading periods with their individual 'closeDate'", function() {
  deepEqual(
    this.gradingPeriodCollection.refs.grading_period_1.props.closeDate,
    new Date('2015-06-07T05:00:00Z')
  )
  deepEqual(
    this.gradingPeriodCollection.refs.grading_period_2.props.closeDate,
    new Date('2015-09-07T05:00:00Z')
  )
})

test('deleteGradingPeriod calls confirmDelete if the period being deleted is not new (it is saved server side)', function() {
  const confirmDelete = sandbox.stub($.fn, 'confirmDelete')
  this.gradingPeriodCollection.deleteGradingPeriod('1')
  ok(confirmDelete.calledOnce)
})

test('updateGradingPeriodCollection correctly updates the periods state', function() {
  const updatedPeriodComponent = {}
  updatedPeriodComponent.state = {
    id: '1',
    startDate: new Date('2069-03-01T06:00:00Z'),
    endDate: new Date('2070-05-31T05:00:00Z'),
    weight: null,
    title: 'Updating an existing period!'
  }
  updatedPeriodComponent.props = {
    permissions: {
      read: true,
      update: true,
      delete: true
    }
  }
  this.gradingPeriodCollection.updateGradingPeriodCollection(updatedPeriodComponent)
  const updatedPeriod = this.gradingPeriodCollection.state.periods.find(p => p.id === '1')
  deepEqual(updatedPeriod.title, updatedPeriodComponent.state.title)
})

test('getPeriodById returns the period with the matching id (if one exists)', function() {
  const period = this.gradingPeriodCollection.getPeriodById('1')
  deepEqual(period.id, '1')
})

test("given two grading periods that don't overlap, areNoDatesOverlapping returns true", function() {
  ok(
    this.gradingPeriodCollection.areNoDatesOverlapping(
      this.gradingPeriodCollection.state.periods[0]
    )
  )
})

test('given two overlapping grading periods, areNoDatesOverlapping returns false', function() {
  const startDate = new Date('2015-03-01T06:00:00Z')
  const endDate = new Date('2015-05-31T05:00:00Z')
  const formattedIndexData = [
    {
      id: '1',
      startDate,
      endDate,
      weight: null,
      title: 'Spring',
      permissions: {
        read: false,
        update: false,
        delete: false
      }
    },
    {
      id: '2',
      startDate,
      endDate,
      weight: null,
      title: 'Summer',
      permissions: {
        read: false,
        update: false,
        delete: false
      }
    }
  ]
  this.gradingPeriodCollection.setState({periods: formattedIndexData})
  ok(
    !this.gradingPeriodCollection.areNoDatesOverlapping(
      this.gradingPeriodCollection.state.periods[0]
    )
  )
})

test('serializeDataForSubmission serializes periods by snake casing keys', function() {
  const firstPeriod = this.gradingPeriodCollection.state.periods[0]
  const secondPeriod = this.gradingPeriodCollection.state.periods[1]
  const expectedOutput = {
    grading_periods: [
      {
        id: firstPeriod.id,
        title: firstPeriod.title,
        start_date: firstPeriod.startDate,
        end_date: firstPeriod.endDate
      },
      {
        id: secondPeriod.id,
        title: secondPeriod.title,
        start_date: secondPeriod.startDate,
        end_date: secondPeriod.endDate
      }
    ]
  }
  deepEqual(this.gradingPeriodCollection.serializeDataForSubmission(), expectedOutput)
})

test('batchUpdatePeriods makes an AJAX call if validations pass', function() {
  sandbox.stub(this.gradingPeriodCollection, 'areGradingPeriodsValid').returns(true)
  const ajax = sandbox.spy($, 'ajax')
  this.gradingPeriodCollection.batchUpdatePeriods()
  ok(ajax.calledOnce)
})

test('batchUpdatePeriods does not make an AJAX call if validations fail', function() {
  sandbox.stub(this.gradingPeriodCollection, 'areGradingPeriodsValid').returns(false)
  const ajax = sandbox.spy($, 'ajax')
  this.gradingPeriodCollection.batchUpdatePeriods()
  ok(ajax.notCalled)
})

test('isTitleCompleted checks for a title being present', function() {
  const period = {title: 'Spring'}
  ok(this.gradingPeriodCollection.isTitleCompleted(period))
})

test('isTitleCompleted fails blank titles', function() {
  const period = {title: ' '}
  ok(!this.gradingPeriodCollection.isTitleCompleted(period))
})

test('isStartDateBeforeEndDate passes', function() {
  const period = {
    startDate: new Date('2015-03-01T06:00:00Z'),
    endDate: new Date('2015-05-31T05:00:00Z')
  }
  ok(this.gradingPeriodCollection.isStartDateBeforeEndDate(period))
})

test('isStartDateBeforeEndDate fails', function() {
  const period = {
    startDate: new Date('2015-05-31T05:00:00Z'),
    endDate: new Date('2015-03-01T06:00:00Z')
  }
  ok(!this.gradingPeriodCollection.isStartDateBeforeEndDate(period))
})

test('areDatesValid passes', function() {
  const period = {
    startDate: new Date('2015-03-01T06:00:00Z'),
    endDate: new Date('2015-05-31T05:00:00Z')
  }
  ok(this.gradingPeriodCollection.areDatesValid(period))
})

test('areDatesValid fails', function() {
  let period = {
    startDate: new Date('foo'),
    endDate: new Date('foo')
  }
  ok(!this.gradingPeriodCollection.areDatesValid(period))
  period = {
    startDate: new Date('foo'),
    endDate: new Date('2015-05-31T05:00:00Z')
  }
  ok(!this.gradingPeriodCollection.areDatesValid(period))
  period = {
    startDate: '2015-03-01T06:00:00Z',
    endDate: new Date('foo')
  }
  ok(!this.gradingPeriodCollection.areDatesValid(period))
})

test('areNoDatesOverlapping periods are not overlapping when endDate of earlier period is the same as start date for the latter', function() {
  const periodOne = {
    id: '1',
    startDate: new Date('2029-03-01T06:00:00Z'),
    endDate: new Date('2030-05-31T05:00:00Z'),
    weight: null,
    title: 'Spring',
    permissions: {
      read: true,
      update: true,
      delete: true
    }
  }
  const periodTwo = {
    id: 'new2',
    startDate: new Date('2030-05-31T05:00:00Z'),
    endDate: new Date('2031-05-31T05:00:00Z'),
    weight: null,
    title: 'Spring',
    permissions: {
      read: true,
      update: true,
      delete: true
    }
  }
  this.gradingPeriodCollection.setState({
    periods: [periodOne, periodTwo]
  })
  ok(this.gradingPeriodCollection.areNoDatesOverlapping(periodTwo))
})

test('areNoDatesOverlapping periods are overlapping when a period falls within another', function() {
  const periodOne = {
    id: '1',
    startDate: new Date('2029-01-01T00:00:00Z'),
    endDate: new Date('2030-01-01T00:00:00Z'),
    weight: null,
    title: 'Spring',
    permissions: {
      read: true,
      update: true,
      delete: true
    }
  }
  const periodTwo = {
    id: 'new2',
    startDate: new Date('2029-01-01T00:00:00Z'),
    endDate: new Date('2030-01-01T00:00:00Z'),
    weight: null,
    title: 'Spring',
    permissions: {
      read: true,
      update: true,
      delete: true
    }
  }
  this.gradingPeriodCollection.setState({
    periods: [periodOne, periodTwo]
  })
  ok(!this.gradingPeriodCollection.areNoDatesOverlapping(periodTwo))
})

test('areDatesOverlapping adding two periods at the same time that overlap returns true', function() {
  const existingPeriod = this.gradingPeriodCollection.state.periods[0]
  const periodOne = {
    id: 'new1',
    startDate: new Date('2029-01-01T00:00:00Z'),
    endDate: new Date('2030-01-01T00:00:00Z'),
    title: 'Spring',
    permissions: {
      update: true,
      delete: true
    }
  }
  const periodTwo = {
    id: 'new2',
    startDate: new Date('2029-01-01T00:00:00Z'),
    endDate: new Date('2030-01-01T00:00:00Z'),
    title: 'Spring',
    permissions: {
      update: true,
      delete: true
    }
  }
  this.gradingPeriodCollection.setState({
    periods: [existingPeriod, periodOne, periodTwo]
  })
  ok(!this.gradingPeriodCollection.areDatesOverlapping(existingPeriod))
  ok(this.gradingPeriodCollection.areDatesOverlapping(periodOne))
  ok(this.gradingPeriodCollection.areDatesOverlapping(periodTwo))
})

test('renderSaveButton does not render a button if the user cannot update any of the periods on the page', function() {
  const uneditable = [
    {
      id: '12',
      startDate: new Date('2015-03-01T06:00:00Z'),
      endDate: new Date('2015-05-31T05:00:00Z'),
      weight: null,
      title: 'Spring',
      permissions: {
        read: true,
        update: false,
        delete: false
      }
    }
  ]
  this.gradingPeriodCollection.setState({periods: uneditable})
  notOk(this.gradingPeriodCollection.renderSaveButton())
  Object.assign(uneditable, {
    permissions: {
      update: true,
      delete: false
    }
  })
  this.gradingPeriodCollection.setState({periods: uneditable})
  notOk(this.gradingPeriodCollection.renderSaveButton())
  Object.assign(uneditable, {
    permissions: {
      delete: false,
      delete: true
    }
  })
  this.gradingPeriodCollection.setState({periods: uneditable})
  notOk(this.gradingPeriodCollection.renderSaveButton())
})

test('renderSaveButton renders a button if the user is not at the course grading periods page', function() {
  ok(this.gradingPeriodCollection.renderSaveButton())
})

QUnit.module('GradingPeriodCollection with read-only grading periods', {
  setup() {
    this.server = sinon.fakeServer.create()
    fakeENV.setup()
    ENV.current_user_roles = ['admin']
    ENV.GRADING_PERIODS_URL = '/api/v1/accounts/1/grading_periods'
    ENV.GRADING_PERIODS_WEIGHTED = false
    this.indexData = {
      grading_periods: [
        {
          id: '1',
          start_date: '2015-03-01T06:00:00Z',
          end_date: '2015-05-31T05:00:00Z',
          weight: null,
          title: 'Spring',
          permissions: {
            update: true,
            delete: true
          }
        }
      ],
      grading_periods_read_only: true,
      can_create_grading_periods: true
    }
    this.server.respondWith('GET', ENV.GRADING_PERIODS_URL, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(this.indexData)
    ])
    const GradingPeriodCollectionElement = <GradingPeriodCollection />
    this.gradingPeriodCollection = TestUtils.renderIntoDocument(GradingPeriodCollectionElement)
    this.server.respond()
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(this.gradingPeriodCollection.getDOMNode().parentNode)
    fakeENV.teardown()
    this.server.restore()
  }
})

test("renders grading periods with 'readOnly' set to true", function() {
  equal(this.gradingPeriodCollection.refs.grading_period_1.props.readOnly, true)
})

test("renders grading periods with 'weighted' set to the ENV variable (false)", function() {
  equal(this.gradingPeriodCollection.refs.grading_period_1.props.weighted, false)
})
