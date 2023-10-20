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

import CreatorEventGroup from 'ui/features/speed_grader/react/AssessmentAuditTray/components/AuditTrail/CreatorEventGroup'
import {
  buildAssignmentCreatedEvent,
  buildAssignmentUpdatedEvent,
  buildEvent,
} from 'ui/features/speed_grader/react/AssessmentAuditTray/__tests__/AuditTrailSpecHelpers'
import buildAuditTrail from 'ui/features/speed_grader/react/AssessmentAuditTray/buildAuditTrail'

QUnit.module('AssessmentAuditTray CreatorEventGroup', suiteHooks => {
  let $container
  let auditEvents
  let externalTools
  let quizzes
  let users
  let props

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    auditEvents = [
      buildAssignmentCreatedEvent({id: '4901', createdAt: '2018-09-01T12:00:00Z'}),
      buildEvent({id: '4902', userId: '1101', createdAt: '2018-09-02T12:00:00Z'}),
      buildEvent({id: '4903', userId: '1101', createdAt: '2018-09-02T12:00:00Z'}),
    ]
    users = [{id: '1101', name: 'Adam Jones', role: 'final_grader'}]
    externalTools = [{id: '21', name: 'Bulldog Tool', role: 'grader'}]
    quizzes = [{id: '123', name: 'Unicorns', role: 'grader'}]
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function buildAuditTrailAndMountComponent() {
    const auditTrail = buildAuditTrail({auditEvents, users, externalTools, quizzes})
    props = {creatorEventGroup: auditTrail.creatorEventGroups[0]}
    ReactDOM.render(<CreatorEventGroup {...props} />, $container)
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

  test('displays the creator name', () => {
    buildAuditTrailAndMountComponent()
    const $heading = $container.querySelector('h3')
    ok($heading.textContent.includes('Adam Jones'))
  })

  test('displays the creator role', () => {
    buildAuditTrailAndMountComponent()
    const $heading = $container.querySelector('h3')
    ok($heading.textContent.includes('(Final Grader)'))
  })

  QUnit.module('"Non-anonymous action" notification', () => {
    function getIcon() {
      return $container.querySelector('svg[name="IconWarning"]')
    }

    function getTooltip() {
      const $trigger = $container.querySelector('[aria-describedby^="Tooltip_"]')
      return $trigger && document.querySelector(`#${$trigger.getAttribute('aria-describedby')}`)
    }

    QUnit.module('when the creator acted while student anonymity was disabled', contextHooks => {
      contextHooks.beforeEach(() => {
        const event = buildAssignmentUpdatedEvent(
          {createdAt: '2018-09-01T13:00:00Z', id: '4904'},
          {anonymous_grading: [true, false]}
        )
        auditEvents.splice(1, 0, event)
        buildAuditTrailAndMountComponent()
      })

      test('displays a warning icon', () => {
        ok(getIcon())
      })

      // FOO-3825
      QUnit.skip('displays a tooltip', () => {
        equal(
          getTooltip().textContent,
          `${users[0].name} performed actions while anonymous was off`
        )
      })
    })

    QUnit.module('when the creator acted while student anonymity was enabled', () => {
      test('does not display a warning icon', () => {
        buildAuditTrailAndMountComponent()
        notOk(getIcon())
      })

      test('does not display a tooltip', () => {
        buildAuditTrailAndMountComponent()
        notOk(getTooltip())
      })
    })
  })

  QUnit.module('"Toggle Details" button', hooks => {
    hooks.beforeEach(() => {
      buildAuditTrailAndMountComponent()
    })

    test('is labeled with the creator name', () => {
      const buttonText = getToggleDetailsButton().textContent
      equal(buttonText, 'Assessment audit events for Adam Jones')
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
