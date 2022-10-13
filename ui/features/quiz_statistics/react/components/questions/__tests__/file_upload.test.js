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
import FileUpload from '../file_upload'
import {camelize} from '@canvas/quiz-legacy-client-apps/util/convert_case'

describe('canvas_quizzes/statistics/views/questions/file_upload', () => {
  it('renders', () => {
    const fixture = camelize({
      id: '54',
      question_type: 'file_upload_question',
      question_text: "<p>File Upload: what's that you look like?</p>",
      position: 13,
      responses: 1,
      graded: 0,
      full_credit: 0,
      point_distribution: [
        {
          score: 0,
          count: 152,
        },
      ],
    })

    render(<FileUpload {...fixture} />)
  })
})
