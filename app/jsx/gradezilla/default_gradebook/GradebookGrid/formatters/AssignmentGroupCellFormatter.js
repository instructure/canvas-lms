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

import round from 'compiled/util/round';
import I18n from 'i18nObj';
import {scoreToPercentage} from '../../../../gradebook/shared/helpers/GradeCalculationHelper'

function getGradePercentage (score, pointsPossible) {
  const grade = scoreToPercentage(score, pointsPossible)
  return round(grade, round.DEFAULT);
}

function render (options) {
  const percentage = options.possible ? options.percentage : '-';

  // xsslint safeString.property score possible
  // xsslint safeString.identifier percentage
  return `
    <div class="gradebook-cell">
      <div class="gradebook-tooltip">${options.score} / ${options.possible}</div>
      <span class="percentage">${percentage}</span>
    </div>
  `;
}

export default class AssignmentGroupCellFormatter {
  render = (_row, _cell, value, _columnDef, _dataContext) => {
    if (value == null) {
      return '';
    }

    let percentage = getGradePercentage(value.score, value.possible);
    percentage = isFinite(percentage) ? percentage : 0;

    let possible = round(value.possible, round.DEFAULT);
    possible = possible ? I18n.n(possible) : possible;

    const templateOpts = {
      percentage: I18n.n(round(percentage, round.DEFAULT), { percentage: true }),
      possible,
      score: I18n.n(round(value.score, round.DEFAULT))
    };

    return render(templateOpts);
  }
}
