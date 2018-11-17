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

import AuditTrail from 'jsx/speed_grader/AssessmentAuditTray/components/AuditTrail'
import {buildEvent} from 'jsx/speed_grader/AssessmentAuditTray/__tests__/AuditTrailSpecHelpers'
import buildAuditTrail from 'jsx/speed_grader/AssessmentAuditTray/buildAuditTrail'

QUnit.module('AssessmentAuditTray AuditTrail', suiteHooks => {
  let $container
  let props

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    const auditEvents = [
      buildEvent({id: '4901', userId: '1103'}),
      buildEvent({id: '4902', userId: '1101'}),
      buildEvent({id: '4903', userId: '1102'}),
      buildEvent({id: '4904', userId: '1101'})
    ]

    props = {
      auditTrail: buildAuditTrail(auditEvents)
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent() {
    ReactDOM.render(<AuditTrail {...props} />, $container)
  }

  function getUserEventGroups() {
    return [...$container.querySelector('#assessment-audit-trail').children]
  }

  test('displays a user event group for each distinct user', () => {
    mountComponent()
    strictEqual(getUserEventGroups().length, 3)
  })

  test('displays "Unknown User" when the related user is not loaded', () => {
    // This should never happen in practice. However, better safe than sorry.
    mountComponent()
    const names = getUserEventGroups().map($group => $group.querySelector('h3').textContent)
    deepEqual(names, ['Unknown User', 'Unknown User', 'Unknown User'])
  })
})
