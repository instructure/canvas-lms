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

import AuditTrail from 'ui/features/speed_grader/react/AssessmentAuditTray/components/AuditTrail/index.js'
import {buildEvent} from 'ui/features/speed_grader/react/AssessmentAuditTray/__tests__/AuditTrailSpecHelpers.js'
import buildAuditTrail from 'ui/features/speed_grader/react/AssessmentAuditTray/buildAuditTrail.js'

QUnit.module('AssessmentAuditTray AuditTrail', suiteHooks => {
  let $container
  let props

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    const auditEvents = [
      buildEvent({id: '4901', userId: '1103'}),
      buildEvent({id: '4902', userId: '1101'}),
      buildEvent({id: '4903', userId: '1102'}),
      buildEvent({id: '4904', userId: '1104'}),
      buildEvent(
        {id: '4905', eventType: 'submission_updated', userId: '1101'},
        {grade: [null, 'A']}
      )
    ]
    const users = [
      {id: '1101', name: 'A sedulous pupil', role: 'student'},
      {id: '1102', name: 'A quizzical administrator', role: 'administrator'},
      {id: '1103', name: 'A querulous final-grader', role: 'final_grader'}
    ]

    const externalTools = []
    const quizzes = []

    props = {
      auditTrail: buildAuditTrail({auditEvents, users, externalTools, quizzes})
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent() {
    ReactDOM.render(<AuditTrail {...props} />, $container)
  }

  function getCreatorEventGroups() {
    return [...$container.querySelector('#assessment-audit-trail').children]
  }

  function getHeaderContents() {
    return getCreatorEventGroups().map($group => $group.querySelector('h3').textContent)
  }

  test('displays a creator event group for each distinct creator', () => {
    mountComponent()
    strictEqual(getCreatorEventGroups().length, 4)
  })

  test('displays the name of the creator in the header', () => {
    mountComponent()

    const firstHeader = getHeaderContents()[0]
    ok(firstHeader.includes('A sedulous pupil'))
  })

  test('displays the role of the creator in the header', () => {
    mountComponent()

    const firstHeader = getHeaderContents()[0]
    ok(firstHeader.includes('Student'))
  })

  test('displays "Unknown User" when the related user is not loaded', () => {
    // This should never happen in practice. However, better safe than sorry.
    mountComponent()

    const names = getHeaderContents()
    ok(names[names.length - 1].includes('Unknown User'))
  })
})
