/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate'
import '@canvas/rails-flash-notifications'

import fakeENV from 'helpers/fakeENV'
import rubric_assessment from '@canvas/rubrics/jquery/rubric_assessment'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('rubric_assessment')

QUnit.module('RubricAssessment#roundAndFormat')

test('rounds given number to two decimal places', () => {
  strictEqual(rubric_assessment.roundAndFormat(42.325), '42.33')
  strictEqual(rubric_assessment.roundAndFormat(42.324), '42.32')
})

test('formats given number with I18n.n', () => {
  sandbox.stub(I18n.constructor.prototype, 'n').returns('formatted_number')
  strictEqual(rubric_assessment.roundAndFormat(42), 'formatted_number')
  strictEqual(I18n.n.callCount, 1)
  ok(I18n.n.calledWith(42))
})

test('returns empty string when passed null, undefined or empty string', () => {
  strictEqual(rubric_assessment.roundAndFormat(null), '')
  strictEqual(rubric_assessment.roundAndFormat(undefined), '')
  strictEqual(rubric_assessment.roundAndFormat(''), '')
})

test('properly adds the "selected" class to a rating when score is equal', () => {
  const $criterion = $(
    '<span>' +
      "<span class='rating'><span class='points'>5</span></span>" +
      "<span class='rating'><span class='points'>3</span></span>" +
      "<span class='rating'><span class='points'>0</span></span>" +
      '</span>'
  )
  rubric_assessment.highlightCriterionScore($criterion, 3)
  strictEqual($criterion.find('.selected').find('.points').text(), '3')
})

test('properly adds the "selected" class to proper rating when score is in range', () => {
  const $criterion = $(
    '<span>' +
      "<input type='checkbox' class='criterion_use_range' checked>" +
      "<span class='rating'><span class='points'>5</span></span>" +
      "<span class='rating'><span class='points'>3</span></span>" +
      "<span class='rating'><span class='points'>0</span></span>" +
      '</span>'
  )
  rubric_assessment.highlightCriterionScore($criterion, 4)
  strictEqual($criterion.find('.selected').length, 1)
  strictEqual($criterion.find('.selected').find('.points').text(), '5')
})

QUnit.module('RubricAssessment#checkScoreAdjustment')
test('displays a flash warning when rawPoints has been adjusted', () => {
  const flashSpy = sinon.spy($, 'flashWarning')
  const $criterion = $(
    '<span>' +
      "<span class='description_title'>Some Criterion</span>" +
      "<span class='rating'><span class='points'>5</span></span>" +
      "<span class='rating'><span class='points'>3</span></span>" +
      "<span class='rating'><span class='points'>0</span></span>" +
      '</span>'
  )
  const rating = {points: 5, criterion_id: 1}
  const rawData = {'rubric_assessment[criterion_1][points]': 15}
  rubric_assessment.checkScoreAdjustment($criterion, rating, rawData)
  ok(
    flashSpy.calledWith(
      'Extra credit not permitted on outcomes, score adjusted to maximum possible for Some Criterion'
    )
  )
  flashSpy.restore()
})

test('does not display a flash warning when rawPoints has not been adjusted', () => {
  const flashSpy = sinon.spy($, 'flashWarning')
  const $criterion = $(
    '<span>' +
      "<span class='description_title'>Some Criterion</span>" +
      "<span class='rating'><span class='points'>5</span></span>" +
      "<span class='rating'><span class='points'>3</span></span>" +
      "<span class='rating'><span class='points'>0</span></span>" +
      '</span>'
  )
  const rating = {points: 5, criterion_id: 1}
  const rawData = {'rubric_assessment[criterion_1][points]': 5}
  rubric_assessment.checkScoreAdjustment($criterion, rating, rawData)
  equal(flashSpy.callCount, 0)
  flashSpy.restore()
})

