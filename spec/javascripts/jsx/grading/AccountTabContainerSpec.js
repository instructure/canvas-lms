/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {mount} from 'enzyme'
import $ from 'jquery'
import axios from 'axios'
import _ from 'underscore'
import AccountTabContainer from 'jsx/grading/AccountTabContainer'
import 'jqueryui/tabs'

QUnit.module('AccountTabContainer', {
  renderComponent(props = {}) {
    const defaults = {
      readOnly: false,
      urls: {
        gradingPeriodSetsURL: 'api/v1/accounts/1/grading_period_sets',
        gradingPeriodsUpdateURL:
          'api/v1/grading_period_sets/%7B%7B%20set_id%20%7D%7D/grading_periods/batch_update',
        enrollmentTermsURL: 'api/v1/accounts/1/enrollment_terms',
        deleteGradingPeriodURL: 'api/v1/accounts/1/grading_periods/%7B%7B%20id%20%7D%7D'
      }
    }
    const mergedProps = _.defaults(props, defaults)

    this.wrapper = mount(<AccountTabContainer {...mergedProps} />)
  },

  setup() {
    const response = {}
    const successPromise = new Promise(resolve => resolve(response))
    sandbox.stub(axios, 'get').returns(successPromise)
    sandbox.stub($, 'ajax').returns({done() {}})
  },

  teardown() {
    this.wrapper.unmount()
  }
})

test('tabs are present', function() {
  this.renderComponent()
  const $el = this.wrapper.getDOMNode()
  strictEqual($el.querySelectorAll('.ui-tabs').length, 1)
  strictEqual($el.querySelectorAll('.ui-tabs ul.ui-tabs-nav li').length, 2)
  equal($el.querySelector('#grading-periods-tab').getAttribute('style'), 'display: block;')
  equal($el.querySelector('#grading-standards-tab').getAttribute('style'), 'display: none;')
})

test('jquery-ui tabs() is called', function() {
  const tabsSpy = sandbox.spy($.fn, 'tabs')
  this.renderComponent()
  ok(tabsSpy.calledOnce)
})

test('renders the grading periods', function() {
  this.renderComponent()
  ok(this.wrapper.at(0).instance().gradingPeriods)
})

test('renders the grading standards', function() {
  this.renderComponent()
  ok(this.wrapper.at(0).instance().gradingStandards)
})
