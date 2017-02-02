define([
  'react',
  'react-addons-test-utils',
  'jsx/context_cards/Rating',
  'instructure-ui'
], (React, TestUtils, Rating, { Rating: InstUIRating }) => {

  QUnit.module('StudentContextTray/Rating', () => {
    let subject
    const participationsLevel = 2

    QUnit.module('valueNow', () => {
      test('returns value associated with metricName', () => {
        subject = TestUtils.renderIntoDocument(
          <Rating
            label='Participation'
            metricName='participations_level'
            analytics={{
              participations_level: participationsLevel
            }}
          />
        )

        equal(subject.valueNow, participationsLevel)
      })
    })

    QUnit.module('formatValueText', () => {
      subject = TestUtils.renderIntoDocument(
        <Rating />
      )
      const valueText = [
        'None', 'Low', 'Moderate', 'High'
      ]
      valueText.forEach((v, i) => {
        test(`returns value ${v} for rating ${i}`, () => {
          equal(subject.formatValueText(i, 3), v)
        })
      })
    })

    QUnit.module('render', () => {
      test('delegates to InstUIRating', () => {
        subject = TestUtils.renderIntoDocument(
          <Rating
            label='Participation'
            metricName='participations_level'
            analytics={{
              participations_level: participationsLevel
            }}
          />
        )
        const instUIRating = TestUtils.findRenderedComponentWithType(subject, InstUIRating)
        equal(instUIRating.props.label, subject.props.label)
      })
    })
  })
})
