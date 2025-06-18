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
import $ from 'jquery'
import {render} from '@testing-library/react'
import CourseTabContainer from '../CourseTabContainer'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import 'jqueryui/tabs'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock the child components to avoid their AJAX calls
jest.mock('../gradingPeriodCollection', () => {
  return function MockGradingPeriodCollection() {
    return <div data-testid="grading-period-collection">Grading Period Collection</div>
  }
})

jest.mock('@canvas/grading-standard-collection', () => {
  return function MockGradingStandardCollection() {
    return <div data-testid="grading-standard-collection">Grading Standard Collection</div>
  }
})

const renderCourseTabContainer = (props = {}) => render(<CourseTabContainer {...props} />)

describe('CourseTabContainer', () => {
  beforeEach(() => {
    fakeENV.setup({
      GRADING_PERIODS_URL: '/api/v1/courses/1/grading_periods',
      GRADING_STANDARDS_URL: '/api/v1/courses/1/grading_standards',
      current_user_roles: ['admin'],
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.restoreAllMocks()
  })

  it('tabs are present when there are grading periods', () => {
    const {getByTestId} = renderCourseTabContainer({hasGradingPeriods: true})
    const tabs = getByTestId('grading-tabs')
    expect(tabs).toBeInTheDocument()
    expect(getByTestId('grading-periods-tab-link')).toBeInTheDocument()
    expect(getByTestId('grading-standards-tab-link')).toBeInTheDocument()
  })

  it('tabs are not present when there are no grading periods', () => {
    const {container} = renderCourseTabContainer({hasGradingPeriods: false})
    expect(container.querySelector('.ui-tabs')).not.toBeInTheDocument()
  })

  it('jquery-ui tabs() is called when there are grading periods', () => {
    const tabsSpy = jest.spyOn($.fn, 'tabs')
    renderCourseTabContainer({hasGradingPeriods: true})
    expect(tabsSpy).toHaveBeenCalled()
    tabsSpy.mockRestore()
  })

  it('jquery-ui tabs() is not called when there are no grading periods', () => {
    const tabsSpy = jest.spyOn($.fn, 'tabs')
    renderCourseTabContainer({hasGradingPeriods: false})
    expect(tabsSpy).not.toHaveBeenCalled()
    tabsSpy.mockRestore()
  })

  it('does not render grading periods if there are no grading periods', () => {
    const {queryByText} = renderCourseTabContainer({hasGradingPeriods: false})
    expect(queryByText('Grading Periods')).not.toBeInTheDocument()
  })

  it('renders the grading periods if there are grading periods', () => {
    const {getByTestId} = renderCourseTabContainer({hasGradingPeriods: true})
    expect(getByTestId('grading-periods-tab-link')).toHaveTextContent('Grading Periods')
  })

  it('renders the grading standards if there are no grading periods', () => {
    const {getByText} = renderCourseTabContainer({hasGradingPeriods: false})
    expect(getByText('Grading Schemes')).toBeInTheDocument()
  })

  it('renders the grading standards if there are grading periods', () => {
    const {getByTestId} = renderCourseTabContainer({hasGradingPeriods: true})
    expect(getByTestId('grading-standards-tab-link')).toHaveTextContent('Grading Schemes')
  })
})
