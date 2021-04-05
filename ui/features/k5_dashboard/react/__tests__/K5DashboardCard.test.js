/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import fetchMock from 'fetch-mock'
import {render} from '@testing-library/react'
import K5DashboardCard, {
  DashboardCardHeaderHero,
  LatestAnnouncementLink,
  AssignmentLinks
} from '../K5DashboardCard'
import K5DashboardContext from '@canvas/k5/react/K5DashboardContext'

import {TAB_IDS} from '@canvas/k5/react/utils'

const defaultContext = {
  assignmentsDueToday: {},
  assignmentsMissing: {},
  assignmentsCompletedForToday: {},
  isStudent: true
}

const defaultProps = {
  id: 'test',
  href: '/courses/5',
  originalName: 'test course',
  requestTabChange: () => {}
}

beforeEach(() => {
  fetchMock.get('/api/v1/announcements?context_codes=course_test&active_only=true&per_page=1', '[]')
})

afterEach(() => {
  fetchMock.restore()
})

describe('DashboardCardHeaderHero', () => {
  const heroProps = {
    backgroundColor: '#FFFFFF',
    onClick: () => {}
  }
  it("doesn't add instFS query params if it doesnt use an inst-fs url", () => {
    const {getByTestId} = render(
      <DashboardCardHeaderHero {...heroProps} image="https://example.com/path/to/image.png" />
    )
    expect(getByTestId('k5-dashboard-card-hero').style.getPropertyValue('background-image')).toBe(
      'url(https://example.com/path/to/image.png)'
    )
  })

  it('adds instFS query params if it does use an inst-fs url', () => {
    const {getByTestId} = render(
      <DashboardCardHeaderHero
        {...heroProps}
        image="https://inst-fs-iad-beta.inscloudgate.net/files/blah/foo?download=1&token=abcxyz"
      />
    )
    expect(getByTestId('k5-dashboard-card-hero').style.getPropertyValue('background-image')).toBe(
      'url(https://inst-fs-iad-beta.inscloudgate.net/files/blah/foo?download=1&token=abcxyz&geometry=300x150)'
    )
  })

  it('shows the background color if no image is provided', () => {
    const {getByTestId} = render(<DashboardCardHeaderHero {...heroProps} />)
    expect(getByTestId('k5-dashboard-card-hero').style.getPropertyValue('background-color')).toBe(
      'rgb(255, 255, 255)'
    )
  })
})

describe('K-5 Dashboard Card', () => {
  it('renders a link with the courses title', () => {
    const {getByText} = render(<K5DashboardCard {...defaultProps} />)
    expect(getByText('test course')).toBeInTheDocument()
  })

  it('displays a link to the latest announcement if one exists', async () => {
    fetchMock.get(
      '/api/v1/announcements?context_codes=course_test&active_only=true&per_page=1',
      JSON.stringify([
        {
          id: '55',
          html_url: '/courses/test/discussion_topics/55',
          title: 'How do you do, fellow kids?'
        }
      ]),
      {overwriteRoutes: true}
    )
    const {findByText} = render(<K5DashboardCard {...defaultProps} />)
    const linkText = await findByText('How do you do, fellow kids?')
    const link = linkText.closest('a')
    expect(link.href).toBe('http://localhost/courses/test/discussion_topics/55')
  })

  it('displays "Nothing due today" if no assignments are due today', async () => {
    const {findByText} = render(
      <K5DashboardContext.Provider value={{...defaultContext}}>
        <K5DashboardCard {...defaultProps} />
      </K5DashboardContext.Provider>
    )
    const message = await findByText('Nothing due today')
    expect(message).toBeInTheDocument()
  })

  it('displays a link to the schedule tab if any assignments are due today', async () => {
    const requestTabChange = jest.fn()
    const {findByText} = render(
      <K5DashboardContext.Provider value={{...defaultContext, assignmentsDueToday: {test: 3}}}>
        <K5DashboardCard {...defaultProps} requestTabChange={requestTabChange} />
      </K5DashboardContext.Provider>
    )
    const link = await findByText('3 due today')
    link.click()
    expect(requestTabChange).toHaveBeenCalledWith(TAB_IDS.SCHEDULE)
  })

  it('displays "Nothing else due" if all assignments due today are completed', async () => {
    const {findByText, queryByText} = render(
      <K5DashboardContext.Provider
        value={{...defaultContext, assignmentsCompletedForToday: {test: 2}}}
      >
        <K5DashboardCard {...defaultProps} />
      </K5DashboardContext.Provider>
    )
    expect(await findByText('Nothing else due')).toBeInTheDocument()
    expect(queryByText('Nothing due today')).not.toBeInTheDocument()
  })

  it('displays a link to the schedule tab if any assignments are missing', async () => {
    const requestTabChange = jest.fn()
    const {findByText} = render(
      <K5DashboardContext.Provider value={{...defaultContext, assignmentsMissing: {test: 2}}}>
        <K5DashboardCard {...defaultProps} requestTabChange={requestTabChange} />
      </K5DashboardContext.Provider>
    )
    const link = await findByText('2 missing')
    link.click()
    expect(requestTabChange).toHaveBeenCalledWith(TAB_IDS.SCHEDULE)
  })

  it("doesn't display anything in the assignment links section if the user is not a student", async () => {
    const requestTabChange = jest.fn()
    const {queryByText} = render(
      <K5DashboardContext.Provider value={{...defaultContext, isStudent: false}}>
        <K5DashboardCard {...defaultProps} requestTabChange={requestTabChange} />
      </K5DashboardContext.Provider>
    )
    expect(queryByText('Nothing due today')).not.toBeInTheDocument()
  })
})

describe('LatestAnnouncementLink', () => {
  it('renders loading skeleton while loading', () => {
    const {getByText, queryByText} = render(<LatestAnnouncementLink loading color="red" />)
    expect(getByText('Loading latest announcement link')).toBeInTheDocument()
    expect(queryByText('New announcement', {exact: false})).not.toBeInTheDocument()
  })
})

describe('AssignmentLinks', () => {
  it('renders loading skeleton while loading', () => {
    const {getByText, queryByText} = render(
      <AssignmentLinks loading color="red" requestTabChange={jest.fn()} numMissing={2} />
    )
    expect(getByText('Loading missing assignments link')).toBeInTheDocument()
    expect(queryByText('2 missing')).not.toBeInTheDocument()
  })
})
