/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import fakeENV from '@canvas/test-utils/fakeENV'
import rubric_assessment from '../rubric_assessment'

describe('RubricAssessment', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    document.body.innerHTML = ''
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  describe('roundAndFormat', () => {
    it('rounds given number to two decimal places', () => {
      expect(rubric_assessment.roundAndFormat(42.325)).toBe('42.33')
      expect(rubric_assessment.roundAndFormat(42.324)).toBe('42.32')
    })

    it('returns empty string when passed null, undefined or empty string', () => {
      expect(rubric_assessment.roundAndFormat(null)).toBe('')
      expect(rubric_assessment.roundAndFormat(undefined)).toBe('')
      expect(rubric_assessment.roundAndFormat('')).toBe('')
    })
  })

  describe('highlightCriterionScore', () => {
    it('adds the "selected" class to a rating when score is equal', () => {
      const $criterion = $(`
        <div class="criterion">
          <div class="rating">
            <span class="points">5</span>
          </div>
          <div class="rating">
            <span class="points">3</span>
          </div>
          <div class="rating">
            <span class="points">0</span>
          </div>
        </div>
      `)
      document.body.appendChild($criterion[0])

      rubric_assessment.highlightCriterionScore($criterion, 3)
      expect($criterion.find('.rating').eq(1).hasClass('selected')).toBe(true)
    })

    it('adds the "selected" class to proper rating when score is in range', () => {
      const $criterion = $(`
        <div class="criterion">
          <input type="checkbox" class="criterion_use_range" checked="checked" />
          <div class="rating">
            <span class="points">5</span>
          </div>
          <div class="rating">
            <span class="points">3</span>
          </div>
          <div class="rating">
            <span class="points">0</span>
          </div>
        </div>
      `)
      document.body.appendChild($criterion[0])

      rubric_assessment.highlightCriterionScore($criterion, 4)
      expect($criterion.find('.rating').eq(0).hasClass('selected')).toBe(true)
      expect($criterion.find('.rating').eq(1).hasClass('selected')).toBe(false)
      expect($criterion.find('.rating').eq(2).hasClass('selected')).toBe(false)
    })
  })

  describe('checkScoreAdjustment', () => {
    let flashWarning

    beforeEach(() => {
      flashWarning = jest.fn()
      $.flashWarning = flashWarning
    })

    it('displays a flash warning when rawPoints has been adjusted', () => {
      const $criterion = $(`
        <div class="criterion" id="criterion_1">
          <div class="description_title">Some Criterion</div>
          <input type="hidden" name="rubric_assessment[criterion_1][points]" value="12" />
        </div>
      `)
      document.body.appendChild($criterion[0])

      const rating = {points: 12, criterion_id: 1}
      const rawData = {'rubric_assessment[criterion_1][points]': '15'}

      rubric_assessment.checkScoreAdjustment($criterion, rating, rawData)
      expect(flashWarning).toHaveBeenCalledWith(
        'Extra credit not permitted on outcomes, score adjusted to maximum possible for Some Criterion',
      )
    })

    it('does not display a flash warning when rawPoints has not been adjusted', () => {
      const $criterion = $(`
        <div class="criterion" id="criterion_1">
          <div class="description_title">Some Criterion</div>
          <input type="hidden" name="rubric_assessment[criterion_1][points]" value="12" />
        </div>
      `)
      document.body.appendChild($criterion[0])

      const rating = {points: 12, criterion_id: 1}
      const rawData = {'rubric_assessment[criterion_1][points]': '12'}

      rubric_assessment.checkScoreAdjustment($criterion, rating, rawData)
      expect(flashWarning).not.toHaveBeenCalled()
    })
  })

  describe('getCriteriaAssessmentId', () => {
    it('returns undefined if id is null', () => {
      expect(rubric_assessment.getCriteriaAssessmentId(null)).toBeUndefined()
    })

    it('returns undefined if id is "null"', () => {
      expect(rubric_assessment.getCriteriaAssessmentId('null')).toBeUndefined()
    })

    it('returns the id if id is not null and not "null"', () => {
      expect(rubric_assessment.getCriteriaAssessmentId(5)).toBe(5)
    })
  })

  describe('assessmentData', () => {
    const createRubric = (contents = '') => $(`<div class="rubric">${contents}</div>`)

    beforeEach(() => {
      fakeENV.setup()
      ENV.RUBRIC_ASSESSMENT = {}
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('returns the user ID if assessment_user_id exists in the environment', () => {
      ENV.RUBRIC_ASSESSMENT.assessment_user_id = '123'
      const data = rubric_assessment.assessmentData(createRubric())
      expect(data['rubric_assessment[user_id]']).toBe('123')
    })

    it('returns the user ID if one exists in the submitted rubric', () => {
      const rubric = createRubric(`<div class="user_id">234</div>`)
      const data = rubric_assessment.assessmentData(rubric)
      expect(data['rubric_assessment[user_id]']).toBe('234')
    })

    it('returns the anonymous ID if anonymous_id exists in the environment', () => {
      ENV.RUBRIC_ASSESSMENT.anonymous_id = '7a8c1'
      const data = rubric_assessment.assessmentData(createRubric())
      expect(data['rubric_assessment[anonymous_id]']).toBe('7a8c1')
    })

    it('returns the anonymous ID if one exists in the submitted rubric', () => {
      const rubric = createRubric(`<div class="anonymous_id">81bc2</div>`)
      const data = rubric_assessment.assessmentData(rubric)
      expect(data['rubric_assessment[anonymous_id]']).toBe('81bc2')
    })

    it('returns the user ID if both flavors of ID are available', () => {
      const rubric = createRubric(`
        <div class="user_id">100</div>
        <div class="anonymous_id">81bc2</div>
      `)
      const data = rubric_assessment.assessmentData(rubric)
      expect(data['rubric_assessment[user_id]']).toBe('100')
    })

    it('omits the anonymous ID if both flavors of ID are available', () => {
      const rubric = createRubric(`
        <div class="user_id">100</div>
        <div class="anonymous_id">81bc2</div>
      `)
      const data = rubric_assessment.assessmentData(rubric)
      expect(data['rubric_assessment[anonymous_id]']).toBeUndefined()
    })
  })

  describe('populateRubric', () => {
    let $rubric

    beforeEach(() => {
      fakeENV.setup()
      ENV.RUBRIC_ASSESSMENT = {}
      $rubric = $(`
        <div class="rubric" id="this_is_not_actually_used">
          <div class="user_id"></div>
          <div class="anonymous_id"></div>
        </div>
      `)
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('populates the user_id element with ENV.assessment_user_id if present', () => {
      ENV.RUBRIC_ASSESSMENT.assessment_user_id = '123'
      rubric_assessment.populateRubric($rubric, {})
      expect($rubric.find('.user_id').text()).toBe('123')
    })

    it('populates the user_id element with the value from the passed-in data if present', () => {
      rubric_assessment.populateRubric($rubric, {user_id: '432'})
      expect($rubric.find('.user_id').text()).toBe('432')
    })

    it('populates the anonymous_id element with ENV.anonymous_id if present', () => {
      ENV.RUBRIC_ASSESSMENT.anonymous_id = 'vcx12'
      rubric_assessment.populateRubric($rubric, {})
      expect($rubric.find('.anonymous_id').text()).toBe('vcx12')
    })

    it('populates the anonymous_id element with the value from the passed-in data if present', () => {
      rubric_assessment.populateRubric($rubric, {anonymous_id: 'vv191'})
      expect($rubric.find('.anonymous_id').text()).toBe('vv191')
    })

    it('populates the user_id element if both flavors of ID are available', () => {
      rubric_assessment.populateRubric($rubric, {user_id: '77', anonymous_id: 'vv191'})
      expect($rubric.find('.user_id').text()).toBe('77')
    })

    it('does not populate the anonymous_id element if both flavors of ID are available', () => {
      rubric_assessment.populateRubric($rubric, {user_id: '77', anonymous_id: 'vv191'})
      expect($rubric.find('.anonymous_id').text()).toBe('')
    })
  })
})
