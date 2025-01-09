/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, screen, fireEvent} from '@testing-library/react'
import $ from 'jquery'
import StudentContextTray from '../StudentContextTray'

describe('StudentContextTray', () => {
  let props
  let user
  let course
  let analytics

  beforeEach(() => {
    props = {
      data: {loading: true},
      returnFocusTo: () => {},
      courseId: '1',
      studentId: '1',
    }

    user = {
      _id: '1',
      short_name: 'wooper',
      enrollments: [
        {
          state: 'active',
          section: {name: 'Section 1'},
          grades: {
            current_grade: 'A',
            current_score: 95,
          },
        },
      ],
      avatar_url: 'avatar.jpg',
    }

    course = {
      _id: '1',
      name: 'Test Course',
      permissions: {
        view_analytics: true,
        become_user: true,
        send_messages: true,
      },
      submissionsConnection: {edges: []},
      allowFinalGradeOverride: false,
    }

    analytics = {
      participations: {level: 2},
      page_views: {level: 3},
      tardiness_breakdown: {
        missing: 0,
        late: 0,
      },
    }

    const container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
  })

  afterEach(() => {
    const fixtures = document.getElementById('fixtures')
    if (fixtures) {
      fixtures.remove()
    }
  })

  it('sets focus back to the returnFocusTo element', () => {
    const button = document.createElement('button')
    button.id = 'someButton'
    document.getElementById('fixtures').appendChild(button)

    props.returnFocusTo = () => {
      const $button = $(button)
      $button.focus = () => {
        button.focus()
        return true
      }
      $button.is = () => true
      return [$button]
    }

    const userWithAnalytics = {...user, analytics}
    props.data = {loading: false, user: userWithAnalytics, course}

    const {getByRole} = render(<StudentContextTray {...props} />)
    const closeButton = getByRole('button', {name: 'Close'})
    fireEvent.click(closeButton)

    expect(document.activeElement).toBe(button)
  })

  describe('Student name link', () => {
    const getAriaLabel = () => {
      return screen.getByTestId('student-name-link').getAttribute('aria-label')
    }

    it('aria label includes only the student name when no pronouns are set', () => {
      const userWithAnalytics = {...user, analytics}
      props.data = {loading: false, user: userWithAnalytics, course}
      render(<StudentContextTray {...props} />)
      expect(getAriaLabel()).toBe("Go to wooper's profile")
    })

    it('aria label includes the student name and pronouns when pronouns are set', () => {
      user.pronouns = 'He/Him'
      const userWithAnalytics = {...user, analytics}
      props.data = {loading: false, user: userWithAnalytics, course}
      render(<StudentContextTray {...props} />)
      expect(getAriaLabel()).toBe("Go to wooper He/Him's profile")
    })
  })

  describe('analytics button', () => {
    it('renders with analytics data', () => {
      const userWithAnalytics = {...user, analytics}
      props.data = {loading: false, user: userWithAnalytics, course}
      const {getByText} = render(<StudentContextTray {...props} />)
      const analyticsButton = getByText('Analytics')
      expect(analyticsButton).toBeTruthy()
    })

    it('renders analytics 2 button (only) if the tool is installed', () => {
      const userWithAnalytics = {...user, analytics}
      props.data = {loading: false, user: userWithAnalytics, course}
      props.externalTools = [
        {
          title: 'Analytics Beta',
          base_url:
            'http://example.com/courses/1/external_tools/29?launch_type=student_context_card',
          tool_id: 'fd75124a-140e-470f-944c-114d2d93bb40',
          icon_url: null,
          canvas_icon_class: 'icon-analytics',
        },
      ]
      const {getByText} = render(<StudentContextTray {...props} />)
      const analyticsButton = getByText('Analytics Beta')
      expect(analyticsButton).toBeTruthy()
      expect(analyticsButton.closest('a').href).toBe(
        'http://example.com/courses/1/external_tools/29?launch_type=student_context_card&student_id=1',
      )
    })

    it('does not render without analytics data', () => {
      props.data = {loading: false, user, course}
      const {container} = render(<StudentContextTray {...props} />)
      const analyticsLinks = container.querySelectorAll('a[href*="analytics"]')
      expect(analyticsLinks).toHaveLength(0)
    })
  })
})
