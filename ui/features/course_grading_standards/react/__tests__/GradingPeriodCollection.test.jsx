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
import GradingPeriodCollection from '../gradingPeriodCollection'
import fakeENV from '@canvas/test-utils/fakeENV'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import sinon from 'sinon'

describe('GradingPeriodCollection', () => {
  let sandbox
  let server
  let gradingPeriodCollection
  let indexData
  let formattedIndexData
  let createdPeriodData

  beforeEach(() => {
    // Create a Sinon sandbox
    sandbox = sinon.createSandbox()

    // Stub jQuery methods
    sandbox.stub($, 'flashMessage')
    sandbox.stub($, 'flashError')
    sandbox.stub(window, 'confirm').returns(true)

    // Create a fake server
    server = sinon.fakeServer.create()
    fakeENV.setup()

    // Set ENV variables
    window.ENV = window.ENV || {}
    window.ENV.current_user_roles = ['admin']
    window.ENV.GRADING_PERIODS_URL = '/api/v1/accounts/1/grading_periods'
    window.ENV.GRADING_PERIODS_WEIGHTED = true

    // Define test data
    indexData = {
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
            delete: true,
          },
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
            delete: true,
          },
        },
      ],
      grading_periods_read_only: false,
      can_create_grading_periods: true,
    }

    formattedIndexData = {
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
            delete: true,
          },
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
            delete: true,
          },
        },
      ],
      grading_periods_read_only: false,
      can_create_grading_periods: true,
    }

    createdPeriodData = {
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
            delete: true,
          },
        },
      ],
    }

    // Setup fake server responses
    server.respondWith('GET', window.ENV.GRADING_PERIODS_URL, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(indexData),
    ])
    server.respondWith('POST', window.ENV.GRADING_PERIODS_URL, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(createdPeriodData),
    ])
    server.respondWith('DELETE', `${window.ENV.GRADING_PERIODS_URL}/1`, [204, {}, ''])

    // Render the component
    const GradingPeriodCollectionElement = <GradingPeriodCollection />
    gradingPeriodCollection = TestUtils.renderIntoDocument(GradingPeriodCollectionElement)

    // Respond to the initial GET request
    server.respond()
  })

  afterEach(() => {
    // Unmount the component
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(gradingPeriodCollection).parentNode)

    // Restore fake ENV and server
    fakeENV.teardown()
    server.restore()

    // Restore Sinon sandbox
    sandbox.restore()
  })

  test('gets the grading periods from the grading periods controller', () => {
    expect(gradingPeriodCollection.state.periods).toEqual(formattedIndexData.grading_periods)
  })

  test('getPeriods requests the index data from the server', () => {
    const ajaxSpy = sandbox.spy($, 'ajax')
    gradingPeriodCollection.getPeriods()
    expect(ajaxSpy.calledOnce).toBe(true)
  })

  test("renders grading periods with 'readOnly' set to the returned value (false)", () => {
    expect(gradingPeriodCollection.refs.grading_period_1.props.readOnly).toBe(false)
    expect(gradingPeriodCollection.refs.grading_period_2.props.readOnly).toBe(false)
  })

  test("renders grading periods with 'weighted' set to the ENV variable (true)", () => {
    expect(gradingPeriodCollection.refs.grading_period_1.props.weighted).toBe(true)
    expect(gradingPeriodCollection.refs.grading_period_2.props.weighted).toBe(true)
  })

  test("renders grading periods with their individual 'closeDate'", () => {
    expect(gradingPeriodCollection.refs.grading_period_1.props.closeDate).toEqual(
      new Date('2015-06-07T05:00:00Z'),
    )
    expect(gradingPeriodCollection.refs.grading_period_2.props.closeDate).toEqual(
      new Date('2015-09-07T05:00:00Z'),
    )
  })

  test('deleteGradingPeriod calls confirmDelete if the period being deleted is not new (it is saved server side)', () => {
    const confirmDeleteStub = sandbox.stub($.fn, 'confirmDelete')
    gradingPeriodCollection.deleteGradingPeriod('1')
    expect(confirmDeleteStub.calledOnce).toBe(true)
  })

  test('updateGradingPeriodCollection correctly updates the periods state', () => {
    const updatedPeriodComponent = {}
    updatedPeriodComponent.state = {
      id: '1',
      startDate: new Date('2069-03-01T06:00:00Z'),
      endDate: new Date('2070-05-31T05:00:00Z'),
      weight: null,
      title: 'Updating an existing period!',
    }
    updatedPeriodComponent.props = {
      permissions: {
        read: true,
        update: true,
        delete: true,
      },
    }
    gradingPeriodCollection.updateGradingPeriodCollection(updatedPeriodComponent)
    const updatedPeriod = gradingPeriodCollection.state.periods.find(p => p.id === '1')
    expect(updatedPeriod.title).toBe(updatedPeriodComponent.state.title)
  })

  test('getPeriodById returns the period with the matching id (if one exists)', () => {
    const period = gradingPeriodCollection.getPeriodById('1')
    expect(period.id).toBe('1')
  })

  test("given two grading periods that don't overlap, areNoDatesOverlapping returns true", () => {
    expect(
      gradingPeriodCollection.areNoDatesOverlapping(gradingPeriodCollection.state.periods[0]),
    ).toBe(true)
  })

  test('given two overlapping grading periods, areNoDatesOverlapping returns false', () => {
    const startDate = new Date('2015-03-01T06:00:00Z')
    const endDate = new Date('2015-05-31T05:00:00Z')
    const formattedIndexDataOverlapping = [
      {
        id: '1',
        startDate,
        endDate,
        closeDate: endDate,
        weight: null,
        title: 'Spring',
        permissions: {
          read: true,
          update: true,
          delete: true,
        },
      },
      {
        id: '2',
        startDate,
        endDate,
        closeDate: endDate,
        weight: null,
        title: 'Summer',
        permissions: {
          read: true,
          update: true,
          delete: true,
        },
      },
    ]
    gradingPeriodCollection.setState({periods: formattedIndexDataOverlapping})
    expect(
      gradingPeriodCollection.areNoDatesOverlapping(gradingPeriodCollection.state.periods[0]),
    ).toBe(false)
  })

  test.skip('serializeDataForSubmission serializes periods by snake casing keys', () => {
    const firstPeriod = gradingPeriodCollection.state.periods[0]
    const secondPeriod = gradingPeriodCollection.state.periods[1]
    const expectedOutput = {
      grading_periods: [
        {
          id: firstPeriod.id,
          title: firstPeriod.title,
          start_date: firstPeriod.startDate,
          end_date: secondPeriod.endDate,
        },
        {
          id: secondPeriod.id,
          title: secondPeriod.title,
          start_date: secondPeriod.startDate,
          end_date: secondPeriod.endDate,
        },
      ],
    }
    expect(gradingPeriodCollection.serializeDataForSubmission()).toEqual(expectedOutput)
  })

  test('batchUpdatePeriods makes an AJAX call if validations pass', () => {
    const areGradingPeriodsValidStub = sandbox
      .stub(gradingPeriodCollection, 'areGradingPeriodsValid')
      .returns(true)
    const ajaxSpy = sandbox.spy($, 'ajax')
    gradingPeriodCollection.batchUpdatePeriods()
    expect(ajaxSpy.calledOnce).toBe(true)
  })

  test('batchUpdatePeriods does not make an AJAX call if validations fail', () => {
    const areGradingPeriodsValidStub = sandbox
      .stub(gradingPeriodCollection, 'areGradingPeriodsValid')
      .returns(false)
    const ajaxSpy = sandbox.spy($, 'ajax')
    gradingPeriodCollection.batchUpdatePeriods()
    expect(ajaxSpy.notCalled).toBe(true)
  })

  test('isTitleCompleted checks for a title being present', () => {
    const period = {title: 'Spring'}
    expect(gradingPeriodCollection.isTitleCompleted(period)).toBe(true)
  })

  test('isTitleCompleted fails blank titles', () => {
    const period = {title: ' '}
    expect(gradingPeriodCollection.isTitleCompleted(period)).toBe(false)
  })

  test('isStartDateBeforeEndDate passes', () => {
    const period = {
      startDate: new Date('2015-03-01T06:00:00Z'),
      endDate: new Date('2015-05-31T05:00:00Z'),
    }
    expect(gradingPeriodCollection.isStartDateBeforeEndDate(period)).toBe(true)
  })

  test('isStartDateBeforeEndDate fails', () => {
    const period = {
      startDate: new Date('2015-05-31T05:00:00Z'),
      endDate: new Date('2015-03-01T06:00:00Z'),
    }
    expect(gradingPeriodCollection.isStartDateBeforeEndDate(period)).toBe(false)
  })

  test('areDatesValid passes', () => {
    const period = {
      startDate: new Date('2015-03-01T06:00:00Z'),
      endDate: new Date('2015-05-31T05:00:00Z'),
    }
    expect(gradingPeriodCollection.areDatesValid(period)).toBe(true)
  })

  test('areDatesValid fails', () => {
    let period = {
      startDate: new Date('foo'),
      endDate: new Date('foo'),
    }
    expect(gradingPeriodCollection.areDatesValid(period)).toBe(false)
    period = {
      startDate: new Date('foo'),
      endDate: new Date('2015-05-31T05:00:00Z'),
    }
    expect(gradingPeriodCollection.areDatesValid(period)).toBe(false)
    period = {
      startDate: '2015-03-01T06:00:00Z',
      endDate: new Date('foo'),
    }
    expect(gradingPeriodCollection.areDatesValid(period)).toBe(false)
  })

  test('areNoDatesOverlapping periods are not overlapping when endDate of earlier period is the same as start date for the latter', () => {
    const periodOne = {
      id: '1',
      startDate: new Date('2029-03-01T06:00:00Z'),
      endDate: new Date('2030-05-31T05:00:00Z'),
      weight: null,
      title: 'Spring',
      permissions: {
        read: true,
        update: true,
        delete: true,
      },
    }
    const periodTwo = {
      id: 'new2',
      startDate: new Date('2030-05-31T05:00:00Z'),
      endDate: new Date('2031-05-31T05:00:00Z'),
      weight: null,
      title: 'Summer',
      permissions: {
        read: true,
        update: true,
        delete: true,
      },
    }
    gradingPeriodCollection.setState({
      periods: [periodOne, periodTwo],
    })
    expect(gradingPeriodCollection.areNoDatesOverlapping(periodTwo)).toBe(true)
  })

  test('areNoDatesOverlapping periods are overlapping when a period falls within another', () => {
    const periodOne = {
      id: '1',
      startDate: new Date('2029-01-01T00:00:00Z'),
      endDate: new Date('2030-01-01T00:00:00Z'),
      weight: null,
      title: 'Spring',
      permissions: {
        read: true,
        update: true,
        delete: true,
      },
    }
    const periodTwo = {
      id: 'new2',
      startDate: new Date('2029-01-01T00:00:00Z'),
      endDate: new Date('2030-01-01T00:00:00Z'),
      weight: null,
      title: 'Summer',
      permissions: {
        read: true,
        update: true,
        delete: true,
      },
    }
    gradingPeriodCollection.setState({
      periods: [periodOne, periodTwo],
    })
    expect(gradingPeriodCollection.areNoDatesOverlapping(periodTwo)).toBe(false)
  })

  test('areDatesOverlapping adding two periods at the same time that overlap returns true', () => {
    const existingPeriod = gradingPeriodCollection.state.periods[0]
    const periodOne = {
      id: 'new1',
      startDate: new Date('2029-01-01T00:00:00Z'),
      endDate: new Date('2030-01-01T00:00:00Z'),
      title: 'Spring',
      permissions: {
        update: true,
        delete: true,
      },
    }
    const periodTwo = {
      id: 'new2',
      startDate: new Date('2029-01-01T00:00:00Z'),
      endDate: new Date('2030-01-01T00:00:00Z'),
      title: 'Summer',
      permissions: {
        update: true,
        delete: true,
      },
    }
    gradingPeriodCollection.setState({
      periods: [existingPeriod, periodOne, periodTwo],
    })
    expect(gradingPeriodCollection.areDatesOverlapping(existingPeriod)).toBe(false)
    expect(gradingPeriodCollection.areDatesOverlapping(periodOne)).toBe(true)
    expect(gradingPeriodCollection.areDatesOverlapping(periodTwo)).toBe(true)
  })

  test.skip('renderSaveButton does not render a button if the user cannot update any of the periods on the page', () => {
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
          delete: false,
        },
      },
    ]
    gradingPeriodCollection.setState({periods: uneditable})
    expect(gradingPeriodCollection.renderSaveButton()).toBeFalsy()

    Object.assign(uneditable[0].permissions, {
      update: true,
      delete: false,
    })
    gradingPeriodCollection.setState({periods: uneditable})
    expect(gradingPeriodCollection.renderSaveButton()).toBeFalsy()

    Object.assign(uneditable[0].permissions, {
      delete: true,
    })
    gradingPeriodCollection.setState({periods: uneditable})
    expect(gradingPeriodCollection.renderSaveButton()).toBeFalsy()
  })

  test('renderSaveButton renders a button if the user is not at the course grading periods page', () => {
    expect(gradingPeriodCollection.renderSaveButton()).toBeTruthy()
  })
})

