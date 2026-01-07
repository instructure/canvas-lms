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

import {vi} from 'vitest'
import {TAB_IDS} from '@canvas/k5/react/utils'
import {render} from '@testing-library/react'
import React from 'react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {K5Course} from '../K5Course'
import {MOCK_GROUPS} from './mocks'
import fakeENV from '@canvas/test-utils/fakeENV'
import {
  defaultProps,
  defaultEnv,
  createModulesPartial,
  cleanupModulesContainer,
} from './K5CourseTestHelpers'
import {
  MOCK_COURSE_SYLLABUS,
  MOCK_COURSE_APPS,
  MOCK_COURSE_TABS,
  MOCK_GRADING_PERIODS_EMPTY,
  MOCK_ASSIGNMENT_GROUPS,
  MOCK_ENROLLMENTS,
} from './mocks'

vi.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: vi.fn(),
}))

const server = setupServer()

beforeAll(() => {
  server.listen()
})

afterAll(() => {
  server.close()
})

beforeEach(() => {
  server.use(
    http.get('*/api/v1/courses/30', ({request}) => {
      const url = new URL(request.url)
      const include = url.searchParams.getAll('include[]')
      if (include.includes('syllabus_body')) {
        return HttpResponse.json(MOCK_COURSE_SYLLABUS)
      }
      if (include.includes('grading_periods')) {
        if (include.includes('observed_users')) {
          return HttpResponse.json(MOCK_GRADING_PERIODS_EMPTY)
        }
        return HttpResponse.json(MOCK_GRADING_PERIODS_EMPTY)
      }
      return HttpResponse.json({})
    }),
    http.get('*/api/v1/external_tools/visible_course_nav_tools', () => {
      return HttpResponse.json(MOCK_COURSE_APPS)
    }),
    http.get('*/api/v1/courses/30/tabs', () => {
      return HttpResponse.json(MOCK_COURSE_TABS)
    }),
    http.get('*/api/v1/courses/30/assignment_groups', () => {
      return HttpResponse.json(MOCK_ASSIGNMENT_GROUPS)
    }),
    http.get('*/api/v1/courses/30/enrollments', () => {
      return HttpResponse.json(MOCK_ENROLLMENTS)
    }),
    http.get('*/api/v1/announcements', () => {
      return HttpResponse.json([])
    }),
    http.get('*/api/v1/courses/30/groups', () => {
      return HttpResponse.json(MOCK_GROUPS)
    }),
  )
  fakeENV.setup(defaultEnv)
  document.body.appendChild(createModulesPartial())
})

afterEach(() => {
  fakeENV.teardown()
  cleanupModulesContainer()
  localStorage.clear()
  server.resetHandlers()
  window.location.hash = ''
})

describe('K-5 Subject Course', () => {
  describe('Tabs Header', () => {
    const bannerImageUrl = 'https://example.com/path/to/banner.jpeg'
    const cardImageUrl = 'https://example.com/path/to/image.png'

    it('displays a huge version of the course banner image if set', () => {
      const {getByTestId} = render(
        <K5Course {...defaultProps} bannerImageUrl={bannerImageUrl} cardImageUrl={cardImageUrl} />,
      )
      const hero = getByTestId('k5-course-header-hero')

      expect(hero).toBeInTheDocument()
      expect(hero.style.getPropertyValue('background-image')).toBe(`url(${bannerImageUrl})`)
    })

    it('displays a huge version of the course card image if set and no banner image is set', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} cardImageUrl={cardImageUrl} />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero).toBeInTheDocument()
      expect(hero.style.getPropertyValue('background-image')).toBe(`url(${cardImageUrl})`)
    })

    it('displays the course color if one is set but no course images are set', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} color="#bb8" />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero.style.getPropertyValue('background-color')).toBe('rgb(187, 187, 136)')
    })

    it('displays a gray background on the hero header if no course color or images are set', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero.style.getPropertyValue('background-color')).toBe('rgb(51, 68, 81)')
    })

    it('displays the course name', () => {
      const {getByText} = render(<K5Course {...defaultProps} />)
      expect(getByText(defaultProps.name)).toBeInTheDocument()
    })

    it('shows Home, Schedule, Modules, Grades, and Resources options if configured', () => {
      const {getByText} = render(<K5Course {...defaultProps} />)
      ;['Home', 'Schedule', 'Modules', 'Grades', 'Resources'].forEach(label => {
        expect(getByText(label)).toBeInTheDocument()
        expect(getByText('Arts and Crafts ' + label)).toBeInTheDocument()
      })
    })

    it('defaults to the first tab', () => {
      const {getByRole} = render(<K5Course {...defaultProps} />)
      expect(getByRole('tab', {name: 'Arts and Crafts Home', selected: true})).toBeInTheDocument()
    })

    it('only renders non-hidden tabs, in the order they are provided', () => {
      const tabs = [
        {id: '10'},
        {id: '5', hidden: true},
        {id: '19'},
        {id: 'context_external_tool_3', hidden: true},
      ]
      const {getAllByRole} = render(
        <K5Course {...defaultProps} tabs={tabs} hasSyllabusBody={false} />,
      )
      const renderedTabs = getAllByRole('tab')
      expect(renderedTabs.map(({id}) => id.replace('tab-', ''))).toEqual([
        TAB_IDS.MODULES,
        TAB_IDS.SCHEDULE,
      ])
    })

    it('still renders Resource tab if course has no LTIs but has Important Info', () => {
      const tabs = [{id: '10'}, {id: '5'}, {id: '19'}]
      const {getByText} = render(<K5Course {...defaultProps} tabs={tabs} />)
      expect(getByText('Resources')).toBeInTheDocument()
      expect(getByText('Arts and Crafts Resources')).toBeInTheDocument()
    })

    it('does not render Resource tab if course has no LTIs nor Important Info', () => {
      const tabs = [{id: '10'}, {id: '5'}, {id: '19'}]
      const {queryByText} = render(
        <K5Course {...defaultProps} tabs={tabs} hasSyllabusBody={false} />,
      )
      expect(queryByText('Resources')).not.toBeInTheDocument()
      expect(queryByText('Arts and Crafts Resources')).not.toBeInTheDocument()
    })

    it('renders an empty state instead of any tabs if none are provided', () => {
      const {getByTestId, getByText, queryByRole} = render(
        <K5Course {...defaultProps} tabs={[]} hasSyllabusBody={false} />,
      )
      expect(getByText(defaultProps.name)).toBeInTheDocument()
      expect(queryByRole('tab')).not.toBeInTheDocument()
      expect(getByTestId('space-panda')).toBeInTheDocument()
      expect(getByText('Welcome to the cold, dark void of Arts and Crafts.')).toBeInTheDocument()
    })

    it('renders a link to update tab settings if no tabs are provided and the user has manage permissions', () => {
      const {getByRole} = render(
        <K5Course {...defaultProps} canManage={true} tabs={[]} hasSyllabusBody={false} />,
      )
      const link = getByRole('link', {name: 'Reestablish your world'})
      expect(link).toBeInTheDocument()
      expect(link.href).toBe('http://localhost/courses/30/settings#tab-navigation')
    })

    it('does not render anything when tabContentOnly is true', () => {
      const {queryByText} = render(<K5Course {...defaultProps} tabContentOnly={true} />)

      // Course hero shouldn't be shown
      expect(queryByText(defaultProps.name)).not.toBeInTheDocument()

      // Tabs should not be shown
      ;['Home', 'Schedule', 'Modules', 'Grades', 'Resources', 'Groups'].forEach(t =>
        expect(queryByText(t)).not.toBeInTheDocument(),
      )
    })
  })
})
