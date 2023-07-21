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

import {render} from '@testing-library/react'
import React from 'react'
import Report from '../report'
import {camelize} from '@canvas/quiz-legacy-client-apps/util/convert_case'

describe('canvas_quizzes/statistics/views/summary/report', () => {
  it('does things on rerender', () => {
    const {rerender} = render(<Report />)
    const fixture = camelize({
      id: '14',
      report_type: 'student_analysis',
      readable_type: 'Student Analysis',
      includes_all_versions: false,
      generatable: true,
      anonymous: false,
      url: 'http://localhost:3000/api/v1/courses/1/quizzes/1/reports/14',
      created_at: '2014-04-29T08:57:36Z',
      updated_at: '2014-04-29T09:08:55Z',
      links: {
        quiz: 'http://localhost:3000/api/v1/courses/1/quizzes/1',
      },
      file: camelize({
        id: 154,
        'content-type': 'text/csv',
        display_name: 'CNVS-4338 Quiz Student Analysis Report.csv',
        filename: 'quiz_student_analysis_report.csv',
        url: 'http://localhost:3000/files/154/download?download_frd=1&verifier=XDl5emZ8E5KHjrmkcMUArhyLCHEJsi6DxNoLqsd4',
        size: 1093,
        created_at: '2014-04-29T09:08:55Z',
        updated_at: '2014-04-29T09:08:55Z',
        unlock_at: null,
        locked: false,
        hidden: false,
        lock_at: null,
        hidden_for_user: false,
        thumbnail_url: null,
        locked_for_user: false,
      }),
      progress: camelize({
        completion: 100,
        context_id: 13,
        context_type: 'Quizzes::QuizStatistics',
        created_at: '2014-04-02T06:41:47Z',
        id: 143,
        message: null,
        tag: 'Quizzes::QuizStatistics',
        updated_at: '2014-04-02T06:41:47Z',
        user_id: null,
        workflow_state: 'completed',
        url: 'http://localhost:3000/api/v1/progress/143',
      }),
    })

    rerender(<Report isGenerating={true} {...fixture} />)

    rerender(<Report isGenerated={true} {...fixture} />)
  })
})
