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
import timezone from 'timezone'
import newYork from 'timezone/America/New_York'

import DateEventGroup from 'jsx/speed_grader/AssessmentAuditTray/components/AuditTrail/DateEventGroup'
import {buildEvent} from 'jsx/speed_grader/AssessmentAuditTray/__tests__/AuditTrailSpecHelpers'
import buildAuditTrail from 'jsx/speed_grader/AssessmentAuditTray/buildAuditTrail'

QUnit.module('AssessmentAuditTray DateEventGroup', suiteHooks => {
  let $container
  let props
  let timezoneSnapshot

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    const auditEvents = [
      buildEvent({id: '4901', userId: '1101', createdAt: '2018-09-01T16:34:00Z'}),
      buildEvent({id: '4902', userId: '1101', createdAt: '2018-09-01T16:45:00Z'}),
      buildEvent({id: '4903', userId: '1101', createdAt: '2018-09-01T16:56:00Z'})
    ]
    const users = [{id: '1101', name: 'A stupefying student', role: 'student'}]
    const auditTrail = buildAuditTrail({auditEvents, users})

    props = {
      dateEventGroup: auditTrail.userEventGroups[0].dateEventGroups[0]
    }

    timezoneSnapshot = timezone.snapshot()
    timezone.changeZone(newYork, 'America/New_York')
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
    timezone.restore(timezoneSnapshot)
  })

  function mountComponent() {
    ReactDOM.render(<DateEventGroup {...props} />, $container)
  }

  test('displays the starting date and time in the timezone of the current user', () => {
    mountComponent()
    const $heading = $container.querySelector('h4')
    equal($heading.textContent, 'September 1 starting at 12:34pm')
  })

  test('displays a list of all events', () => {
    mountComponent()
    const $events = $container.querySelectorAll('ul li')
    strictEqual($events.length, 3)
  })
})
