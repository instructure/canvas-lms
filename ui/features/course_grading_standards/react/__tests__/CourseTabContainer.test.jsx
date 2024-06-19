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
import {render, screen} from '@testing-library/react'
import CourseTabContainer from '../CourseTabContainer'

const renderCourseTabContainer = (props = {}) => render(<CourseTabContainer {...props} />)

describe('CourseTabContainer', () => {
  beforeEach(() => {
    jest
      .spyOn($, 'getJSON')
      .mockImplementation(() => ({success: () => ({error: () => {}}), done: () => {}}))
  })

  it('tabs are present when there are grading periods', () => {
    renderCourseTabContainer({hasGradingPeriods: true})

    expect(screen.getAllByRole('tablist')).toHaveLength(1)
    expect(screen.getAllByRole('tab')).toHaveLength(2)
  })

  it('tabs are not present when there are no grading periods', () => {
    const {container} = renderCourseTabContainer({hasGradingPeriods: false})

    expect(container.querySelector('.ui-tabs')).not.toBeInTheDocument()
  })

  it('jquery-ui tabs() is called when there are grading periods', () => {
    const tabsSpy = jest.spyOn($.fn, 'tabs')

    renderCourseTabContainer({hasGradingPeriods: true})

    expect(tabsSpy).toHaveBeenCalled()
  })

  it('jquery-ui tabs() is not called when there are no grading periods', () => {
    const tabsSpy = jest.spyOn($.fn, 'tabs')

    renderCourseTabContainer({hasGradingPeriods: false})

    expect(tabsSpy).not.toHaveBeenCalled()
  })

  it('does not render grading periods if there are no grading periods', () => {
    renderCourseTabContainer({hasGradingPeriods: false})

    expect(screen.queryByText('Grading Periods')).not.toBeInTheDocument()
  })

  it('renders the grading periods if there are grading periods', () => {
    renderCourseTabContainer({hasGradingPeriods: true})

    expect(screen.getByText('Grading Periods')).toBeInTheDocument()
  })

  it('renders the grading standards if there are no grading periods', () => {
    renderCourseTabContainer({hasGradingPeriods: false})

    expect(screen.getByText('Grading Schemes')).toBeInTheDocument()
  })

  it('renders the grading standards if there are grading periods', () => {
    renderCourseTabContainer({hasGradingPeriods: true})

    expect(screen.getByText('Grading Schemes')).toBeInTheDocument()
  })
})
