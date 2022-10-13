/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import TestUtils from 'react-dom/test-utils'
import MetricsList from '@canvas/context-cards/react/MetricsList'

QUnit.module('StudentContextTray/MetricsList', hooks => {
  let subject
  hooks.afterEach(() => {
    if (subject) {
      const componentNode = ReactDOM.findDOMNode(subject)
      if (componentNode) {
        ReactDOM.unmountComponentAtNode(componentNode.parentNode)
      }
    }
    subject = null
  })

  QUnit.module('grade', hooks => {
    test('returns null by default', () => {
      subject = TestUtils.renderIntoDocument(<MetricsList />)
      notOk(subject.grade)
    })

    test('returns override_grade if present and final_grade_override is true', () => {
      const overrideGrade = 'A+'
      subject = TestUtils.renderIntoDocument(
        <MetricsList
          allowFinalGradeOverride
          user={{
            enrollments: [
              {
                grades: {
                  override_grade: overrideGrade,
                },
                sections: [],
              },
            ],
          }}
        />
      )

      equal(subject.grade, overrideGrade)
    })
    test('returns current_grade if override_grade is present and final_grade_override is false', () => {
      const overrideGrade = 'A+'
      const currentGrade = 'B-'

      subject = TestUtils.renderIntoDocument(
        <MetricsList
          allowFinalGradeOverride={false}
          user={{
            enrollments: [
              {
                grades: {
                  override_grade: overrideGrade,
                  current_grade: currentGrade,
                },
                sections: [],
              },
            ],
          }}
        />
      )

      equal(subject.grade, currentGrade)
    })

    test('returns override_score if present and override_grade is not present', () => {
      const overrideScore = '81.8'
      subject = TestUtils.renderIntoDocument(
        <MetricsList
          allowFinalGradeOverride
          user={{
            enrollments: [
              {
                grades: {
                  override_score: overrideScore,
                },
                sections: [],
              },
            ],
          }}
        />
      )

      equal(subject.grade, `${overrideScore}%`)
    })

    test('returns current_grade if present and override fields are not present', () => {
      const currentGrade = 'A+'
      subject = TestUtils.renderIntoDocument(
        <MetricsList
          user={{
            enrollments: [
              {
                grades: {
                  current_grade: currentGrade,
                },
                sections: [],
              },
            ],
          }}
        />
      )

      equal(subject.grade, currentGrade)
    })

    test('returns current_score by default', () => {
      const currentScore = '75.3'
      subject = TestUtils.renderIntoDocument(
        <MetricsList
          user={{
            enrollments: [
              {
                grades: {
                  current_grade: null,
                  current_score: currentScore,
                },
                sections: [],
              },
            ],
          }}
        />
      )

      equal(subject.grade, `${currentScore}%`)
    })

    test('returns - if the enrollment is undefined', () => {
      subject = TestUtils.renderIntoDocument(
        <MetricsList
          user={{
            enrollments: [],
          }}
        />
      )

      equal(subject.grade, '-')
    })
  })

  QUnit.module('missingCount', hooks => {
    test('returns count from analytics data when present', () => {
      const missingCount = 3
      subject = TestUtils.renderIntoDocument(
        <MetricsList
          analytics={{
            tardiness_breakdown: {
              missing: missingCount,
            },
          }}
        />
      )

      equal(subject.missingCount, missingCount)
    })
  })

  QUnit.module('lateCount', () => {
    test('returns value from analytics when present', () => {
      const lateCount = 5
      subject = TestUtils.renderIntoDocument(
        <MetricsList
          analytics={{
            tardiness_breakdown: {
              late: lateCount,
            },
          }}
        />
      )

      equal(subject.lateCount, lateCount)
    })
  })
})
