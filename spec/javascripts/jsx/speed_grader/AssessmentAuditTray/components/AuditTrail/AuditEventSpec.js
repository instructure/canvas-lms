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
import {auditEventStudentAnonymityStates} from 'jsx/speed_grader/AssessmentAuditTray/AuditTrailHelpers'
import {buildEvent} from 'jsx/speed_grader/AssessmentAuditTray/__tests__/AuditTrailSpecHelpers'

const {NA, OFF, ON, TURNED_OFF, TURNED_ON} = auditEventStudentAnonymityStates

QUnit.module('AssessmentAuditTray AuditEvent', suiteHooks => {
  let $container
  let props

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    props = {
      auditEvent: buildEvent({eventType: 'grades_posted'}),
      studentAnonymity: ON
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

  QUnit.module('Anonymity notification', hooks => {
    const OFF_MESSAGE = 'Action was not anonymous'
    const TURNED_OFF_MESSAGE = 'Anonymous was turned off'

    hooks.beforeEach(() => {
      props.auditEvent = buildEvent({eventType: 'student_anonymity_updated'})
    })

    function getBadge() {
      return $container.querySelector('[id^="Badge__"]')
    }

    function getTooltip() {
      const $trigger = $container.querySelector('[aria-describedby^="Tooltip__"]')
      return $trigger && document.querySelector(`#${$trigger.getAttribute('aria-describedby')}`)
    }

    QUnit.module('when student anonymity was on', contextHooks => {
      contextHooks.beforeEach(() => {
        props.studentAnonymity = ON
        mountComponent()
      })

      test('does not display a notification badge', () => {
        notOk(getBadge())
      })

      test('does not display a notification tooltip', () => {
        notOk(getTooltip())
      })
    })

    QUnit.module('when student anonymity was turned on', contextHooks => {
      contextHooks.beforeEach(() => {
        props.studentAnonymity = TURNED_ON
        mountComponent()
      })

      test('does not display a notification badge', () => {
        notOk(getBadge())
      })

      test('does not display a notification tooltip', () => {
        notOk(getTooltip())
      })
    })

    QUnit.module('when student anonymity was off', contextHooks => {
      contextHooks.beforeEach(() => {
        props.studentAnonymity = OFF
        mountComponent()
      })

      test('displays a notification badge', () => {
        ok(getBadge())
      })

      test(`displays the "${OFF_MESSAGE}" tooltip`, () => {
        equal(getTooltip().textContent, OFF_MESSAGE)
      })
    })

    QUnit.module('when student anonymity was turned off', contextHooks => {
      contextHooks.beforeEach(() => {
        props.studentAnonymity = TURNED_OFF
        mountComponent()
      })

      test('displays a notification badge', () => {
        ok(getBadge())
      })

      test(`displays the "${TURNED_OFF_MESSAGE}" tooltip`, () => {
        equal(getTooltip().textContent, TURNED_OFF_MESSAGE)
      })
    })

    QUnit.module('when student anonymity was not used', contextHooks => {
      contextHooks.beforeEach(() => {
        props.studentAnonymity = NA
        mountComponent()
      })

      test('does not display a notification badge', () => {
        notOk(getBadge())
      })

      test('does not display a notification tooltip', () => {
        notOk(getTooltip())
      })
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
