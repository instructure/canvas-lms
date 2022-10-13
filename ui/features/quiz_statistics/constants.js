/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

export default {
  DISCRIMINATION_INDEX_THRESHOLD: 0.25,

  // a whitelist of the attributes we need from the payload
  QUIZ_STATISTICS_ATTRS: [
    'id',
    'points_possible',
    'speed_grader_url',
    'anonymous_survey',
    'quiz_submissions_zip_url',
  ],

  SUBMISSION_STATISTICS_ATTRS: [
    'score_average',
    'score_high',
    'score_low',
    'score_stdev',
    'scores',
    'duration_average',
    'unique_count',
  ],

  QUESTION_STATISTICS_ATTRS: [
    'id',
    'question_type',
    'question_text',
    'responses',
    'answers',
    'position',
    'user_ids',
    'user_names',

    // multiple-choice & true/false
    'answered_student_count',
    'top_student_count',
    'middle_student_count',
    'bottom_student_count',
    'correct_top_student_count',
    'correct_middle_student_count',
    'correct_bottom_student_count',
    'point_biserials',

    // multiple-answers
    'correct',
    'partially_correct',

    // FIMB, Multiple-Dropdowns, Matching
    'answer_sets',

    // Essay
    'full_credit',
    'point_distribution',
  ],

  POINT_BISERIAL_ATTRS: ['answer_id', 'correct', 'distractor', 'point_biserial'],

  QUIZ_REPORT_ATTRS: [
    'id',
    'report_type',
    'readable_type',
    'generatable',
    'includes_all_versions',
    'url',
  ],

  PROGRESS_ATTRS: [
    'id',
    'completion',
    'url', // for polling
    'workflow_state',
  ],

  ATTACHMENT_ATTRS: ['created_at', 'url'],

  PROGRESS_QUEUED: 'queued',
  PROGRESS_ACTIVE: 'running',
  PROGRESS_COMPLETE: 'completed',
  PROGRESS_FAILED: 'failed',
}
