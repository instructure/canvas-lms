/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {ZNextPageInfo} from '../PaginatedResult'
import {GET_ASSIGNMENTS_QUERY} from './getAssignmentsQuery'
import {executeQuery} from '@canvas/graphql'

const ZCheckpoint = z
  .object({
    dueAt: z.string().nullable(),
    lockAt: z.string().nullable(),
    name: z.string().nullable(),
    onlyVisibleToOverrides: z.boolean(),
    pointsPossible: z.number(),
    tag: z.string(),
    unlockAt: z.string().nullable(),
  })
  .strict()

const ZGradingType = z.enum([
  'gpa_scale',
  'letter_grade',
  'not_graded',
  'pass_fail',
  'percent',
  'points',
])

export const ZSubmissionType = z.enum([
  'attendance',
  'basic_lti_launch',
  'discussion_topic',
  'external_tool',
  'media_recording',
  'none',
  'not_graded',
  'on_paper',
  'online_quiz',
  'online_text_entry',
  'online_upload',
  'online_url',
  'student_annotation',
  'wiki_page',
])

const ZAssignmentState = z.enum([
  'deleted',
  'duplicating',
  'fail_to_import',
  'failed_to_clone_outcome_alignment',
  'failed_to_duplicate',
  'failed_to_migrate',
  'importing',
  'migrating',
  'outcome_alignment_cloning',
  'published',
  'unpublished',
])

const ZAssignment = z
  .object({
    _id: z.string(),
    allowedAttempts: z.number().nullable(),
    allowedExtensions: z.array(z.string()).nullable(),
    anonymizeStudents: z.boolean().nullable(),
    anonymousGrading: z.boolean().nullable(),
    anonymousInstructorAnnotations: z.boolean().nullable(),
    assignmentGroupId: z.string().nullable(),
    assignmentVisibility: z.array(z.string()).nullable(),
    checkpoints: z.array(ZCheckpoint).nullable(),
    courseId: z.string().nullable(),
    createdAt: z.string().nullable(),
    dueAt: z.string().nullable(),
    dueDateRequired: z.boolean().nullable(),
    gradedSubmissionsExist: z.boolean().nullable(),
    gradeGroupStudentsIndividually: z.boolean().nullable(),
    gradesPublished: z.boolean().nullable(),
    gradingStandardId: z.string().nullable(),
    gradingType: ZGradingType,
    groupCategoryId: z.number().nullable(),
    hasRubric: z.boolean(),
    hasSubAssignments: z.boolean(),
    hasSubmittedSubmissions: z.boolean().nullable(),
    htmlUrl: z.string().nullable(),
    importantDates: z.boolean().nullable(),
    lockAt: z.string().nullable(),
    moderatedGradingEnabled: z.boolean().nullable(),
    moduleItems: z
      .array(
        z.object({position: z.number(), module: z.object({_id: z.string()}).strict()}).strict(),
      )
      .nullable(),
    muted: z.boolean().nullable(),
    name: z.string().nullable(),
    omitFromFinalGrade: z.boolean().nullable(),
    onlyVisibleToOverrides: z.boolean(),
    peerReviews: z
      .object({
        anonymousReviews: z.boolean().nullable(),
        automaticReviews: z.boolean().nullable(),
        enabled: z.boolean().nullable(),
        intraReviews: z.boolean().nullable(),
      })
      .strict()
      .nullable(),
    pointsPossible: z.number().nullable(),
    position: z.number().nullable(),
    postManually: z.boolean().nullable(),
    postToSis: z.boolean().nullable(),
    published: z.boolean().nullable(),
    state: ZAssignmentState,
    submissionTypes: ZSubmissionType.array().nullable(),
    unlockAt: z.string().nullable(),
    updatedAt: z.string().nullable(),
    visibleToEveryone: z.boolean(),
  })
  .strict()
export type Assignment = z.infer<typeof ZAssignment>

const ZGetAssignmentsResult = z
  .object({
    assignmentGroup: z.object({
      assignmentsConnection: z.object({
        pageInfo: ZNextPageInfo,
        nodes: z.array(ZAssignment),
      }),
    }),
  })
  .strict()

export type GetAssignmentsResult = z.infer<typeof ZGetAssignmentsResult>

export type GetAssignmentsParams = {
  assignmentGroupId: string
  gradingPeriodId: string | null
  after?: string
}
export const getAssignments = async (params: GetAssignmentsParams) => {
  const data = await executeQuery<GetAssignmentsResult>(GET_ASSIGNMENTS_QUERY, params)
  const validation = ZGetAssignmentsResult.safeParse(data)
  if (!validation.success) {
    console.error('Validation failed:', validation.error.format())
  }
  return data
}
