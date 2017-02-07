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
  'compiled/util/round',
  'jsx/gradebook/AssignmentGroupGradeCalculator'
], function (_, round, AssignmentGroupGradeCalculator) {
  const sum = function (collection) {
    return _.reduce(collection, function (sum, value) {
      return sum + value;
    }, 0);
  };

  const sumBy = function (collection, attr) {
    const values = _.map(collection, attr);
    return sum(values);
  };

  const getGroupSumWeightedPercent = ({ score, possible, weight }) => {
    return (score / possible) * weight;
  };

  const calculateTotal = function (groupSums, includeUngraded, weightingScheme) {
    groupSums = _.map(groupSums, function (groupSum) {
      const sumVersion = includeUngraded ? groupSum.final : groupSum.current;
      return { ...sumVersion, weight: groupSum.group.group_weight };
    });

    if (weightingScheme === 'percent') {
      const relevantGroupSums = _.filter(groupSums, 'possible');
      let finalGrade = sum(_.map(relevantGroupSums, getGroupSumWeightedPercent));
      const fullWeight = sumBy(relevantGroupSums, 'weight');
      if (fullWeight === 0) {
        finalGrade = null;
      } else if (fullWeight < 100) {
        finalGrade = finalGrade * 100 / fullWeight;
      }

      const submissionCount = sumBy(relevantGroupSums, 'submission_count');
      const possible = ((submissionCount > 0) || includeUngraded) ? 100 : 0;
      let score = finalGrade && round(finalGrade, 2);
      score = isNaN(score) ? null : score;

      return { score, possible };
    } else {
      return {
        score: sumBy(groupSums, 'score'),
        possible: sumBy(groupSums, 'possible')
      }
    }
  };

  // Each submission requires the following properties:
  // * score: number
  // * points_possible: non-negative integer
  // * assignment_id: Canvas id
  // * assignment_group_id: Canvas id
  // * excused: boolean
  //
  // To represent assignments which the student has not yet submitted, set the
  // score of the related submission to `null`.
  //
  // Each assignment group requires the following properties:
  // * id: Canvas id
  // * rules: object *see below
  // * group_weight: non-negative number
  // * assignments: array *see below
  //
  // `rules` has the following properties:
  // * drop_lowest: non-negative integer
  // * drop_highest: non-negative integer
  // * never_drop: [array of assignment ids]
  //
  // `assignments` is an array of objects with the following properties:
  // * id: Canvas id
  // * points_possible: non-negative number
  // * submission_types: [array of strings]
  //
  // The weighting scheme is one of [`percent`, `points`]
  //
  // When weightingScheme is `percent`, assignment group weights are used.
  // Otherwise, no weighting is applied.
  const calculate = function (submissions, assignmentGroups, weightingScheme) {
    const groupSums = _.map(assignmentGroups, function (group) {
      return AssignmentGroupGradeCalculator.calculate(submissions, group);
    });

    return {
      group_sums: groupSums,
      current: calculateTotal(groupSums, false, weightingScheme),
      final: calculateTotal(groupSums, true, weightingScheme)
    };
  };

  return {
    calculate
  };
});