QUnit.module('RubricAssessment', moduleHooks => {
  moduleHooks.beforeEach(() => {
    fakeENV.setup()
    ENV.RUBRIC_ASSESSMENT = {}
  })

  moduleHooks.afterEach(() => {
    fakeENV.teardown()
  })

  QUnit.module('#getCriteriaAssessmentId', () => {
    test('returns undefined if id is null', () => {
      const id = rubric_assessment.getCriteriaAssessmentId(null)

      strictEqual(id, undefined)
    })

    test('returns undefined if id is "null"', () => {
      const id = rubric_assessment.getCriteriaAssessmentId('null')

      strictEqual(id, undefined)
    })

    test('returns the id if id is not null and not "null"', () => {
      const id = rubric_assessment.getCriteriaAssessmentId(5)

      strictEqual(id, 5)
    })
  })

  QUnit.module('#assessmentData', () => {
    const createRubric = (contents = '') => $(`<div class="rubric">${contents}</div>`)

    test('returns the user ID if assessment_user_id exists in the environment', () => {
      ENV.RUBRIC_ASSESSMENT.assessment_user_id = '123'
      const data = rubric_assessment.assessmentData(createRubric())

      strictEqual(data['rubric_assessment[user_id]'], '123')
    })

    test('returns the user ID if one exists in the submitted rubric', () => {
      const rubric = createRubric(`<div class="user_id">234</div>`)
      const data = rubric_assessment.assessmentData(rubric)

      strictEqual(data['rubric_assessment[user_id]'], '234')
    })

    test('returns the anonymous ID if anonymous_id exists in the environment', () => {
      ENV.RUBRIC_ASSESSMENT.anonymous_id = '7a8c1'
      const data = rubric_assessment.assessmentData(createRubric())

      strictEqual(data['rubric_assessment[anonymous_id]'], '7a8c1')
    })

    test('returns the anonymous ID if one exists in the submitted rubric', () => {
      const rubric = createRubric(`<div class="anonymous_id">81bc2</div>`)
      const data = rubric_assessment.assessmentData(rubric)

      strictEqual(data['rubric_assessment[anonymous_id]'], '81bc2')
    })

    test('returns the user ID if both flavors of ID are available', () => {
      const rubric = createRubric(`
        <div class="user_id">100</div>
        <div class="anonymous_id">81bc2</div>
      `)
      const data = rubric_assessment.assessmentData(rubric)

      strictEqual(data['rubric_assessment[user_id]'], '100')
    })

    test('omits the anonymous ID if both flavors of ID are available', () => {
      const rubric = createRubric(`
        <div class="user_id">100</div>
        <div class="anonymous_id">81bc2</div>
      `)
      const data = rubric_assessment.assessmentData(rubric)

      strictEqual(data['rubric_assessment[anonymous_id]'], undefined)
    })
  })

  QUnit.module('#populateRubric', hooks => {
    let $rubric

    hooks.beforeEach(() => {
      $rubric = $(`
        <div class="rubric" id="this_is_not_actually_used">
          <div class="user_id">
          <div class="anonymous_id">
        </div>
      `)
    })

    test('populates the user_id element of the passed-in rubric with ENV.assessment_user_id if present', () => {
      ENV.RUBRIC_ASSESSMENT.assessment_user_id = '123'
      rubric_assessment.populateRubric($rubric, {})
      strictEqual($rubric.find('.user_id').text(), '123')
    })

    test('populates the user_id element of the passed-in rubric with the value from the passed-in data if present', () => {
      rubric_assessment.populateRubric($rubric, {user_id: '432'})
      strictEqual($rubric.find('.user_id').text(), '432')
    })

    test('populates the anonymous_id element of the passed-in rubric with ENV.anonymous_id if present', () => {
      ENV.RUBRIC_ASSESSMENT.anonymous_id = 'vcx12'
      rubric_assessment.populateRubric($rubric, {})
      strictEqual($rubric.find('.anonymous_id').text(), 'vcx12')
    })

    test('populates the anonymous_id element of the passed-in rubric with the value from the passed-in data if present', () => {
      rubric_assessment.populateRubric($rubric, {anonymous_id: 'vv191'})
      strictEqual($rubric.find('.anonymous_id').text(), 'vv191')
    })

    test('populates the user_id element if both flavors of ID are available', () => {
      rubric_assessment.populateRubric($rubric, {user_id: '77', anonymous_id: 'vv191'})
      strictEqual($rubric.find('.user_id').text(), '77')
    })

    test('does not populate the anonymous_id element if both flavors of ID are available', () => {
      rubric_assessment.populateRubric($rubric, {user_id: '77', anonymous_id: 'vv191'})
      strictEqual($rubric.find('.anonymous_id').text(), '')
    })
  })
})
