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
    window.ENV.permissions = {can_manage_differentiation_tags: false}
  })

  afterEach(() => {
    const fixtures = document.getElementById('fixtures')
    if (fixtures) {
      fixtures.remove()
    }
    window.ENV.permissions = {}
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

  describe('when tray is opened after being closed', () => {
    it('calls data.refetch when user has manage tags permissions', () => {
      window.ENV.permissions = {can_manage_differentiation_tags: true}
      const mockRefetch = vi.fn()
      const userWithAnalytics = {...user, analytics}

      // Mock returnFocusTo to prevent focus errors when closing the tray
      props.returnFocusTo = () => []
      props.data = {loading: false, user: userWithAnalytics, course, refetch: mockRefetch}

      const {getByRole, rerender} = render(<StudentContextTray {...props} />)

      const closeButton = getByRole('button', {name: 'Close'})
      fireEvent.click(closeButton)
      mockRefetch.mockClear()

      // Change props so that React calls UNSAFE_componentWillReceiveProps
      const newProps = {
        ...props,
        courseId: props.courseId,
        data: {loading: false, user: userWithAnalytics, course, refetch: mockRefetch},
      }

      rerender(<StudentContextTray {...newProps} />)

      expect(mockRefetch).toHaveBeenCalledTimes(1)
    })

    it('does not call data.refetch when user lacks manage tags permissions', () => {
      const mockRefetch = vi.fn()
      const userWithAnalytics = {...user, analytics}
      props.returnFocusTo = () => []
      props.data = {loading: false, user: userWithAnalytics, course, refetch: mockRefetch}

      const {getByRole, rerender} = render(<StudentContextTray {...props} />)

      const closeButton = getByRole('button', {name: 'Close'})
      fireEvent.click(closeButton)
      mockRefetch.mockClear()

      const newProps = {
        ...props,
        courseId: props.courseId,
        data: {loading: false, user: userWithAnalytics, course, refetch: mockRefetch},
      }

      rerender(<StudentContextTray {...newProps} />)

      expect(mockRefetch).not.toHaveBeenCalled()
    })

    it('does not crash when data.refetch is not provided', () => {
      window.ENV.permissions = {can_manage_differentiation_tags: true}
      const userWithAnalytics = {...user, analytics}
      props.returnFocusTo = () => []
      props.data = {loading: false, user: userWithAnalytics, course}

      const {getByRole, rerender} = render(<StudentContextTray {...props} />)

      const closeButton = getByRole('button', {name: 'Close'})
      fireEvent.click(closeButton)

      const newProps = {
        ...props,
        courseId: props.courseId,
        data: {loading: false, user: userWithAnalytics, course}, // no refetch function
      }

      expect(() => rerender(<StudentContextTray {...newProps} />)).not.toThrow()
    })
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
      const {queryByText} = render(<StudentContextTray {...props} />)
      const analyticsButton = queryByText('Analytics')
      expect(analyticsButton).not.toBeTruthy()
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

    it('does not render legacy analytics entrypoint', () => {
      props.data = {loading: false, user, course}
      const {container} = render(<StudentContextTray {...props} />)
      const analyticsLinks = container.querySelectorAll('a[href*="analytics"]')
      expect(analyticsLinks).toHaveLength(0)
    })
  })

  describe('differentiation tags', () => {
    const createTagEdge = (groupId, groupName, categoryName, singleTag = false) => ({
      node: {
        group: {
          _id: groupId,
          name: groupName,
          groupCategory: {
            name: categoryName,
            singleTag,
          },
        },
      },
    })

    beforeEach(() => {
      window.ENV.permissions = {can_manage_differentiation_tags: true}
    })

    it('renders tags when user has permissions and tags exist', () => {
      const userWithTags = {
        ...user,
        analytics,
        differentiationTagsConnection: {
          edges: [
            createTagEdge('1', 'Group 1', 'Category 1'),
            createTagEdge('2', 'Group 2', 'Category 2'),
          ],
        },
      }
      props.data = {loading: false, user: userWithTags, course}
      render(<StudentContextTray {...props} />)

      expect(screen.getByText('Category 1 | Group 1')).toBeTruthy()
      expect(screen.getByText('Category 2 | Group 2')).toBeTruthy()
    })

    it('renders Category Name as tag name when singleTag is true', () => {
      const userWithSingleTag = {
        ...user,
        analytics,
        differentiationTagsConnection: {
          edges: [createTagEdge('1', 'Group 1', 'Category 1', true)],
        },
      }
      props.data = {loading: false, user: userWithSingleTag, course}
      render(<StudentContextTray {...props} />)

      expect(screen.getByText('Category 1')).toBeTruthy()
      expect(screen.queryByText('Group 1')).toBeFalsy()
    })

    it('renders Category Name | Tag Name as tag name when singleTag is false', () => {
      const userWithSingleTag = {
        ...user,
        analytics,
        differentiationTagsConnection: {
          edges: [createTagEdge('1', 'Group 1', 'Category 1')],
        },
      }
      props.data = {loading: false, user: userWithSingleTag, course}
      render(<StudentContextTray {...props} />)

      expect(screen.getByText('Category 1 | Group 1')).toBeTruthy()
    })

    it('does not render tags when user lacks permissions', () => {
      window.ENV.permissions = {can_manage_differentiation_tags: false}
      const userWithTags = {
        ...user,
        analytics,
        differentiationTagsConnection: {
          edges: [createTagEdge('1', 'Group 1', 'Category 1')],
        },
      }
      props.data = {loading: false, user: userWithTags, course}
      render(<StudentContextTray {...props} />)

      expect(screen.queryByTestId('tag-1')).toBeFalsy()
    })

    it('does not render tags when user has no tags', () => {
      const userWithoutTags = {
        ...user,
        analytics,
        differentiationTagsConnection: {edges: []},
      }
      props.data = {loading: false, user: userWithoutTags, course}
      render(<StudentContextTray {...props} />)

      expect(screen.queryByTestId(/tag-\d+/)).toBeFalsy()
    })

    it('renders tags container with auto scroller when there are more than 4 tags', () => {
      const tagsEdges = Array.from({length: 5}, (_, i) =>
        createTagEdge(`${i + 1}`, `Group ${i + 1}`, `Category ${i + 1}`),
      )
      const userWithManyTags = {
        ...user,
        analytics,
        differentiationTagsConnection: {edges: tagsEdges},
      }
      props.data = {loading: false, user: userWithManyTags, course}
      render(<StudentContextTray {...props} />)

      const container = screen.getByTestId('tags-container')
      const computedStyle = window.getComputedStyle(container)
      expect(computedStyle.maxHeight).toBe('8rem')
      expect(computedStyle.overflowY).toBe('auto')
      expect(computedStyle.position).toBe('relative')
    })

    it('renders tags container without a scroller when there are 4 tags or less', () => {
      const tagsEdges = Array.from({length: 4}, (_, i) =>
        createTagEdge(`${i + 1}`, `Group ${i + 1}`, `Category ${i + 1}`),
      )
      const userWithFewTags = {
        ...user,
        analytics,
        differentiationTagsConnection: {edges: tagsEdges},
      }
      props.data = {loading: false, user: userWithFewTags, course}
      render(<StudentContextTray {...props} />)

      const container = screen.getByTestId('tags-container')
      const computedStyle = window.getComputedStyle(container)

      // No scrolling constraints should be applied
      expect(computedStyle.maxHeight).not.toBe('8rem')
      expect(computedStyle.overflowY).not.toBe('auto')
    })
  })
})
