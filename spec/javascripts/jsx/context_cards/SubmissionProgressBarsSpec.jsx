define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/context_cards/SubmissionProgressBars',
  'instructure-ui/Progress'
], (React, ReactDOM, TestUtils, SubmissionProgressBars, { default: InstUIProgress }) => {

  module('StudentContextTray/Progress', (hooks) => {
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

    module('displayGrade', (hooks) => {
      hooks.beforeEach(() => {
        subject = TestUtils.renderIntoDocument(
          <SubmissionProgressBars submissions={[]} />
        )
      })

      module('when submission is excused', (hooks) => {
        test('it returns `EX`', () => {
          submission = { id: 1, excused: true, assignment: {points_possible: 25} }
          grade = subject.displayGrade(submission)
          equal(grade, 'EX')
        })
      })

      module('when grade is a percentage', () => {
        test('it returns the grade', () => {
          const percentage = "80%"
          submission = {
            id: 1,
            excused: false,
            grade: percentage,
            assignment: {points_possible: 25}
          }
          grade = subject.displayGrade(submission)
          equal(grade, percentage)
        })
      })

      module('when grade is complete or incomplete', () => {
        test('it calls `renderIcon`', () => {
          submission = {
            id: 1,
            excused: false,
            assignment: {points_possible: 25}
          }
          spy = sinon.spy(subject, 'renderIcon')

          subject.displayGrade({...submission, grade: 'complete'})
          ok(spy.calledOnce)
          spy.reset()

          subject.displayGrade({...submission, grade: 'incomplete'})
          ok(spy.calledOnce)
          subject.renderIcon.restore()
        })
      })

      module('when grade is a random string', () => {
        test('it renders `score/points_possible`', () => {
          const pointsPossible = 25
          const score = '15'
          grade = "A+"
          submission = {
            id: 1,
            excused: false,
            grade: grade,
            score: score,
            assignment: {points_possible: pointsPossible}
          }
          equal(subject.displayGrade(submission), `${score}/${pointsPossible}`)
        })
      })

      module('by default', () => {
        test('it renders `score/points_possible`', () => {
          const pointsPossible = 25
          grade = '15'
          score = '15'
          submission = {
            id: 1,
            excused: false,
            grade: grade,
            score: score,
            assignment: {points_possible: pointsPossible}
          }
          equal(subject.displayGrade(submission), `${score}/${pointsPossible}`)
        })
      })
    })

    module('renderIcon', (hooks) => {
      module('when grade is `complete`', () => {
        test('renders icon with `icon-check` class', () => {
          subject = TestUtils.renderIntoDocument(
            <SubmissionProgressBars submissions={[{
              id: 1,
              grade: 'complete',
              score: 25,
              assignment: {points_possible: 25}
            }]} />
          )
          tag = TestUtils.findRenderedDOMComponentWithTag(subject, 'i')
          equal(tag.className, 'icon-check')
        })
      })

      module('when grade is `complete`', () => {
        test('renders icon with `icon-check` class', () => {
          subject = TestUtils.renderIntoDocument(
            <SubmissionProgressBars submissions={[{
              id: 1,
              grade: 'incomplete',
              score: 0,
              assignment: {points_possible: 25}
            }]} />
          )
          tag = TestUtils.findRenderedDOMComponentWithTag(subject, 'i')
          equal(tag.className, 'icon-x')
        })
      })
    })

    module('render', () => {
      test('renders one InstUIProgress component per submission', () => {
        const submissions = [{
          id: 1,
          grade: 'incomplete',
          score: 0,
          assignment: {points_possible: 25}
        }, {
          id: 2,
          grade: 'complete',
          score: 25,
          assignment: {points_possible: 25}
        }, {
          id: 3,
          grade: 'A+',
          score: 25,
          assignment: {points_possible: 25}
        }]
        subject = TestUtils.renderIntoDocument(
          <SubmissionProgressBars submissions={submissions} />
        )
        const instUIProgressBars = TestUtils.scryRenderedComponentsWithType(subject, InstUIProgress)
        equal(instUIProgressBars.length, submissions.length)
      })
    })
  })
})
