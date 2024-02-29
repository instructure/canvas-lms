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

import $ from 'jquery'
import 'jquery-migrate'
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import StudentContextTray from '@canvas/context-cards/react/StudentContextTray'

QUnit.module('StudentContextTray', hooks => {
  let tray
  let props
  let user
  let course
  let analytics

  function renderTray() {
    return TestUtils.renderIntoDocument(
      <StudentContextTray {...props} />,
      document.getElementById('fixtures')
    )
  }

  hooks.beforeEach(() => {
    props = {
      data: {loading: true},
      returnFocusTo: () => {},
      courseId: '1',
      studentId: '1',
    }

    user = {
      short_name: 'wooper',
      enrollments: [],
    }

    course = {
      permissions: {
        view_analytics: true,
      },
      submissionsConnection: {edges: []},
    }

    analytics = {
      participations: {level: 2},
      page_views: {level: 3},
    }
  })
  hooks.afterEach(() => {
    if (tray) {
      const componentNode = ReactDOM.findDOMNode(tray)
      if (componentNode) {
        ReactDOM.unmountComponentAtNode(componentNode.parentNode)
      }
    }
    tray = null
  })

  test('sets focus back to the result of the returnFocusTo prop', () => {
    $('#fixtures').append('<button id="someButton"><button>')
    props.returnFocusTo = () => [$('#someButton')]
    tray = renderTray()
    const fakeEvent = {
      preventDefault() {},
    }
    tray.handleRequestClose(fakeEvent)
    strictEqual(document.activeElement, document.getElementById('someButton'))
  })

  QUnit.module('Student name link', () => {
    function studentNameLinkLabel() {
      return document.querySelector('.StudentContextTray-Header__Name a').getAttribute('aria-label')
    }

    test('aria label includes only the student name when no pronouns are set', () => {
      const userWithAnalytics = {...user, analytics}
      props.data = {loading: false, user: userWithAnalytics, course}
      tray = renderTray()
      strictEqual(studentNameLinkLabel(), "Go to wooper's profile")
    })

    test('aria label includes the student name and pronouns when pronouns are set', () => {
      user.pronouns = 'He/Him'
      const userWithAnalytics = {...user, analytics}
      props.data = {loading: false, user: userWithAnalytics, course}
      tray = renderTray()
      strictEqual(studentNameLinkLabel(), "Go to wooper He/Him's profile")
    })
  })

  QUnit.module('analytics button', () => {
    test('it renders with analytics data', () => {
      const userWithAnalytics = {...user, analytics}
      props.data = {loading: false, user: userWithAnalytics, course}
      tray = renderTray()
      const quickLinks = tray.renderQuickLinks(userWithAnalytics, course)
      const children = quickLinks.props.children.filter(quickLink => quickLink !== null)

      // This is ugly, but getting at the rendered output with a portal
      // involved is also ugly.
      ok(children[0].props.children.props.href.match(/analytics/))
    })

    test('it renders analytics 2 button (only) if the tool is installed', () => {
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
      tray = renderTray()
      const quickLinks = tray.renderQuickLinks(userWithAnalytics, course)
      const children = quickLinks.props.children.filter(quickLink => quickLink !== null)

      equal(children.length, 1)
      equal(
        children[0][0].props.children.props.href,
        'http://example.com/courses/1/external_tools/29?launch_type=student_context_card&student_id=1'
      )
    })

    test('it does not render without analytics data', () => {
      props.data = {loading: false, user, course}
      tray = renderTray()
      const quickLinks = tray.renderQuickLinks(user, course)
      const children = quickLinks.props.children.filter(quickLink => quickLink !== null)
      strictEqual(children.length, 0)
    })
  })
})
