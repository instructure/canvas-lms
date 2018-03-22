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

define([
  'jsx/grading/helpers/OutlierScoreHelper',
  'compiled/gradebook/GradebookTranslations'
], ({ default: OutlierScoreHelper, isUnusuallyHigh }, GRADEBOOK_TRANSLATIONS) => {

  QUnit.module('#hasWarning', () => {
    test('returns true for exacty 1.5 times points possible', () => {
      ok(new OutlierScoreHelper(150, 100).hasWarning());
    });

    test('returns true when above 1.5 times and decimal is present', () => {
      ok(new OutlierScoreHelper(150.01, 100).hasWarning());
    });

    test('returns true when value is negative', () => {
      ok(new OutlierScoreHelper(-1, 100).hasWarning());
    });

    test('returns false when value is less than 1.5 times', () => {
      notOk(new OutlierScoreHelper(149.99, 100).hasWarning());
    });

    test('returns false for 0 points', () => {
      notOk(new OutlierScoreHelper(0, 100).hasWarning());
    });

    test('returns false for 0 points possible', () => {
      notOk(new OutlierScoreHelper(10, 0).hasWarning());
    });

    test('return false for null score', () => {
      notOk(new OutlierScoreHelper(null, 100).hasWarning());
    });

    test('return false for null points possible', () => {
      notOk(new OutlierScoreHelper(10, null).hasWarning());
    });

    test('return false for NaN score', () => {
      notOk(new OutlierScoreHelper(NaN, 100).hasWarning());
    });

    test('return false for NaN pointsPossible', () => {
      notOk(new OutlierScoreHelper(10, NaN).hasWarning());
    });
  });

  QUnit.module('#isUnusuallyHigh', () => {
    test('returns true for exacty 1.5 times points possible', () => {
      ok(isUnusuallyHigh(150, 100));
    });

    test('returns true when above 1.5 times and decimal is present', () => {
      ok(isUnusuallyHigh(150.01, 100));
    });

    test('returns false when value is less than 1.5 times', () => {
      notOk(isUnusuallyHigh(149.99, 100));
    });

    test('returns false for 0 points', () => {
      notOk(isUnusuallyHigh(0, 100));
    });

    test('returns false for 0 points possible', () => {
      notOk(isUnusuallyHigh(10, 0));
    });

    test('return false for null score', () => {
      notOk(isUnusuallyHigh(null, 100));
    });

    test('return false for null points possible', () => {
      notOk(isUnusuallyHigh(10, null));
    });

    test('return false for NaN score', () => {
      notOk(isUnusuallyHigh(NaN, 100));
    });

    test('return false for NaN pointsPossible', () => {
      notOk(isUnusuallyHigh(10, NaN));
    });
  });

  QUnit.module('#warningMessage', {
    setup() {
      this.tooManyPointsWarning =
        GRADEBOOK_TRANSLATIONS.submission_too_many_points_warning;
      this.negativePointsWarning =
        GRADEBOOK_TRANSLATIONS.submission_negative_points_warning;
    }
  });

  test('positive score outside 1.5 multipler returns too many points warning',
    function() {
    const outlierScore = new OutlierScoreHelper(150, 100);
    equal(outlierScore.warningMessage(), this.tooManyPointsWarning);
  });

  test('negative score returns negative points warning', function() {
    const outlierScore = new OutlierScoreHelper(-1, 100);
    equal(outlierScore.warningMessage(), this.negativePointsWarning);
  });

  test('score within range returns null', function() {
    const outlierScore = new OutlierScoreHelper(100, 100);
    equal(outlierScore.warningMessage(), null);
  });
});
