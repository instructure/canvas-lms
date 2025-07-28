/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {z} from 'zod'
import getCookie from '@instructure/get-cookie'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'
import type {Submission} from 'api'

export const ZUpdateSubmissionGradeParams = z.object({
  assignmentId: z.string(),
  userId: z.string(),
  courseId: z.string(),
  gradedAnonymously: z.boolean(),
  grade: z.string().nullable(),
  excuse: z.boolean(),
  checkpointTag: z.string().nullable(),
})

type UpdateSubmissionGradeParams = z.infer<typeof ZUpdateSubmissionGradeParams>

export async function updateSubmissionGrade({
  assignmentId,
  userId,
  courseId,
  gradedAnonymously,
  grade,
  excuse,
  checkpointTag,
}: UpdateSubmissionGradeParams): Promise<any> {
  if (checkpointTag) {
    return updateCheckpointedSubmissionGrade({
      checkpointTag,
      courseId,
      assignmentId,
      studentId: userId,
      grade,
    })
  }

  return updateNonCheckpointedSubmissionGrade({
    assignmentId,
    userId,
    courseId,
    gradedAnonymously,
    grade,
    excuse,
  })
}

/** *********************************************************** */
/* Non-Checkpoint grading code below */
/** *********************************************************** */

function transform(result: any) {
  if (result.errors?.length > 0) {
    throw new Error(result.errors[0].message)
  }

  const {submission} = result[0]
  return {
    submission: {
      _id: submission.id,
      grade: submission.grade,
      score: submission.score,
      gradingStatus: submission.grading_status,
    },
  }
}

export const ZUpdateNonCheckpointSubmissionGradeParams = z.object({
  assignmentId: z.string(),
  userId: z.string(),
  courseId: z.string(),
  gradedAnonymously: z.boolean(),
  grade: z.string().nullable(),
  excuse: z.boolean(),
})

type NonCheckpointSubmissionGradeParams = z.infer<typeof ZUpdateNonCheckpointSubmissionGradeParams>

async function updateNonCheckpointedSubmissionGrade({
  assignmentId,
  userId,
  courseId,
  gradedAnonymously,
  grade,
  excuse,
}: NonCheckpointSubmissionGradeParams): Promise<any> {
  const body: Record<any, any> = {
    originator: 'speed_grader',
    submission: {
      assignment_id: assignmentId,
      user_id: userId,
      graded_anonymously: gradedAnonymously,
    },
  }
  if (excuse) {
    body.submission.excuse = excuse
  } else {
    body.submission.grade = grade
  }
  const {data} = await executeApiRequest<Submission>({
    method: 'POST',
    path: `/courses/${courseId}/gradebook/update_submission`,
    body,
  })
  return transform(data)
}

/** *********************************************************** */
/* Checkpoint grading code below */
/** *********************************************************** */

const ZUpdateCheckpointSubmissionGradeParams = z.object({
  checkpointTag: z.string(),
  courseId: z.string(),
  assignmentId: z.string(),
  studentId: z.string(),
  grade: z.string().nullable(),
})

type CheckpointSubmissionGradeParams = z.infer<typeof ZUpdateCheckpointSubmissionGradeParams>

const updateCheckpointedSubmissionGrade = async ({
  checkpointTag,
  courseId,
  assignmentId,
  studentId,
  grade,
}: CheckpointSubmissionGradeParams): Promise<any> => {
  const {data} = await executeApiRequest({
    method: 'PUT',
    path: `/api/v1/courses/${courseId}/assignments/${assignmentId}/submissions/${studentId}`,
    body: {
      course_id: courseId,
      sub_assignment_tag: checkpointTag,
      submission: {
        assignment_id: assignmentId,
        user_id: studentId,
        posted_grade: grade,
      },
    },
  })

  return data
}
