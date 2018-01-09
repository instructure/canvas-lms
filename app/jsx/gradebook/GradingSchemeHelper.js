/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import round from 'compiled/util/round'
import _ from 'underscore'

export function scoreToGrade (score, gradingScheme) {
  const roundedScore = round(score, 4);
  const scoreWithLowerBound = Math.max(roundedScore, 0);
  const letter = _.find(gradingScheme, (row, i) => {
    const schemeScore = (row[1] * 100).toPrecision(4);
    // The precision of the lower bound (* 100) must be limited to eliminate
    // floating-point errors.
    // e.g. 0.545 * 100 returns 54.50000000000001 in JavaScript.
    return scoreWithLowerBound >= schemeScore || i === (gradingScheme.length - 1);
  });
  return letter[0];
}

export default {
  scoreToGrade
}
