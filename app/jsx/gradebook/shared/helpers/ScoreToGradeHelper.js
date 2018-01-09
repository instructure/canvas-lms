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

import GradeFormatHelper from '../../../gradebook/shared/helpers/GradeFormatHelper';

const DEFAULT_GRADE = '';

export default {
  scoreToGrade (score, assignment, gradingScheme) {
    if (score == null) {
      return DEFAULT_GRADE;
    }

    const gradingType = assignment.grading_type;

    switch (gradingType) {
      case 'points': {
        return GradeFormatHelper.formatGrade(score);
      }
      case 'percent': {
        if (!assignment.points_possible) {
          return DEFAULT_GRADE;
        }

        const percentage = 100 * (score / assignment.points_possible);
        return GradeFormatHelper.formatGrade(percentage, { gradingType });
      }
      case 'pass_fail': {
        const grade = score ? 'complete' : 'incomplete';
        return GradeFormatHelper.formatGrade(grade, { gradingType });
      }
      case 'letter_grade': {
        if (!gradingScheme || !assignment.points_possible) {
          return DEFAULT_GRADE;
        }

        const normalizedScore = score / assignment.points_possible;

        for (let i = 0; i < gradingScheme.length; i += 1) {
          if (gradingScheme[i][1] <= normalizedScore) {
            return gradingScheme[i][0];
          }
        }
      }
      // fall through
      default:
        return score;
    }
  }
}
