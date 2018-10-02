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

import AssessmentSummary from 'jsx/speed_grader/AssessmentAuditTray/components/AssessmentSummary'

QUnit.module('AssessmentSummary', suiteHooks => {
  let $container
  let props

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    props = {
      assignment: {
        gradesPublishedAt: '2015-05-04T12:00:00.000Z',
        pointsPossible: 10
      },
      submission: {
        score: 9.5
      }
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function renderComponent() {
    ReactDOM.render(<AssessmentSummary {...props} />, $container)
  }

  QUnit.module('"Final Grade"', () => {
    test('shows the score out of points possible', () => {
      renderComponent()
      ok($container.textContent.includes('9.5/10'))
    })

    test('rounds the score to two decimal places', () => {
      props.submission.score = 9.523
      renderComponent()
      ok($container.textContent.includes('9.52/10'))
    })

    test('rounds the points possible to two decimal places', () => {
      props.assignment.pointsPossible = 10.017
      renderComponent()
      ok($container.textContent.includes('9.5/10.02'))
    })

    test('displays zero out of points possible when the score is zero', () => {
      props.submission.score = 0
      renderComponent()
      ok($container.textContent.includes('0/10'))
    })

    test('displays score out of zero points possible when the assignment is worth zero points', () => {
      props.assignment.pointsPossible = 0
      renderComponent()
      ok($container.textContent.includes('9.5/0'))
    })

    test('displays "–" (en dash) for score when the submission is ungraded', () => {
      props.submission.score = null
      renderComponent()
      ok($container.textContent.includes('–/10'))
    })
  })

  QUnit.module('"Posted to student"', () => {
    test('displays the "grades published" date from the assignment', () => {
      renderComponent()
      const $time = $container.querySelector('time')
      equal($time.getAttribute('datetime'), props.assignment.gradesPublishedAt)
    })

    test('includes the time on the visible date', () => {
      renderComponent()
      const $time = $container.querySelector('time')
      ok($time.textContent.includes('12pm'))
    })
  })
})
