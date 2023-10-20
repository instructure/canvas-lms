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
import {render} from '@testing-library/react'
import K5DashboardCard, {
  DashboardCardHeaderHero,
  LatestAnnouncementLink,
  AssignmentLinks,
} from '../K5DashboardCard'
import K5DashboardContext from '@canvas/k5/react/K5DashboardContext'

const defaultContext = {
  assignmentsDueToday: {},
  assignmentsMissing: {},
  assignmentsCompletedForToday: {},
  loadingAnnouncements: false,
  loadingOpportunities: false,
  isStudent: true,
  subjectAnnouncements: [],
}

const defaultProps = {
  id: 'test',
  href: '/courses/test',
  shortName: 'test course',
}

describe('DashboardCardHeaderHero', () => {
  const heroProps = {
    backgroundColor: '#FFFFFF',
    onClick: () => {},
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
    const subjectAnnouncements = [
      {
        id: '55',
        context_code: 'course_test',
        html_url: '/courses/test/discussion_topics/55',
        title: 'How do you do, fellow kids?',
      },
    ]
    const {findByText} = render(
      <K5DashboardContext.Provider value={{...defaultContext, subjectAnnouncements}}>
        <K5DashboardCard {...defaultProps} />
      </K5DashboardContext.Provider>
    )
    const linkText = await findByText('How do you do, fellow kids?')
    const link = linkText.closest('a')
    expect(link.href).toBe('http://localhost/courses/test/discussion_topics/55')
  })

  it('displays "Nothing due today" if no assignments are due today', async () => {
    const {findByText} = render(
      <K5DashboardContext.Provider value={defaultContext}>
        <K5DashboardCard {...defaultProps} />
      </K5DashboardContext.Provider>
    )
    const message = await findByText('Nothing due today')
    expect(message).toBeInTheDocument()
  })

  it('displays a link to the schedule tab if any assignments are due today', async () => {
    const {findByRole} = render(
      <K5DashboardContext.Provider value={{...defaultContext, assignmentsDueToday: {test: 3}}}>
        <K5DashboardCard {...defaultProps} />
      </K5DashboardContext.Provider>
    )
    const link = await findByRole('link', {name: 'View 3 items due today for course test course'})
    expect(link).toBeInTheDocument()
    expect(link.getAttribute('href')).toMatch('/courses/test?focusTarget=today#schedule')
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
    const {findByRole} = render(
      <K5DashboardContext.Provider value={{...defaultContext, assignmentsMissing: {test: 2}}}>
        <K5DashboardCard {...defaultProps} />
      </K5DashboardContext.Provider>
    )
    const link = await findByRole('link', {name: 'View 2 missing items for course test course'})
    expect(link).toBeInTheDocument()
    expect(link.getAttribute('href')).toMatch('/courses/test?focusTarget=missing-items#schedule')
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

  it('defaults color if no course color or image are provided', () => {
    const {getByTestId} = render(<K5DashboardCard {...defaultProps} />)
    expect(getByTestId('k5-dashboard-card-hero').style.getPropertyValue('background-color')).toBe(
      'rgb(57, 75, 88)'
    )
  })
})

describe('LatestAnnouncementLink', () => {
  it('renders loading skeleton while loading', () => {
    const {getByText, queryByText} = render(
      <LatestAnnouncementLink courseId="1" loading={true} color="red" />
    )
    expect(getByText('Loading latest announcement link')).toBeInTheDocument()
    expect(queryByText('New announcement', {exact: false})).not.toBeInTheDocument()
  })
})

describe('AssignmentLinks', () => {
  it('renders loading skeleton while loading', () => {
    const {getByText, queryByText} = render(
      <AssignmentLinks id="1" loading={true} color="red" courseName="test" numMissing={2} />
    )
    expect(getByText('Loading missing assignments link')).toBeInTheDocument()
    expect(queryByText('2 missing')).not.toBeInTheDocument()
  })
})
