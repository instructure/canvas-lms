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

import AssessmentAuditTray from 'jsx/speed_grader/AssessmentAuditTray'

QUnit.module('AssessmentAuditTray', suiteHooks => {
  let $container
  let context
  let onEntered
  let onExited
  let props
  let tray

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    props = {}
    onEntered = promiseProp('onEntered')
    onExited = promiseProp('onExited')

    context = {
      assignmentId: '2301',
      courseId: '1201',
      submissionId: '2501'
    }

    renderTray()
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function promiseProp(propName) {
    return new Promise(resolve => {
      props[propName] = resolve
    })
  }

  function renderTray() {
    ReactDOM.render(
      <AssessmentAuditTray
        ref={ref => {
          tray = ref
        }}
        {...props}
      />,
      $container
    )
  }

  function getTrayContainer() {
    return document.querySelector('[role="dialog"][aria-label="Assessment audit tray"]')
  }

  function getCloseButton() {
    const $tray = getTrayContainer()
    return [...$tray.querySelectorAll('button')].find($button => $button.textContent === 'Close')
  }

  QUnit.module('#show()', () => {
    test('opens the tray', async () => {
      tray.show(context)
      await onEntered
      ok(getTrayContainer())
    })
  })

  test('closes when the "Close" button is clicked', async () => {
    tray.show(context)
    await onEntered
    getCloseButton().click()
    await onExited
    notOk(getTrayContainer())
  })
})
