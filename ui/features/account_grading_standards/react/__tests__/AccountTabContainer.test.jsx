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

import $ from 'jquery'
import axios from '@canvas/axios'
import {render, screen} from '@testing-library/react'
import AccountTabContainer from '../AccountTabContainer'

const defaultProps = (props = {}) => ({
  readOnly: false,
  urls: {
    gradingPeriodSetsURL: 'api/v1/accounts/1/grading_period_sets',
    gradingPeriodsUpdateURL:
      'api/v1/grading_period_sets/%7B%7B%20set_id%20%7D%7D/grading_periods/batch_update',
    enrollmentTermsURL: 'api/v1/accounts/1/enrollment_terms',
    deleteGradingPeriodURL: 'api/v1/accounts/1/grading_periods/%7B%7B%20id%20%7D%7D',
  },
  ...props,
})

const renderAccountTabContainer = (props = {}) =>
  render(<AccountTabContainer {...defaultProps(props)} />)

describe('AccountTabContainer', () => {
  beforeEach(() => {
    jest.spyOn(axios, 'get').mockImplementation(() => Promise.resolve({}))
    jest.spyOn($, 'ajax').mockImplementation(() => ({done() {}}))
  })

  it('tabs are present', () => {
    const {container} = renderAccountTabContainer()

    expect(container.querySelectorAll('.ui-tabs-nav')).toHaveLength(1)
    expect(container.querySelectorAll('.ui-tabs-nav li')).toHaveLength(2)
  })

  it('default tab is expanded', () => {
    const {container} = renderAccountTabContainer()

    const tabpanels = container.querySelectorAll('.ui-tabs-panel')

    expect(tabpanels[0].textContent).toContain('Grading Periods')
    expect(tabpanels[0].getAttribute('aria-hidden')).toBe('false')
    expect(tabpanels[0].getAttribute('aria-expanded')).toBe('true')
    expect(tabpanels[1].getAttribute('aria-hidden')).toBe('true')
    expect(tabpanels[1].getAttribute('aria-expanded')).toBe('false')
  })

  it('jquery-ui tabs() is called', () => {
    jest.spyOn($.fn, 'tabs')

    renderAccountTabContainer()

    expect($.fn.tabs).toHaveBeenCalled()
  })

  it('renders the grading periods', () => {
    renderAccountTabContainer()

    expect(screen.getByText('Grading Periods')).toBeTruthy()
  })

  it('renders the grading standards', () => {
    renderAccountTabContainer()

    expect(screen.getByText('Grading Schemes')).toBeTruthy()
  })
})
