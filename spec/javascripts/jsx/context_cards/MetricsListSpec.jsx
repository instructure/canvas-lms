define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/context_cards/MetricsList'
], (React, ReactDOM, TestUtils, MetricsList) => {

  module('StudentContextTray/MetricsList', (hooks) => {
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

    module('grade', (hooks) => {
      test('returns null by default', () => {
        subject = TestUtils.renderIntoDocument(
          <MetricsList />
        )
        notOk(subject.grade)
      })

      test('returns current_grade if present', () => {
        const currentGrade = 'A+'
        subject = TestUtils.renderIntoDocument(
          <MetricsList
            user={{
              enrollments: [{
                grades: {
                  current_grade: currentGrade
                },
                sections: []
              }]
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
              enrollments: [{
                grades: {
                  current_grade: null,
                  current_score: currentScore
                },
                sections: []
              }]
            }}
          />
        )

        equal(subject.grade, `${currentScore}%`)
      })
    })

    module('missingCount', (hooks) => {
      test('returns null by default', () => {
        subject = TestUtils.renderIntoDocument(
          <MetricsList />
        )
        notOk(subject.missingCount)
      })

      test('returns count from analytics data when present', () => {
        const missingCount = 3
        subject = TestUtils.renderIntoDocument(
          <MetricsList
            analytics={{
              tardiness_breakdown: {
                missing: missingCount
              }
            }}
          />
        )

        equal(subject.missingCount, missingCount)
      })
    })

    module('lateCount', () => {
      test('returns null by default', () => {
        subject = TestUtils.renderIntoDocument(
          <MetricsList />
        )
        notOk(subject.lateCount)
      })

      test('returns value from analytics when present', () => {
        const lateCount = 5
        subject = TestUtils.renderIntoDocument(
          <MetricsList
            analytics={{
              tardiness_breakdown: {
                late: lateCount
              }
            }}
          />
        )

        equal(subject.lateCount, lateCount)
      })
    })
  })
})
