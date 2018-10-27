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
import 'compiled/jquery.rails_flash_notifications' // eslint-disable-line

import rubric_assessment from 'rubric_assessment'
import I18n from 'i18n!rubric_assessment'

QUnit.module('RubricAssessment#roundAndFormat')

test('rounds given number to two decimal places', function() {
  strictEqual(rubric_assessment.roundAndFormat(42.325), '42.33')
  strictEqual(rubric_assessment.roundAndFormat(42.324), '42.32')
})

test('formats given number with I18n.n', function() {
  sandbox.stub(I18n, 'n').returns('formatted_number')
  strictEqual(rubric_assessment.roundAndFormat(42), 'formatted_number')
  strictEqual(I18n.n.callCount, 1)
  ok(I18n.n.calledWith(42))
})

test('returns empty string when passed null, undefined or empty string', function() {
  strictEqual(rubric_assessment.roundAndFormat(null), '')
  strictEqual(rubric_assessment.roundAndFormat(undefined), '')
  strictEqual(rubric_assessment.roundAndFormat(''), '')
})

test('properly adds the "selected" class to a rating when score is equal', function() {
  const $criterion = $(
    '<span>' +
      "<span class='rating'><span class='points'>5</span></span>" +
      "<span class='rating'><span class='points'>3</span></span>" +
      "<span class='rating'><span class='points'>0</span></span>" +
      '</span>'
  )
  rubric_assessment.highlightCriterionScore($criterion, 3)
  strictEqual(
    $criterion
      .find('.selected')
      .find('.points')
      .text(),
    '3'
  )
})

test('properly adds the "selected" class to proper rating when score is in range', function() {
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
  strictEqual(
    $criterion
      .find('.selected')
      .find('.points')
      .text(),
    '5'
  )
})

QUnit.module('RubricAssessment#checkScoreAdjustment')
test('displays a flash warning when rawPoints has been adjusted', function() {
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

test('does not display a flash warning when rawPoints has not been adjusted', function() {
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
