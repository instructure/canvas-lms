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
import $ from 'jquery'
import _ from 'underscore'
import GradingPeriod from 'jsx/grading/gradingPeriod'
import fakeENV from 'helpers/fakeENV'
import DateHelper from 'jsx/shared/helpers/dateHelper'
import 'jquery.instructure_misc_plugins'
import 'compiled/jquery.rails_flash_notifications'

const wrapper = document.getElementById('fixtures')

QUnit.module('GradingPeriod', {
  setup() {
    sandbox.stub($, 'flashMessage')
    sandbox.stub($, 'flashError')
    this.server = sinon.fakeServer.create()
    fakeENV.setup()
    ENV.GRADING_PERIODS_URL = 'api/v1/courses/1/grading_periods'
    this.updatedPeriodData = {
      grading_periods: [
        {
          id: '1',
          title: 'Updated Grading Period!',
          startDate: '2015-03-01T06:00:00Z',
          endDate: '2015-05-31T05:00:00Z',
          closeDate: '2015-06-07T05:00:00Z',
          weight: null,
          permissions: {
            update: true,
            delete: true
          }
        }
      ]
    }
    this.server.respondWith('PUT', `${ENV.GRADING_PERIODS_URL}/1`, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(this.updatedPeriodData)
    ])
    return this.server.respond()
  },
  renderComponent(opts = {}) {
    const exampleProps = {
      id: '1',
      title: 'Spring',
      startDate: new Date('2015-03-01T00:00:00Z'),
      endDate: new Date('2015-05-31T00:00:00Z'),
      closeDate: new Date('2015-06-07T00:00:00Z'),
      weight: 50,
      weighted: true,
      disabled: false,
      readOnly: false,
      permissions: {
        read: true,
        update: true,
        create: true,
        delete: true
      },
      onDeleteGradingPeriod() {},
      updateGradingPeriodCollection: sinon.spy()
    }
    const props = _.defaults(opts, exampleProps)
    const GradingPeriodElement = <GradingPeriod {...props} />
    return ReactDOM.render(GradingPeriodElement, wrapper)
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
    ENV.GRADING_PERIODS_URL = null
    return this.server.restore()
  }
})

test('sets initial state properly', function() {
  const gradingPeriod = this.renderComponent()
  equal(gradingPeriod.state.title, 'Spring')
  deepEqual(gradingPeriod.state.startDate, new Date('2015-03-01T00:00:00Z'))
  deepEqual(gradingPeriod.state.endDate, new Date('2015-05-31T00:00:00Z'))
  equal(gradingPeriod.state.weight, 50)
})

test('onDateChange calls replaceInputWithDate', function() {
  const gradingPeriod = this.renderComponent()
  const replaceInputWithDate = sandbox.stub(gradingPeriod, 'replaceInputWithDate')
  gradingPeriod.onDateChange('startDate', 'period_start_date_1')
  ok(replaceInputWithDate.calledOnce)
})

test('onDateChange calls updateGradingPeriodCollection', function() {
  const gradingPeriod = this.renderComponent()
  gradingPeriod.onDateChange('startDate', 'period_start_date_1')
  ok(gradingPeriod.props.updateGradingPeriodCollection.calledOnce)
})

test('onTitleChange changes the title state', function() {
  const gradingPeriod = this.renderComponent()
  const fakeEvent = {
    target: {
      name: 'title',
      value: 'MXP: Most Xtreme Primate'
    }
  }
  gradingPeriod.onTitleChange(fakeEvent)
  equal(gradingPeriod.state.title, 'MXP: Most Xtreme Primate')
})

test('onTitleChange calls updateGradingPeriodCollection', function() {
  const gradingPeriod = this.renderComponent()
  const fakeEvent = {
    target: {
      name: 'title',
      value: 'MXP: Most Xtreme Primate'
    }
  }
  gradingPeriod.onTitleChange(fakeEvent)
  ok(gradingPeriod.props.updateGradingPeriodCollection.calledOnce)
})

test('replaceInputWithDate calls formatDatetimeForDisplay', function() {
  const gradingPeriod = this.renderComponent()
  const formatDatetime = sandbox.stub(DateHelper, 'formatDatetimeForDisplay')
  const fakeDateElement = {
    val() {}
  }
  gradingPeriod.replaceInputWithDate('startDate', fakeDateElement)
  ok(formatDatetime.calledOnce)
})

test("assigns the 'readOnly' property on the template when false", function() {
  const gradingPeriod = this.renderComponent()
  equal(gradingPeriod.refs.template.props.readOnly, false)
})

test("assigns the 'readOnly' property on the template when true", function() {
  const gradingPeriod = this.renderComponent({readOnly: true})
  equal(gradingPeriod.refs.template.props.readOnly, true)
})

test("assigns the 'weight' and 'weighted' properties", function() {
  const gradingPeriod = this.renderComponent()
  equal(gradingPeriod.refs.template.props.weight, 50)
  equal(gradingPeriod.refs.template.props.weighted, true)
})

test("assigns the 'weight' and 'weighted' properties when weighted is false", function() {
  const gradingPeriod = this.renderComponent({weighted: false})
  equal(gradingPeriod.refs.template.props.weight, 50)
  equal(gradingPeriod.refs.template.props.weighted, false)
})

test("assigns the 'closeDate' property", function() {
  const gradingPeriod = this.renderComponent()
  deepEqual(gradingPeriod.refs.template.props.closeDate, new Date('2015-06-07T00:00:00Z'))
})

test("assigns 'endDate' as 'closeDate' when 'closeDate' is not defined", function() {
  const gradingPeriod = this.renderComponent({closeDate: null})
  deepEqual(gradingPeriod.refs.template.props.closeDate, new Date('2015-05-31T00:00:00Z'))
})
