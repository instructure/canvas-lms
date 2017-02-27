/*
 * Copyright (C) 2016 Instructure, Inc.
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
  'underscore',
  'jsx/gradebook/GradingSchemeHelper'
], (_, GradingSchemeHelper) => {
  QUnit.module('GradingSchemeHelper.scoreToGrade');

  test('returns the lowest grade to below-scale scores', () => {
    const gradingScheme = [['A', 0.90], ['B', 0.80], ['C', 0.70], ['D', 0.60], ['E', 0.50]];
    equal(GradingSchemeHelper.scoreToGrade(40, gradingScheme), 'E');
  });

  test('accounts for floating-point rounding errors', () => {
    // Keep this spec close to identical to the ruby GradeCalculator specs to ensure they both do the same thing.
    const gradingScheme = [
      ['A', 0.90], ['B+', 0.886], ['B', 0.80], ['C', 0.695], ['D', 0.555], ['E', 0.545], ['M', 0.00]
    ];
    equal(GradingSchemeHelper.scoreToGrade(1005, gradingScheme), 'A');
    equal(GradingSchemeHelper.scoreToGrade(105, gradingScheme), 'A');
    equal(GradingSchemeHelper.scoreToGrade(100, gradingScheme), 'A');
    equal(GradingSchemeHelper.scoreToGrade(99, gradingScheme), 'A');
    equal(GradingSchemeHelper.scoreToGrade(90, gradingScheme), 'A');
    equal(GradingSchemeHelper.scoreToGrade(89.999, gradingScheme), 'B+');
    equal(GradingSchemeHelper.scoreToGrade(88.601, gradingScheme), 'B+');
    equal(GradingSchemeHelper.scoreToGrade(88.6, gradingScheme), 'B+');
    equal(GradingSchemeHelper.scoreToGrade(88.599, gradingScheme), 'B');
    equal(GradingSchemeHelper.scoreToGrade(80, gradingScheme), 'B');
    equal(GradingSchemeHelper.scoreToGrade(79.999, gradingScheme), 'C');
    equal(GradingSchemeHelper.scoreToGrade(79, gradingScheme), 'C');
    equal(GradingSchemeHelper.scoreToGrade(69.501, gradingScheme), 'C');
    equal(GradingSchemeHelper.scoreToGrade(69.5, gradingScheme), 'C');
    equal(GradingSchemeHelper.scoreToGrade(69.499, gradingScheme), 'D');
    equal(GradingSchemeHelper.scoreToGrade(60, gradingScheme), 'D');
    equal(GradingSchemeHelper.scoreToGrade(55.5, gradingScheme), 'D');
    equal(GradingSchemeHelper.scoreToGrade(54.5, gradingScheme), 'E');
    equal(GradingSchemeHelper.scoreToGrade(50, gradingScheme), 'M');
    equal(GradingSchemeHelper.scoreToGrade(0, gradingScheme), 'M');
    equal(GradingSchemeHelper.scoreToGrade(-100, gradingScheme), 'M');
  });
});
