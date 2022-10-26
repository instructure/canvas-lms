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

import * as Turnitin from '@canvas/grading/Turnitin'

let submissionWithReport = null

QUnit.module('Turnitin', {
  setup() {
    return (submissionWithReport = {
      id: '7',
      body: null,
      url: null,
      grade: null,
      score: null,
      submitted_at: '2016-11-29T22:29:44Z',
      assignment_id: '52',
      user_id: '2',
      submission_type: 'online_upload',
      workflow_state: 'submitted',
      grade_matches_current_submission: true,
      graded_at: null,
      grader_id: null,
      attempt: 1,
      excused: null,
      late: false,
      preview_url:
        'http://canvas.docker/courses/2/assignments/52/submissions/2?preview=1&version=1',
      turnitin_data: {
        attachment_103: {
          similarity_score: 0.8,
          state: 'acceptable',
          report_url: 'http://www.instructure.com',
          status: 'pending',
        },
      },
      has_originality_report: true,
      attachments: [
        {
          id: '103',
          folder_id: '9',
          display_name: 'Untitled-2.rtf',
          filename: '1480456390_119__Untitled.rtf',
          'content-type': 'text/rtf',
          url: 'http://canvas.docker/files/103/download?download_frd=1&verifier=kRS6CMQUNlpF1sobUbALPa0AxE2J70vxPAX7GQqo',
          size: null,
          created_at: '2016-11-29T22:29:43Z',
          updated_at: '2016-11-29T22:29:43Z',
          unlock_at: null,
          locked: false,
          hidden: false,
          lock_at: null,
          hidden_for_user: false,
          thumbnail_url: null,
          modified_at: '2016-11-29T22:29:43Z',
          mime_class: 'doc',
          media_entry_id: null,
          locked_for_user: false,
          preview_url: null,
        },
      ],
      turnitin: {},
    })
  },
})

test('uses the score when the score is 0', () => {
  submissionWithReport.turnitin_data.attachment_103.similarity_score = 0

  const tii_data = Turnitin.extractDataForTurnitin(
    submissionWithReport,
    'attachment_103',
    '/courses/2'
  )

  equal(tii_data.score, '0%')
})

test('correctly finds text entry plagiarism data', () => {
  submissionWithReport.turnitin_data = {
    'submission_7_2016-11-29T22:29:44Z': {
      similarity_score: 0.8,
      state: 'acceptable',
      report_url: 'http://www.instructure.com',
      status: 'pending',
    },
  }
  submissionWithReport.submission_type = 'online_text_entry'

  const plagiarismData = Turnitin.extractDataTurnitin(submissionWithReport)
  equal(plagiarismData.items.length, 1)
})

test('uses originality_report type in url if submission has an OriginalityReport', () => {
  const tii_data = Turnitin.extractDataForTurnitin(
    submissionWithReport,
    'attachment_103',
    '/courses/2'
  )
  equal(
    tii_data.reportUrl,
    '/courses/2/assignments/52/submissions/2/originality_report/attachment_103'
  )
})

test('uses turnitin or vericite type if no OriginalityReport is present for the submission', () => {
  submissionWithReport.has_originality_report = null
  const tii_data = Turnitin.extractDataForTurnitin(
    submissionWithReport,
    'attachment_103',
    '/courses/2'
  )
  equal(tii_data.reportUrl, '/courses/2/assignments/52/submissions/2/turnitin/attachment_103')
})

test('it uses vericite type if vericite data is present', () => {
  submissionWithReport.vericite_data = submissionWithReport.turnitin_data
  submissionWithReport.vericite_data.provider = 'vericite'
  delete submissionWithReport.turnitin_data
  delete submissionWithReport.has_originality_report
  const tii_data = Turnitin.extractDataForTurnitin(
    submissionWithReport,
    'attachment_103',
    '/courses/2'
  )
  equal(tii_data.reportUrl, '/courses/2/assignments/52/submissions/2/vericite/attachment_103')
})

test('returns undefined for score if originality_score is blank', () => {
  submissionWithReport.turnitin_data.attachment_103.similarity_score = null
  const tii_data = Turnitin.extractDataForTurnitin(
    submissionWithReport,
    'attachment_103',
    '/courses/2'
  )
  equal(tii_data.score, undefined)
})

test('returns the score percentage if originality_score is present', () => {
  const tii_data = Turnitin.extractDataForTurnitin(
    submissionWithReport,
    'attachment_103',
    '/courses/2'
  )
  equal(tii_data.score, '0.8%')
})
