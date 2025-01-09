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
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {Submission} from '../types/stickers.d'

function updateSticker(
  submission: Submission,
  sticker: string | null,
  onFailure: (err: Error) => void,
) {
  const method = 'PUT'
  const basePath = `/api/v1/courses/${submission.courseId}/assignments/${submission.assignmentId}`
  const path = submission.userId
    ? `${basePath}/submissions/${submission.userId}`
    : `${basePath}/anonymous_submissions/${submission.anonymousId}`

  const body = {
    submission: {
      assignment_id: submission.assignmentId,
      sticker,
    },
  }

  doFetchApi({body, method, path}).catch(onFailure)
}

export default {
  updateSticker,
}
