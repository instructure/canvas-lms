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

import UserEventGroup from 'jsx/speed_grader/AssessmentAuditTray/components/AuditTrail/UserEventGroup'
import {buildEvent} from 'jsx/speed_grader/AssessmentAuditTray/__tests__/AuditTrailSpecHelpers'
import buildAuditTrail from 'jsx/speed_grader/AssessmentAuditTray/buildAuditTrail'

QUnit.module('AssessmentAuditTray UserEventGroup', suiteHooks => {
  let $container
  let auditEvents
  let users
  let props

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    auditEvents = [
      buildEvent({id: '4901', userId: '1101', createdAt: '2018-09-01T12:00:00Z'}),
      buildEvent({id: '4902', userId: '1101', createdAt: '2018-09-02T12:00:00Z'}),
      buildEvent({id: '4903', userId: '1101', createdAt: '2018-09-02T12:00:00Z'})
    ]
    users = [{id: '1101', name: 'A fatalistic final-grader', role: 'final_grader'}]
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function buildAuditTrailAndMountComponent() {
    const auditTrail = buildAuditTrail({auditEvents, users})
    props = {userEventGroup: auditTrail.userEventGroups[1101]}
    ReactDOM.render(<UserEventGroup {...props} />, $container)
  }

  function getToggleDetailsButton() {
    return $container.querySelector('button')
  }

  function getDateEventGroupsSection() {
    const sectionId = getToggleDetailsButton().getAttribute('aria-controls')
    return $container.querySelector(`#${sectionId}`)
  }

  function getDateEventGroupHeadings() {
    return [...$container.querySelectorAll('h4')]
  }

  test('displays the user name', () => {
    buildAuditTrailAndMountComponent()
    const $heading = $container.querySelector('h3')
    ok($heading.textContent.includes('A fatalistic final-grader'))
  })

  QUnit.module('"Toggle Details" button', hooks => {
    hooks.beforeEach(() => {
      buildAuditTrailAndMountComponent()
    })

    test('is labeled with the user name', () => {
      const buttonText = getToggleDetailsButton().textContent
      equal(buttonText, 'Assessment audit events for A fatalistic final-grader')
    })

    test('expands the collapsed details section when clicked', () => {
      getToggleDetailsButton().click()
      strictEqual(getDateEventGroupsSection().children.length, 1)
    })

    test('collapses the expanded details section when clicked', () => {
      getToggleDetailsButton().click()
      getToggleDetailsButton().click()
      strictEqual(getDateEventGroupsSection().children.length, 0)
    })
  })

  QUnit.module('date event groups section', () => {
    test('is empty when collapsed', () => {
      buildAuditTrailAndMountComponent()
      strictEqual(getDateEventGroupHeadings().length, 0)
    })

    test('displays a date event heading for each unique date when expanded', () => {
      buildAuditTrailAndMountComponent()
      getToggleDetailsButton().click()
      strictEqual(getDateEventGroupHeadings().length, 2)
    })
  })
})
