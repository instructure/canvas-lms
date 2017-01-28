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
  const sum = function (collection) {
    return _.reduce(collection, function (sum, value) {
      return sum + value;
    }, 0);
  };

  const sumBy = function (collection, attr) {
    const values = _.map(collection, attr);
    return sum(values);
  };

  const partition = function (collection, partitionFn) {
    const grouped = _.groupBy(collection, partitionFn);
    return [grouped[true] || [], grouped[false] || []];
  };

  const parseScore = function (score) {
    const result = parseFloat(score);
    return (result && isFinite(result)) ? result : 0;
  };


  // Some browser sorting functions (such as in V8) are not stable.
  // This function ensures that the same submission will be dropped regardless
  // of browser.
  const stableSubmissionSort = function (sortFn, getAssignmentIdFn) {
    return function (a, b) {
      const ret = sortFn(a, b);
      if (ret === 0) {
        return getAssignmentIdFn(a) - getAssignmentIdFn(b);
      } else {
        return ret;
      }
    };
  };

  const sortDescending = function ([a, xx], [b, yy]) {
    return b - a;
  };
  const sortAscending = function ([a, xx], [b, yy]) {
    return a - b;
  };
  const getAssignmentIdFn = function ([score, submission]) {
    return submission.submission.assignment_id;
  };

  const getSubmissionGrade = function ({ score, total }) {
    return score / total;
  };

  const estimateQHigh = function (pointed, unpointed, grades) {
    if (unpointed.length > 0) {
      const pointsPossible = sumBy(pointed, 'total');
      const bestPointedScore = Math.max(pointsPossible, sumBy(pointed, 'score'));
      const unpointedScore = sumBy(unpointed, 'score');
      return (bestPointedScore + unpointedScore) / pointsPossible;
    } else {
      return grades[grades.length - 1];
    }
  };

  const dropPointed = function (submissions, cannotDrop, keepHighest, keepLowest) {
    const totals = _.map(submissions, 'total');
    const maxTotal = Math.max.apply(Math, totals);

    const keepHelper = function (submissions, keep, bigFSort) {
      keep = Math.max(1, keep);

      if (submissions.length <= keep) {
        return submissions;
      }

      const allSubmissions = [...submissions, ...cannotDrop];
      const [unpointed, pointed] = partition(allSubmissions, function (submission) {
        return submission.total == 0;
      });

      const grades = _.map(pointed, getSubmissionGrade).sort();
      let qHigh = estimateQHigh(pointed, unpointed, grades);
      let qLow = grades[0];
      let qMid = (qLow + qHigh) / 2;

      const bigF = function (q, submissions) {
        const ratedScores  = _.map(submissions, function (submission) {
          return [submission.score - (q * submission.total), submission];
        });
        const rankedScores = ratedScores.sort(bigFSort);
        const keptScores = rankedScores.slice(0, keep);
        const qKept = sumBy(keptScores, function ([score]) {
          return score;
        });
        const keptSubmissions = _.map(keptScores, function ([score, submission]) {
          return submission;
        });
        const qCantDrop = sumBy(cannotDrop, function (submission) {
          return submission.score - q * submission.total;
        });
        return [qKept + qCantDrop, keptSubmissions];
      };

      let [x, kept] = bigF(qMid, submissions);
      const threshold = 1 / (2 * keep * Math.pow(maxTotal, 2));
      while (qHigh - qLow >= threshold) {
        if (x < 0) {
          qHigh = qMid;
        } else {
          qLow = qMid;
        }
        qMid = (qLow + qHigh) / 2;
        if (qMid === qHigh || qMid === qLow) {
          break;
        }

        [x, kept] = bigF(qMid, submissions);
      }

      return kept;
    };

    const kept = keepHelper(submissions, keepHighest, stableSubmissionSort(sortDescending, getAssignmentIdFn));
    return keepHelper(kept, keepLowest, stableSubmissionSort(sortAscending, getAssignmentIdFn));
  };

  const dropUnpointed = function (submissions, keepHighest, keepLowest) {
    const sortAscending = function (a, b) { return a.score - b.score };
    const getAssignmentIdFn = function ({ submission }) { return submission.assignment_id };
    const sortedSubmissions = submissions.sort(stableSubmissionSort(sortAscending, getAssignmentIdFn));
    return _.chain(sortedSubmissions).last(keepHighest).first(keepLowest).value();
  };

  // I am not going to pretend that this code is understandable.
  //
  // The naive approach to dropping the lowest grades (calculate the
  // grades for each combination of assignments and choose the set which
  // results in the best overall score) is obviously too slow.
  //
  // This approach is based on the algorithm described in "Dropping Lowest
  // Grades" by Daniel Kane and Jonathan Kane. Please see that paper for
  // a full explanation of the math.
  // (http://cseweb.ucsd.edu/~dakane/droplowest.pdf)
  const dropAssignments = function (submissions, rules) {
    rules = rules || {};
    let dropLowest = rules.drop_lowest || 0;
    let dropHighest = rules.drop_highest || 0;
    const neverDropIds = rules.never_drop || [];

    if (!(dropLowest || dropHighest)) {
      return submissions;
    }

    let cannot_drop = [];
    if (neverDropIds.length > 0) {
      [cannot_drop, submissions] = partition(submissions, function (submission) {
        return _.contains(neverDropIds, submission.submission.assignment_id);
      });
    }

    if (submissions.length === 0) {
      return cannot_drop;
    }

    dropLowest = Math.min(dropLowest, submissions.length - 1);
    dropHighest = (dropLowest + dropHighest) >= submissions.length ? 0 : dropHighest;

    const keepHighest = submissions.length - dropLowest;
    const keepLowest = keepHighest - dropHighest;
    const hasPointed = _.some(submissions, function (submission) { return submission.total > 0 });

    let kept;
    if (hasPointed) {
      kept = dropPointed(submissions, cannot_drop, keepHighest, keepLowest);
    } else {
      kept = dropUnpointed(submissions, keepHighest, keepLowest);
    }

    kept = [ ...kept, ...cannot_drop];

    _.difference(submissions, kept).forEach(function (submission) {
      submission.drop = true;
    });

    return kept;
  };

  const calculateGroupSum = function (group, submissions, includeUngraded) {
    // remove assignments without visibility from gradeableAssignments
    const hiddenAssignments = _.chain(submissions).filter('hidden').indexBy('assignment_id').value();
    const gradeableAssignments = _.reject(group.assignments, function (assignment) {
      return assignment.omit_from_final_grade ||
        hiddenAssignments[assignment.id] ||
        _.isEqual(assignment.submission_types, ['not_graded']);
    });
    const assignments = _.indexBy(gradeableAssignments, 'id');

    // filter out submissions from other assignment groups
    submissions = _.filter(submissions, function (submission) {
      return assignments[submission.assignment_id];
    });

    // fill in any missing submissions
    if (includeUngraded) {
      const submissionAssignmentIds = _.map(submissions, function ({ assignment_id }) {
        return assignment_id.toString();
      });
      const missingSubmissions = _.difference(_.keys(assignments), submissionAssignmentIds);
      const submissionStubs = _.map(missingSubmissions, (assignment_id) => {
        return { assignment_id, score: null };
      });
      submissions = [ ...submissions, ...submissionStubs ];
    }

    // filter out excused assignments
    submissions = _.reject(submissions, 'excused');

    const submissionsByAssignment = _.indexBy(submissions, 'assignment_id');

    const submissionData = _.map(submissions, function (submission) {
      return {
        total: parseScore(assignments[submission.assignment_id].points_possible),
        score: parseScore(submission.score),
        submitted: submission.score != null && submission.score !== '',
        pending_review: submission.workflow_state === 'pending_review',
        submission
      };
    });

    let relevantSubmissionData = submissionData;
    if (!includeUngraded) {
      relevantSubmissionData = _.filter(submissionData, function (submission) {
        return submission.submitted && !submission.pending_review;
      });
    }

    const kept = dropAssignments(relevantSubmissionData, group.rules);
    const score = sum(_.chain(kept).map('score').map(parseScore).value());
    const possible = sumBy(kept, 'total');

    return {
      possible,
      score,
      weight: group.group_weight,
      submission_count: _.filter(submissionData, 'submitted').length,
      submissions: _.map(submissionData, function (submission) {
        return {
          drop: submission.drop,
          percent: parseScore(submission.score / submission.total),
          possible: submission.total,
          score: parseScore(submission.score),
          submission: submission.submission,
          submitted: submission.submitted
        };
      })
    };
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
  // An assignment group requires the following properties:
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
  const calculate = function (submissions, assignmentGroup, weightingScheme) {
    return {
      group: assignmentGroup,
      current: calculateGroupSum(assignmentGroup, submissions, false),
      final: calculateGroupSum(assignmentGroup, submissions, true)
    };
  };

  return {
    calculate
  };
});
