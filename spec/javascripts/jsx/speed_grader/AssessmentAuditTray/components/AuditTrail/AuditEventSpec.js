/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'

import AuditEvent from 'jsx/speed_grader/AssessmentAuditTray/components/AuditTrail/AuditEvent'
import {buildEvent} from 'jsx/speed_grader/AssessmentAuditTray/__tests__/AuditTrailSpecHelpers'

QUnit.module('AssessmentAuditTray AuditEvent', suiteHooks => {
  let $container
  let props

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    props = {
      anonymous: true,
      auditEvent: buildEvent({eventType: 'grades_posted'})
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent() {
    ReactDOM.render(<AuditEvent {...props} />, $container)
  }

  test('displays the label for the audit event', () => {
    mountComponent()
    ok($container.textContent.includes('Grades posted'))
  })

  QUnit.module('"Non-anonymous" notification', () => {
    // TODO: Implement as a part of GRADE-1668
    QUnit.skip('does not display a notification for anonymous events', () => {
      props.anonymous = true
      mountComponent()
    })

    // TODO: Implement as a part of GRADE-1668
    QUnit.skip('displays a notification for non-anonymous events', () => {
      props.anonymous = false
      mountComponent()
    })
  })

  QUnit.module('snippet', () => {
    test('is displayed for audit events with snippets', () => {
      props.auditEvent = buildEvent(
        {eventType: 'submission_comment_created'},
        {comment: 'Good job.'}
      )
      mountComponent()
      const $snippet = $container.querySelector('p')
      equal($snippet.textContent, 'Good job.')
    })

    test('is not displayed for events without snippets', () => {
      props.auditEvent = buildEvent({eventType: 'unknown'})
      mountComponent()
      strictEqual($container.querySelectorAll('p').length, 0)
    })
  })
})
