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
  'underscore'
], function (_) {
  const scoreToGrade = function (score, gradingScheme) {
    score = Math.max(score, 0);
    const letter = _.find(gradingScheme, function (row, i) {
      // The precision of the lower bound (* 100) must be limited to eliminate
      // floating-point errors.
      // e.g. 0.545 * 100 returns 54.50000000000001 in JavaScript.
      return score >= (row[1] * 100).toPrecision(4) || i === (gradingScheme.length - 1);
    });
    return letter[0];
  };

  return {
    scoreToGrade
  };
});
