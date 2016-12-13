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
], (_, round, AssignmentGroupGradeCalculator) => {
  function sum (collection) {
    return _.reduce(collection, (total, value) => (total + value), 0);
  }

  function sumBy (collection, attr) {
    const values = _.map(collection, attr);
    return sum(values);
  }

  function getWeightedPercent ({ score, possible, weight }) {
    return (score / possible) * weight;
  }

  function combineAssignmentGroupGrades (assignmentGroupGrades, includeUngraded, options) {
    const scopedAssignmentGroupGrades = _.map(assignmentGroupGrades, (assignmentGroupGrade) => {
      const sumVersion = includeUngraded ? assignmentGroupGrade.final : assignmentGroupGrade.current;
      return { ...sumVersion, weight: assignmentGroupGrade.group.group_weight };
    });

    if (options.weightAssignmentGroups) {
      const relevantGroupGrades = _.filter(scopedAssignmentGroupGrades, 'possible');
      const fullWeight = sumBy(relevantGroupGrades, 'weight');

      let finalGrade = sum(_.map(relevantGroupGrades, getWeightedPercent));
      if (fullWeight === 0) {
        finalGrade = null;
      } else if (fullWeight < 100) {
        finalGrade = (finalGrade * 100) / fullWeight;
      }

      const submissionCount = sumBy(relevantGroupGrades, 'submission_count');
      const possible = ((submissionCount > 0) || includeUngraded) ? 100 : 0;
      let score = finalGrade && round(finalGrade, 2);
      score = isNaN(score) ? null : score;

      return { score, possible };
    }

    return {
      score: sumBy(scopedAssignmentGroupGrades, 'score'),
      possible: sumBy(scopedAssignmentGroupGrades, 'possible')
    }
  }

  function combineGradingPeriodGrades (gradingPeriodGradesByPeriodId, includeUngraded) {
    const scopedGradingPeriodGrades = _.map(gradingPeriodGradesByPeriodId, (gradingPeriodGrade) => {
      const gradesVersion = includeUngraded ? gradingPeriodGrade.final : gradingPeriodGrade.current;
      return { ...gradesVersion, weight: gradingPeriodGrade.weight };
    });

    const weightedScores = _.map(scopedGradingPeriodGrades, (gradingPeriodGrade) => {
      if (gradingPeriodGrade.score) {
        return getWeightedPercent(gradingPeriodGrade);
      }
      return 0;
    });

    const totalWeight = sumBy(scopedGradingPeriodGrades, 'weight');
    const totalScore = (sum(weightedScores) * 100) / Math.min(totalWeight, 100);

    return {
      score: round(totalScore, 2),
      possible: 100
    };
  }

  function divideGroupByGradingPeriods (assignmentGroup, effectiveDueDates) {
    const assignmentsByGradingPeriodId = _.groupBy(assignmentGroup.assignments, assignment => (
      effectiveDueDates[assignment.id].grading_period_id
    ));
    return _.map(assignmentsByGradingPeriodId, assignments => (
      { ...assignmentGroup, assignments }
    ));
  }

  function extractUsableAssignmentGroups (assignmentGroups, effectiveDueDates) {
    return _.reduce(assignmentGroups, (usableGroups, assignmentGroup) => {
      const assignedAssignments = _.filter(assignmentGroup.assignments, assignment => (
        effectiveDueDates[assignment.id]
      ));
      if (assignedAssignments.length > 0) {
        const groupWithAssignedAssignments = { ...assignmentGroup, assignments: assignedAssignments };
        return [
          ...usableGroups,
          ...divideGroupByGradingPeriods(groupWithAssignedAssignments, effectiveDueDates)
        ];
      }
      return usableGroups;
    }, []);
  }

  function calculateWithGradingPeriods (
    submissions, assignmentGroups, gradingPeriods, effectiveDueDates, options
  ) {
    const usableGroups = extractUsableAssignmentGroups(assignmentGroups, effectiveDueDates);

    const assignmentGroupsByGradingPeriodId = _.groupBy(usableGroups, (assignmentGroup) => {
      const assignmentId = assignmentGroup.assignments[0].id;
      return effectiveDueDates[assignmentId].grading_period_id;
    });

    const gradingPeriodsById = _.indexBy(gradingPeriods, 'id');
    const gradingPeriodGradesByPeriodId = {};
    const allAssignmentGroupGrades = [];

    _.forEach(gradingPeriods, (gradingPeriod) => {
      const groupGrades = {};

      (assignmentGroupsByGradingPeriodId[gradingPeriod.id] || []).forEach((assignmentGroup) => {
        groupGrades[assignmentGroup.id] = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
        allAssignmentGroupGrades.push(groupGrades[assignmentGroup.id]);
      });

      const groupGradesList = _.values(groupGrades);

      gradingPeriodGradesByPeriodId[gradingPeriod.id] = {
        weight: gradingPeriodsById[gradingPeriod.id].weight,
        current: combineAssignmentGroupGrades(groupGradesList, false, options),
        final: combineAssignmentGroupGrades(groupGradesList, true, options),
        assignmentGroups: groupGrades
      };
    });

    if (options.weightGradingPeriods) {
      return {
        gradingPeriods: gradingPeriodGradesByPeriodId,
        group_sums: allAssignmentGroupGrades,
        current: combineGradingPeriodGrades(gradingPeriodGradesByPeriodId, false, options),
        final: combineGradingPeriodGrades(gradingPeriodGradesByPeriodId, true, options)
      };
    }

    return {
      gradingPeriods: gradingPeriodGradesByPeriodId,
      group_sums: allAssignmentGroupGrades,
      current: combineAssignmentGroupGrades(allAssignmentGroupGrades, false, options),
      final: combineAssignmentGroupGrades(allAssignmentGroupGrades, true, options)
    };
  }

  function calculateWithoutGradingPeriods (submissions, assignmentGroups, options) {
    const assignmentGroupGrades = _.map(assignmentGroups, group => (
      AssignmentGroupGradeCalculator.calculate(submissions, group)
    ));

    return {
      group_sums: assignmentGroupGrades,
      current: combineAssignmentGroupGrades(assignmentGroupGrades, false, options),
      final: combineAssignmentGroupGrades(assignmentGroupGrades, true, options)
    };
  }

  // Each submission requires the following properties:
  // * score: number
  // * points_possible: non-negative integer
  // * assignment_id: Canvas id
  // * assignment_group_id: Canvas id
  // * excused: boolean
  //
  // Ungraded submissions will have a score of `null`.
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
  //
  // Grading periods and effective due dates are optional, but must be used
  // together.
  //
  // Each grading period requires the following properties:
  // * id: Canvas id
  // * weight: non-negative number
  //
  // `effectiveDueDates` is an object with at least the following shape:
  // {
  //   <assignment id (Canvas id)>: {
  //     grading_period_id: <grading period id (Canvas id)>
  //   }
  // }
  //
  // `effectiveDueDates` should generally include an assignment id for most/all
  // assignments in use for the course and student. The structure above is the
  // "user-scoped" form of effective due dates, which includes only the
  // necessary data to perform a grade calculation. Effective due date entries
  // would otherwise include more information about a student's relationship
  // with an assignment and related grading periods.
  //
  // GradingPeriod Grade information has the following shape:
  // {
  //   <grading period id (Canvas id)>: {
  //     assignmentGroups: {
  //       <assignment group id (Canvas id)>: <AssignmentGroup Grade information>
  //     }
  //   }
  // }
  //
  // Course Grade information has the following shape:
  // {
  //   score: number|null
  //   possible: number|null
  // }
  //
  // Each grading period will have a map for assignment group grades, keyed to
  // the id of assignment groups graded within the grading period. Not every
  // call to `calculate` will include grading period grades, as some courses do
  // not use grading periods.
  //
  // AssignmentGroup Grade information is the returned result from the
  // AssignmentGroupGradeCalculator.calculate function.
  //
  // Return value has the following shape:
  // {
  //   gradingPeriods: <GradingPeriod Grade information *see above>
  //   group_sums: [array of AssignmentGroup Grade information *see above]
  //   current: <Course Grade information *see above>
  //   final: <Grade Grade information *see above>
  // }
  function calculate (submissions, assignmentGroups, weightingScheme, gradingPeriods, effectiveDueDates) {
    const options = {
      weightGradingPeriods: _.some(gradingPeriods, 'weight'),
      weightAssignmentGroups: weightingScheme === 'percent'
    };

    if (gradingPeriods && effectiveDueDates) {
      return calculateWithGradingPeriods(
        submissions, assignmentGroups, gradingPeriods, effectiveDueDates, options
      );
    }

    return calculateWithoutGradingPeriods(submissions, assignmentGroups, options);
  }

  return {
    calculate
  };
});
