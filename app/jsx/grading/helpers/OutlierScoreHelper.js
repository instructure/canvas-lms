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

import GRADEBOOK_TRANSLATIONS from 'compiled/gradebook/GradebookTranslations'

  const MULTIPLIER = 1.5;

  const isNegativePoints = function(score) {
    return score < 0;
  };

  const isUnusuallyHigh = function(score, pointsPossible) {
    if (pointsPossible === 0 || pointsPossible == null) { return false; }
    const outlierBoundary = pointsPossible * MULTIPLIER;
    return score >= outlierBoundary;
  };

  class OutlierScoreHelper {
    constructor(score, pointsPossible) {
      this.score = score;
      this.pointsPossible = pointsPossible;
    }

    hasWarning() {
      // mutually exclusive
      return isNegativePoints(this.score) || isUnusuallyHigh(this.score, this.pointsPossible);
    }

    warningMessage() {
      if (isNegativePoints(this.score)) {
        return GRADEBOOK_TRANSLATIONS.submission_negative_points_warning;
      } else if (isUnusuallyHigh(this.score, this.pointsPossible)) {
        return GRADEBOOK_TRANSLATIONS.submission_too_many_points_warning;
      } else {
        return null;
      }
    }
  };

export { OutlierScoreHelper as default, isUnusuallyHigh }
