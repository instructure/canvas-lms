/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

// @ts-ignore
import Big from 'big.js';

/**
 * @typedef {[string, number]} GradingStandard
 */

/**
 * @typedef {Object} GradingSchemeDataRow
 * @property {string} name
 * @property {number} value
 */

/**
 * @deprecated Use scoreToLetterGrade(score: number, gradingSchemeDataRows: GradingSchemeDataRow[]) instead, which takes
 * a more reasonably typed object model than the 2d array that this function takes in for gradingScheme data rows.
 * @param {number} score
 * @param {GradingStandard[]} gradingSchemes
 * @returns {?string}
 */
export function scoreToGrade(score, gradingSchemes) {
  // Because scoreToGrade is being used in a non typescript file, ui/features/grade_summary/jquery/index.js,
  // score can be NaN despite its type being declared as a number
  if (typeof score !== 'number' || Number.isNaN(score) || gradingSchemes == null) {
    return null;
  }

  // convert deprecated 2d array format to newer GradingSchemeDataRow[] format
  const gradingSchemeDataRows = gradingSchemes.map(row => ({ name: row[0], value: row[1] }));
  return scoreToLetterGrade(score, gradingSchemeDataRows);
}

/**
 * @param {number} score
 * @param {GradingSchemeDataRow[]} gradingSchemeDataRows
 * @returns {string}
 */
export function scoreToLetterGrade(score, gradingSchemeDataRows) {
  // Because scoreToGrade is being used in a non typescript file, ui/features/grade_summary/jquery/index.js,
  // score can be NaN despite its type being declared as a number
  if (typeof score !== 'number' || Number.isNaN(score) || gradingSchemeDataRows == null) {
    return null;
  }

  const roundedScore = parseFloat(Big(score).round(4));
  const scoreWithLowerBound = Math.max(roundedScore, 0);
  const letter = gradingSchemeDataRows.find((row, i) => {
    const schemeScore = (row.value * 100).toPrecision(4);
    return scoreWithLowerBound >= parseFloat(schemeScore) || i === gradingSchemeDataRows.length - 1;
  });
  if (!letter) {
    throw new Error('grading scheme not found');
  }
  return letter.name;
}
