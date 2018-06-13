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
import TestUtils from 'react-addons-test-utils'
import SubmissionProgressBars from 'jsx/context_cards/SubmissionProgressBars'
import InstUIProgress from '@instructure/ui-elements/lib/components/Progress'
import { shallow } from 'enzyme'

const user = { _id: 1 }

QUnit.module('StudentContextTray/Progress', (hooks) => {
  let grade, score, spy, subject, submission, tag

  hooks.afterEach(() => {
    if (subject) {
      const componentNode = ReactDOM.findDOMNode(subject)
      if (componentNode) {
        ReactDOM.unmountComponentAtNode(componentNode.parentNode)
      }
    }
    grade = null
    score = null
    spy = null
    submission = null
    subject = null
    tag = null
  })

  QUnit.module('displayGrade', () => {
    hooks.beforeEach(() => {
      subject = TestUtils.renderIntoDocument(
        <SubmissionProgressBars submissions={[]} />
      )
    })

    QUnit.module('when submission is excused', () => {
      test('it returns `EX`', () => {
        submission = { id: 1, excused: true, assignment: {points_possible: 25} }
        grade = SubmissionProgressBars.displayGrade(submission)
        equal(grade, 'EX')
      })
    })

    QUnit.module('when grade is a percentage', () => {
      test('it returns the grade', () => {
        const percentage = '80%'
        submission = {
          id: 1,
          excused: false,
          grade: percentage,
          assignment: {points_possible: 25}
        }
        grade = SubmissionProgressBars.displayGrade(submission)
        equal(grade, percentage)
      })
    })

    QUnit.module('when grade is complete or incomplete', () => {
      test('it calls `renderIcon`', () => {
        submission = {
          id: 1,
          excused: false,
          assignment: {points_possible: 25}
        }
        spy = sinon.spy(SubmissionProgressBars, 'renderIcon')

        SubmissionProgressBars.displayGrade({...submission, grade: 'complete'})
        ok(spy.calledOnce)
        spy.reset()

        SubmissionProgressBars.displayGrade({...submission, grade: 'incomplete'})
        ok(spy.calledOnce)
        SubmissionProgressBars.renderIcon.restore()
      })
    })

    QUnit.module('when grade is a random string', () => {
      test('it renders `score/points_possible`', () => {
        const pointsPossible = 25
        score = '15'
        grade = 'A+'
        submission = {
          grade,
          score,
          id: 1,
          excused: false,
          assignment: {points_possible: pointsPossible}
        }
        equal(SubmissionProgressBars.displayGrade(submission), `${score}/${pointsPossible}`)
      })
    })

    QUnit.module('by default', () => {
      test('it renders `score/points_possible`', () => {
        const pointsPossible = 25
        grade = '15'
        score = '15'
        submission = {
          grade,
          score,
          id: 1,
          excused: false,
          assignment: {points_possible: pointsPossible}
        }
        equal(SubmissionProgressBars.displayGrade(submission), `${score}/${pointsPossible}`)
      })
    })
  })

  QUnit.module('displayScreenreaderGrade', () => {
    hooks.beforeEach(() => {
      subject = TestUtils.renderIntoDocument(
        <SubmissionProgressBars submissions={[]} />
      )
    })

    QUnit.module('when submission is excused', () => {
      test('it returns `excused`', () => {
        submission = { id: 1, excused: true, assignment: {points_possible: 25} }
        grade = SubmissionProgressBars.displayScreenreaderGrade(submission)
        equal(grade, 'excused')
      })
    })

    QUnit.module('when grade is a percentage', () => {
      test('it returns the grade', () => {
        const percentage = '80%'
        submission = {
          id: 1,
          excused: false,
          grade: percentage,
          assignment: {points_possible: 25}
        }
        grade = SubmissionProgressBars.displayScreenreaderGrade(submission)
        equal(grade, percentage)
      })
    })

    QUnit.module('when grade is complete or incomplete', () => {
      test('renders `complete` or `incomplete`', () => {
        submission = {
          id: 1,
          excused: false,
          assignment: {points_possible: 25}
        }

        grade = SubmissionProgressBars.displayScreenreaderGrade({...submission, grade: 'complete'})
        equal(grade, 'complete')

        grade = SubmissionProgressBars.displayScreenreaderGrade({...submission, grade: 'incomplete'})
        equal(grade, 'incomplete')
      })
    })

    QUnit.module('when grade is a random string', () => {
      test('it renders `score/points_possible`', () => {
        const pointsPossible = 25
        score = '15'
        grade = 'A+'
        submission = {
          grade,
          score,
          id: 1,
          excused: false,
          assignment: {points_possible: pointsPossible}
        }
        equal(SubmissionProgressBars.displayScreenreaderGrade(submission), `${score}/${pointsPossible}`)
      })
    })

    QUnit.module('by default', () => {
      test('it renders `score/points_possible`', () => {
        const pointsPossible = 25
        grade = '15'
        score = '15'
        submission = {
          grade,
          score,
          id: 1,
          excused: false,
          assignment: {points_possible: pointsPossible}
        }
        equal(SubmissionProgressBars.displayScreenreaderGrade(submission), `${score}/${pointsPossible}`)
      })
    })
  })

  QUnit.module('renderIcon', () => {
    QUnit.module('when grade is `complete`', () => {
      test('renders icon with `icon-check` class', () => {
        subject = TestUtils.renderIntoDocument(
          <SubmissionProgressBars
            submissions={[{
              id: 1,
              grade: 'complete',
              score: 25,
              assignment: {points_possible: 25},
              user
            }]}
          />
        )
        tag = TestUtils.findRenderedDOMComponentWithTag(subject, 'i')
        equal(tag.className, 'icon-check')
      })
    })

    QUnit.module('when grade is `complete`', () => {
      test('renders icon with `icon-check` class', () => {
        subject = TestUtils.renderIntoDocument(
          <SubmissionProgressBars submissions={[{
            id: 1,
            grade: 'incomplete',
            score: 0,
            assignment: {points_possible: 25},
            user
          }]} />
        )
        tag = TestUtils.findRenderedDOMComponentWithTag(subject, 'i')
        equal(tag.className, 'icon-x')
      })
    })
  })

  QUnit.module('render', () => {
    test('renders one InstUIProgress component per submission', () => {
      const submissions = [{
        id: 1,
        grade: 'incomplete',
        score: 0,
        user,
        assignment: {points_possible: 25}
      }, {
        id: 2,
        grade: 'complete',
        score: 25,
        user,
        assignment: {points_possible: 25}
      }, {
        id: 3,
        grade: 'A+',
        score: 25,
        user,
        assignment: {points_possible: 25}
      }]
      subject = TestUtils.renderIntoDocument(
        <SubmissionProgressBars submissions={submissions} />
      )
      const instUIProgressBars = TestUtils.scryRenderedComponentsWithType(subject, InstUIProgress)
      equal(instUIProgressBars.length, submissions.length)
    })

    test('ignores submissions with null grades', () => {
      const submissions = [
        {
          id: '1',
          score: 5,
          grade: '5',
          assignment: {html_url: 'asdf', points_possible: 1},
          user: {short_name: 'bob', _id: '1'}
        },
        {
          id: '2',
          score: null,
          grade: null,
          assignment: {html_url: 'asdf', points_possible: 1},
          user: {short_name: 'bob', _id: '1'}
        }
      ]

      const tray = shallow(<SubmissionProgressBars submissions={submissions} />)
      equal(tray.find('Progress').length, 1)
    })

    test('links to submission urls', () => {
      const submissions = [
        {
          id: '1',
          score: 5,
          grade: '5',
          assignment: {html_url: 'grades', points_possible: 1},
          user: {short_name: 'bob', _id: '99'}
        },
      ]

      const tray = shallow(<SubmissionProgressBars submissions={submissions} />)
      ok(tray.find("Tooltip").node.props.href.match(/submissions\/99/));
    })
  })
})