describe('GradingPeriodCollection with read-only grading periods', () => {
  let sandbox
  let server
  let gradingPeriodCollection
  let indexData

  beforeEach(() => {
    // Create a Sinon sandbox
    sandbox = sinon.createSandbox()

    // Create a fake server
    server = sinon.fakeServer.create()
    fakeENV.setup()

    // Set ENV variables
    window.ENV = window.ENV || {}
    window.ENV.current_user_roles = ['admin']
    window.ENV.GRADING_PERIODS_URL = '/api/v1/accounts/1/grading_periods'
    window.ENV.GRADING_PERIODS_WEIGHTED = false

    // Define test data
    indexData = {
      grading_periods: [
        {
          id: '1',
          start_date: '2015-03-01T06:00:00Z',
          end_date: '2015-05-31T05:00:00Z',
          weight: null,
          title: 'Spring',
          permissions: {
            update: true,
            delete: true,
          },
        },
      ],
      grading_periods_read_only: true,
      can_create_grading_periods: true,
    }

    // Setup fake server responses
    server.respondWith('GET', window.ENV.GRADING_PERIODS_URL, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(indexData),
    ])

    // Render the component
    const GradingPeriodCollectionElement = <GradingPeriodCollection />
    gradingPeriodCollection = TestUtils.renderIntoDocument(GradingPeriodCollectionElement)

    // Respond to the initial GET request
    server.respond()
  })

  afterEach(() => {
    // Unmount the component
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(gradingPeriodCollection).parentNode)

    // Restore fake ENV and server
    fakeENV.teardown()
    server.restore()

    // Restore Sinon sandbox
    sandbox.restore()
  })

  test("renders grading periods with 'readOnly' set to true", () => {
    expect(gradingPeriodCollection.refs.grading_period_1.props.readOnly).toBe(true)
  })

  test("renders grading periods with 'weighted' set to the ENV variable (false)", () => {
    expect(gradingPeriodCollection.refs.grading_period_1.props.weighted).toBe(false)
  })
})
