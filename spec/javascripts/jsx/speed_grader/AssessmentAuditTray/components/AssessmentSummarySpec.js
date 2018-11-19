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

import AssessmentSummary from 'jsx/speed_grader/AssessmentAuditTray/components/AssessmentSummary'
import {overallAnonymityStates} from 'jsx/speed_grader/AssessmentAuditTray/AuditTrailHelpers'

const {FULL, NA, PARTIAL} = overallAnonymityStates

QUnit.module('AssessmentSummary', suiteHooks => {
  let $container
  let props
  let timezoneSnapshot

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    timezoneSnapshot = timezone.snapshot()
    timezone.changeZone(newYork, 'America/New_York')

    props = {
      anonymityDate: new Date('2015-04-04T19:00:00.000Z'),
      assignment: {
        gradesPublishedAt: '2015-05-04T16:00:00.000Z',
        pointsPossible: 10
      },
      finalGradeDate: new Date('2015-04-18T17:00:00.000Z'),
      overallAnonymity: FULL,
      submission: {
        score: 9.5
      }
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
    timezone.restore(timezoneSnapshot)
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

    test('displays the "final grade" date from the audit trail', () => {
      renderComponent()
      const $time = $container.querySelector('#audit-tray-final-grade time')
      equal($time.getAttribute('datetime'), '2015-04-18T17:00:00.000Z')
    })

    test('includes the time on the visible date', () => {
      renderComponent()
      const $time = $container.querySelector('#audit-tray-final-grade time')
      ok($time.textContent.includes('1pm'))
    })
  })

  QUnit.module('"Posted to student"', () => {
    test('displays the "grades published" date from the assignment', () => {
      renderComponent()
      const $time = $container.querySelector('#audit-tray-grades-posted time')
      equal($time.getAttribute('datetime'), props.assignment.gradesPublishedAt)
    })

    test('includes the time on the visible date', () => {
      renderComponent()
      const $time = $container.querySelector('#audit-tray-grades-posted time')
      ok($time.textContent.includes('12pm'))
    })
  })

  QUnit.module('"Overall Anonymity"', () => {
    let $description
    let $label

    function getOverallAnonymityLabel() {
      return $container.querySelector('#audit-tray-overall-anonymity-label')
    }

    function getOverallAnonymityDescription() {
      return $container.querySelector('#audit-tray-overall-anonymity-description')
    }

    function renderAndQuery() {
      renderComponent()
      $label = getOverallAnonymityLabel()
      $description = getOverallAnonymityDescription()
    }

    QUnit.module('when anonymity was used without interruption', contextHooks => {
      contextHooks.beforeEach(() => {
        props.overallAnonymity = FULL
        renderAndQuery()
      })

      test('labels the indicator with "Anonymous On"', () => {
        equal($label.textContent, 'Anonymous On')
      })

      test('displays the anonymity date', () => {
        const $time = $description.querySelector('time')
        equal($time.getAttribute('datetime'), '2015-04-04T19:00:00.000Z')
      })

      test('includes the time on the visible date', () => {
        const $time = $description.querySelector('time')
        ok($time.textContent.includes('3pm'))
      })
    })

    QUnit.module('when anonymity was applied multiple times', contextHooks => {
      contextHooks.beforeEach(() => {
        props.overallAnonymity = PARTIAL
        renderAndQuery()
      })

      test('labels the indicator with "Partially Anonymous"', () => {
        // TODO: Swap the assertion here for GRADE-1820
        // equal($label.textContent, 'Partially Anonymous')
        ok($label.textContent.includes('Partially'))
      })

      test('displays the anonymity date', () => {
        const $time = $description.querySelector('time')
        equal($time.getAttribute('datetime'), '2015-04-04T19:00:00.000Z')
      })

      test('includes the time on the visible date', () => {
        const $time = $description.querySelector('time')
        ok($time.textContent.includes('3pm'))
      })
    })

    QUnit.module('when anonymity was not used', contextHooks => {
      contextHooks.beforeEach(() => {
        props.anonymityDate = null
        props.overallAnonymity = NA
        renderAndQuery()
      })

      test('labels the indicator with "Anonymous Off"', () => {
        equal($label.textContent, 'Anonymous Off')
      })

      test('includes the time on the visible date', () => {
        equal($description.textContent, 'Anonymous was never turned on')
      })
    })
  })
})
