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
], (_) => {
  function sum (collection) {
    return _.reduce(collection, (total, value) => total + value, 0);
  }

  function sumBy (collection, attr) {
    const values = _.map(collection, attr);
    return sum(values);
  }

  function partition (collection, partitionFn) {
    const grouped = _.groupBy(collection, partitionFn);
    return [grouped.true || [], grouped.false || []];
  }

  function parseScore (score) {
    const result = parseFloat(score);
    return (result && isFinite(result)) ? result : 0;
  }

  function sortPairsDescending ([scoreA, submissionA], [scoreB, submissionB]) {
    const scoreDiff = scoreB - scoreA;
    if (scoreDiff !== 0) {
      return scoreDiff;
    }
    // To ensure stable sorting, use the assignment id as a secondary sort.
    return submissionA.assignment_id - submissionB.assignment_id;
  }

  function sortPairsAscending ([scoreA, submissionA], [scoreB, submissionB]) {
    const scoreDiff = scoreA - scoreB;
    if (scoreDiff !== 0) {
      return scoreDiff;
    }
    // To ensure stable sorting, use the assignment id as a secondary sort.
    return submissionA.assignment_id - submissionB.assignment_id;
  }

  function sortSubmissionsAscending (submissionA, submissionB) {
    const scoreDiff = submissionA.score - submissionB.score;
    if (scoreDiff !== 0) {
      return scoreDiff;
    }
    // To ensure stable sorting, use the assignment id as a secondary sort.
    return submissionA.assignment_id - submissionB.assignment_id;
  }

  function getSubmissionGrade ({ score, total }) {
    return score / total;
  }

  function estimateQHigh (pointed, unpointed, grades) {
    if (unpointed.length > 0) {
      const pointsPossible = sumBy(pointed, 'total');
      const bestPointedScore = Math.max(pointsPossible, sumBy(pointed, 'score'));
      const unpointedScore = sumBy(unpointed, 'score');
      return (bestPointedScore + unpointedScore) / pointsPossible;
    }

    return grades[grades.length - 1];
  }

  function buildBigF (keepCount, cannotDrop, sortFn) {
    return function bigF (q, submissions) {
      const ratedScores = _.map(submissions, submission => (
        [submission.score - (q * submission.total), submission]
      ));
      const rankedScores = ratedScores.sort(sortFn);
      const keptScores = rankedScores.slice(0, keepCount);
      const qKept = sumBy(keptScores, ([score]) => score);
      const keptSubmissions = _.map(keptScores, ([_score, submission]) => submission);
      const qCannotDrop = sumBy(cannotDrop, submission => submission.score - (q * submission.total));
      return [qKept + qCannotDrop, keptSubmissions];
    }
  }

  function dropPointed (droppableSubmissionData, cannotDrop, keepHighest, keepLowest) {
    const totals = _.map(droppableSubmissionData, 'total');
    const maxTotal = Math.max(...totals);

    function keepHelper (submissions, initialKeepCount, bigFSort) {
      const keepCount = Math.max(1, initialKeepCount);

      if (submissions.length <= keepCount) {
        return submissions;
      }

      const allSubmissionData = [...submissions, ...cannotDrop];
      const [unpointed, pointed] = partition(allSubmissionData, submissionDatum => submissionDatum.total === 0);

      const grades = _.map(pointed, getSubmissionGrade).sort();
      let qHigh = estimateQHigh(pointed, unpointed, grades);
      let qLow = grades[0];
      let qMid = (qLow + qHigh) / 2;

      const bigF = buildBigF(keepCount, cannotDrop, bigFSort);

      let [x, submissionsToKeep] = bigF(qMid, submissions);
      const threshold = 1 / (2 * keepCount * (maxTotal ** 2));
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

        [x, submissionsToKeep] = bigF(qMid, submissions);
      }

      return submissionsToKeep;
    }

    const submissionsWithLowestDropped = keepHelper(
      droppableSubmissionData, keepHighest, sortPairsDescending
    );
    return keepHelper(
      submissionsWithLowestDropped, keepLowest, sortPairsAscending
    );
  }

  function dropUnpointed (submissions, keepHighest, keepLowest) {
    const sortedSubmissions = submissions.sort(sortSubmissionsAscending);
    return _.chain(sortedSubmissions).last(keepHighest).first(keepLowest).value();
  }

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
  function dropAssignments (allSubmissionData, rules = {}) {
    let dropLowest = rules.drop_lowest || 0;
    let dropHighest = rules.drop_highest || 0;
    const neverDropIds = rules.never_drop || [];

    if (!(dropLowest || dropHighest)) {
      return allSubmissionData;
    }

    let cannotDrop = [];
    let droppableSubmissionData = allSubmissionData;
    if (neverDropIds.length > 0) {
      [cannotDrop, droppableSubmissionData] = partition(allSubmissionData, submission => (
        _.contains(neverDropIds, submission.submission.assignment_id)
      ));
    }

    if (droppableSubmissionData.length === 0) {
      return cannotDrop;
    }

    dropLowest = Math.min(dropLowest, droppableSubmissionData.length - 1);
    dropHighest = (dropLowest + dropHighest) >= droppableSubmissionData.length ? 0 : dropHighest;

    const keepHighest = droppableSubmissionData.length - dropLowest;
    const keepLowest = keepHighest - dropHighest;
    const hasPointed = _.some(droppableSubmissionData, submission => submission.total > 0);

    let submissionsToKeep;
    if (hasPointed) {
      submissionsToKeep = dropPointed(droppableSubmissionData, cannotDrop, keepHighest, keepLowest);
    } else {
      submissionsToKeep = dropUnpointed(droppableSubmissionData, keepHighest, keepLowest);
    }

    submissionsToKeep = [...submissionsToKeep, ...cannotDrop];

    _.difference(droppableSubmissionData, submissionsToKeep).forEach((submission) => { submission.drop = true });

    return submissionsToKeep;
  }

  function calculateGroupGrade (group, allSubmissions, includeUngraded) {
    // Remove assignments without visibility from gradeableAssignments.
    const hiddenAssignmentsById = _.chain(allSubmissions).filter('hidden').indexBy('assignment_id').value();
    const gradeableAssignments = _.reject(group.assignments, assignment => (
      assignment.omit_from_final_grade ||
        hiddenAssignmentsById[assignment.id] ||
        _.isEqual(assignment.submission_types, ['not_graded'])
    ));
    const assignments = _.indexBy(gradeableAssignments, 'id');

    // Remove submissions from other assignment groups.
    let submissions = _.filter(allSubmissions, submission => assignments[submission.assignment_id]);

    // To calculate grades for assignments to which the student has not yet
    // submitted, create a submission stub with a score of `null`.
    if (includeUngraded) {
      const submissionAssignmentIds = _.map(submissions, ({ assignment_id }) => assignment_id.toString());
      const missingAssignmentIds = _.difference(_.keys(assignments), submissionAssignmentIds);
      const submissionStubs = _.map(missingAssignmentIds, assignmentId => (
        { assignment_id: assignmentId, score: null }
      ));
      submissions = [...submissions, ...submissionStubs];
    }

    // Remove excused submissions.
    submissions = _.reject(submissions, 'excused');

    const submissionData = _.map(submissions, submission => (
      {
        total: parseScore(assignments[submission.assignment_id].points_possible),
        score: parseScore(submission.score),
        submitted: submission.score != null && submission.score !== '',
        pending_review: submission.workflow_state === 'pending_review',
        submission
      }
    ));

    let relevantSubmissionData = submissionData;
    if (!includeUngraded) {
      relevantSubmissionData = _.filter(submissionData, submission => (
        submission.submitted && !submission.pending_review
      ));
    }

    const submissionsToKeep = dropAssignments(relevantSubmissionData, group.rules);
    const score = sum(_.chain(submissionsToKeep).map('score').map(parseScore).value());
    const possible = sumBy(submissionsToKeep, 'total');

    return {
      score,
      possible,
      submission_count: _.filter(submissionData, 'submitted').length,
      submissions: _.map(submissionData, submissionDatum => (
        {
          drop: submissionDatum.drop,
          percent: parseScore(submissionDatum.score / submissionDatum.total),
          score: parseScore(submissionDatum.score),
          possible: submissionDatum.total,
          submission: submissionDatum.submission,
          submitted: submissionDatum.submitted
        }
      ))
    };
  }

  // Each submission requires the following properties:
  // * score: number
  // * points_possible: non-negative integer
  // * assignment_id: <Canvas id>
  // * assignment_group_id: <Canvas id>
  // * excused: boolean
  //
  // Ungraded submissions will have a score of `null`.
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
  // * id: <Canvas id>
  // * points_possible: non-negative number
  // * submission_types: [array of strings]
  //
  // An AssignmentGroup Grade has the following shape:
  // {
  //   score: number|null
  //   possible: number|null
  //   submission_count: non-negative number
  //   submissions: [array of Submissions]
  // }
  //
  // Return value is an AssignmentGroup Grade Set.
  // An AssignmentGroup Grade Set has the following shape:
  // {
  //   assignmentGroupId: <Canvas id>
  //   assignmentGroupWeight: number
  //   current: <AssignmentGroup Grade *see above>
  //   final: <AssignmentGroup Grade *see above>
  //   scoreUnit: 'points'
  // }
  function calculate (allSubmissions, assignmentGroup) {
    const submissions = _.uniq(allSubmissions, 'assignment_id');
    return {
      assignmentGroupId: assignmentGroup.id,
      assignmentGroupWeight: assignmentGroup.group_weight,
      current: calculateGroupGrade(assignmentGroup, submissions, false),
      final: calculateGroupGrade(assignmentGroup, submissions, true),
      scoreUnit: 'points'
    };
  }

  return {
    calculate
  };
});
