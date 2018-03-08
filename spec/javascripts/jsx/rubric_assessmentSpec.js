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

define(['rubric_assessment', 'i18n!rubric_assessment'], (rubric_assessment, I18n) => {
  QUnit.module('RubricAssessment#roundAndFormat')

  test('rounds given number to two decimal places', function() {
    strictEqual(rubric_assessment.roundAndFormat(42.325), '42.33')
    strictEqual(rubric_assessment.roundAndFormat(42.324), '42.32')
  })

  test('formats given number with I18n.n', function() {
    this.stub(I18n, 'n').returns('formatted_number')
    strictEqual(rubric_assessment.roundAndFormat(42), 'formatted_number')
    strictEqual(I18n.n.callCount, 1)
    ok(I18n.n.calledWith(42))
  })

  test('returns empty string when passed null, undefined or empty string', function() {
    strictEqual(rubric_assessment.roundAndFormat(null), '')
    strictEqual(rubric_assessment.roundAndFormat(undefined), '')
    strictEqual(rubric_assessment.roundAndFormat(''), '')
  })
})
