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
import SubmissionProgressBars from '../SubmissionProgressBars'
import {shallow} from 'enzyme'
import {render} from '@testing-library/react'
import sinon from 'sinon'

const user = {_id: '1'}

describe('StudentContextTray/Progress', () => {
  let grade, score, spy, subject, submission, tag

  afterEach(() => {
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

  describe('displayGrade', () => {
    beforeEach(() => {
      subject = TestUtils.renderIntoDocument(<SubmissionProgressBars submissions={[]} />)
    })

    describe('when submission is excused', () => {
      test('it returns `EX`', () => {
        submission = {id: '1', excused: true, assignment: {points_possible: 25}}
        grade = SubmissionProgressBars.displayGrade(submission)
        expect(grade).toEqual('EX')
      })
    })

    describe('when grade is a percentage', () => {
      test('it returns the grade', () => {
        const percentage = '80%'
        submission = {
          id: '1',
          excused: false,
          grade: percentage,
          assignment: {points_possible: 25},
        }
        grade = SubmissionProgressBars.displayGrade(submission)
        expect(grade).toEqual(percentage)
      })
    })

    describe('when grade is complete or incomplete', () => {
      test('it calls `renderIcon`', () => {
        submission = {
          id: '1',
          excused: false,
          assignment: {points_possible: 25},
        }
        spy = sinon.spy(SubmissionProgressBars, 'renderIcon')

        SubmissionProgressBars.displayGrade({...submission, grade: 'complete'})
        expect(spy.calledOnce).toBeTruthy()
        spy.resetHistory()

        SubmissionProgressBars.displayGrade({...submission, grade: 'incomplete'})
        expect(spy.calledOnce).toBeTruthy()
        SubmissionProgressBars.renderIcon.restore()
      })
    })

    describe('when grade is a random string', () => {
      test('it renders `score/points_possible`', () => {
        const pointsPossible = 25
        score = '15'
        grade = 'A+'
        submission = {
          grade,
          score,
          id: '1',
          excused: false,
          assignment: {points_possible: pointsPossible},
        }
        expect(SubmissionProgressBars.displayGrade(submission)).toEqual(
          `${score}/${pointsPossible}`
        )
      })
    })

    describe('by default', () => {
      test('it renders `score/points_possible`', () => {
        const pointsPossible = 25
        grade = '15'
        score = '15'
        submission = {
          grade,
          score,
          id: '1',
          excused: false,
          assignment: {points_possible: pointsPossible},
        }
        expect(SubmissionProgressBars.displayGrade(submission)).toEqual(
          `${score}/${pointsPossible}`
        )
      })
    })
  })

  describe('displayScreenreaderGrade', () => {
    beforeEach(() => {
      subject = TestUtils.renderIntoDocument(<SubmissionProgressBars submissions={[]} />)
    })

    describe('when submission is excused (2)', () => {
      test('it returns `excused`', () => {
        submission = {id: '1', excused: true, assignment: {points_possible: 25}}
        grade = SubmissionProgressBars.displayScreenreaderGrade(submission)
        expect(grade).toEqual('excused')
      })
    })

    describe('when grade is a percentage (2)', () => {
      test('it returns the grade', () => {
        const percentage = '80%'
        submission = {
          id: '1',
          excused: false,
          grade: percentage,
          assignment: {points_possible: 25},
        }
        grade = SubmissionProgressBars.displayScreenreaderGrade(submission)
        expect(grade).toEqual(percentage)
      })
    })

    describe('when grade is complete or incomplete (2)', () => {
      test('renders `complete` or `incomplete`', () => {
        submission = {
          id: '1',
          excused: false,
          assignment: {points_possible: 25},
        }

        grade = SubmissionProgressBars.displayScreenreaderGrade({...submission, grade: 'complete'})
        expect(grade).toEqual('complete')

        grade = SubmissionProgressBars.displayScreenreaderGrade({
          ...submission,
          grade: 'incomplete',
        })
        expect(grade).toEqual('incomplete')
      })
    })

    describe('when grade is a random string (2)', () => {
      test('it renders `score/points_possible`', () => {
        const pointsPossible = 25
        score = '15'
        grade = 'A+'
        submission = {
          grade,
          score,
          id: '1',
          excused: false,
          assignment: {points_possible: pointsPossible},
        }
        expect(SubmissionProgressBars.displayScreenreaderGrade(submission)).toEqual(
          `${score}/${pointsPossible}`
        )
      })
    })

    describe('by default (2)', () => {
      test('it renders `score/points_possible`', () => {
        const pointsPossible = 25
        grade = '15'
        score = '15.56789'
        submission = {
          grade,
          score,
          id: '1',
          excused: false,
          assignment: {points_possible: pointsPossible},
        }
        expect(SubmissionProgressBars.displayScreenreaderGrade(submission)).toEqual(
          `15.57/${pointsPossible}`
        )
      })
    })
  })

  describe('renderIcon', () => {
    describe('when grade is `complete`', () => {
      test('renders icon with `icon-check` class', () => {
        subject = TestUtils.renderIntoDocument(
          <SubmissionProgressBars
            submissions={[
              {
                id: '1',
                grade: 'complete',
                score: 25,
                assignment: {name: 'test', points_possible: 25, html_url: '/test'},
                user,
              },
            ]}
          />
        )
        tag = TestUtils.findRenderedDOMComponentWithTag(subject, 'i')
        expect(tag.className).toEqual('icon-check')
      })
    })

    describe('when grade is `complete` (2)', () => {
      test('renders icon with `icon-check` class', () => {
        subject = TestUtils.renderIntoDocument(
          <SubmissionProgressBars
            submissions={[
              {
                id: '1',
                grade: 'incomplete',
                score: 0,
                assignment: {name: 'test', points_possible: 25, html_url: '/test'},
                user,
              },
            ]}
          />
        )
        tag = TestUtils.findRenderedDOMComponentWithTag(subject, 'i')
        expect(tag.className).toEqual('icon-x')
      })
    })
  })

  describe('render', () => {
    test('renders one ProgressBar component per submission', () => {
      const submissions = [
        {
          id: '1',
          grade: 'incomplete',
          score: 0,
          user,
          assignment: {name: 'test', points_possible: 25, html_url: '/test'},
        },
        {
          id: '2',
          grade: 'complete',
          score: 25,
          user,
          assignment: {name: 'test', points_possible: 25, html_url: '/test'},
        },
        {
          id: '3',
          grade: 'A+',
          score: 25,
          user,
          assignment: {name: 'test', points_possible: 25, html_url: '/test'},
        },
      ]
      const wrapper = render(<SubmissionProgressBars submissions={submissions} />)

      const ProgressBarBars = wrapper.container.querySelectorAll(
        '.StudentContextTray-Progress__Bar'
      ) // Assuming ProgressBar is the name of the component
      expect(ProgressBarBars.length).toEqual(submissions.length)
    })

    test('ignores submissions with null grades', () => {
      const submissions = [
        {
          id: '1',
          score: 5,
          grade: '5',
          assignment: {name: 'test', html_url: '/test', points_possible: 1},
          user: {short_name: 'bob', _id: '1'},
        },
        {
          id: '2',
          score: null,
          grade: null,
          assignment: {name: 'test', html_url: '/test', points_possible: 1},
          user: {short_name: 'bob', _id: '1'},
        },
      ]

      const tray = shallow(<SubmissionProgressBars submissions={submissions} />)
      expect(tray.find('ProgressBar').length).toEqual(1)
    })

    test('links to submission urls', () => {
      const submissions = [
        {
          id: '1',
          score: 5,
          grade: '5',
          assignment: {name: 'test', html_url: 'grades', points_possible: 1},
          user: {short_name: 'bob', _id: '99'},
        },
      ]

      const tray = shallow(<SubmissionProgressBars submissions={submissions} />)
      expect(
        tray
          .find('Link')
          .getElement()
          .props.href.match(/submissions\/99/)
      ).toBeTruthy()
    })
  })
})
