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
import {executeQuery} from '@canvas/graphql'
import {ZSubmissionType} from '../assignments/getAssignments'
import {buildGraphQLQuery, numberToLetters} from '../buildGraphQLQuery'

const ZLatePolicyStatus = z.enum(['late', 'missing', 'extended', 'none'])

const ZSubmissionState = z.enum([
  'submitted',
  'unsubmitted',
  'pending_review',
  'graded',
  'ungraded',
  'deleted',
])

const ZSubAssignmentSubmission = z
  .object({
    customGradeStatusId: z.string().nullable(),
    enteredGrade: z.string().nullable(),
    enteredScore: z.number().nullable(),
    excused: z.boolean().nullable(),
    grade: z.string().nullable(),
    gradeMatchesCurrentSubmission: z.boolean().nullable(),
    late: z.boolean(),
    latePolicyStatus: ZLatePolicyStatus.nullable(),
    missing: z.boolean(),
    publishedGrade: z.string().nullable(),
    publishedScore: z.number().nullable(),
    score: z.number().nullable(),
    secondsLate: z.number().nullable(),
    subAssignmentTag: z.string().nullable(),
  })
  .strict()

// Only this 2 fields are needed for SubmissionHelper.ts
const ZTurnitinData = z
  .object({
    assetString: z.string(),
    score: z.number().nullable(),
    status: z.string().nullable(),
    state: z.string().nullable(),
  })
  .strict()

const ZVericiteData = z
  .object({
    assetString: z.string(),
    score: z.number().nullable(),
    status: z.string().nullable(),
    state: z.string().nullable(),
  })
  .strict()

const ZSubmission = z
  .object({
    _id: z.string(),
    attachments: z.array(z.object({_id: z.string()}).strict()),
    anonymousId: z.string().nullable(),
    assignment: z
      .object({
        _id: z.string(),
        hasSubAssignments: z.boolean(),
      })
      .strict(),
    attempt: z.number(),
    cachedDueDate: z.string().nullable(),
    customGradeStatusId: z.string().nullable(),
    deductedPoints: z.number().nullable(),
    enteredGrade: z.string().nullable(),
    enteredScore: z.number().nullable(),
    excused: z.boolean().nullable(),
    grade: z.string().nullable(),
    gradeMatchesCurrentSubmission: z.boolean().nullable(),
    gradingPeriodId: z.string().nullable(),
    hasOriginalityReport: z.boolean(),
    hasPostableComments: z.boolean(), // was not fetched, but seems to be needed
    late: z.boolean(),
    latePolicyStatus: ZLatePolicyStatus.nullable(),
    missing: z.boolean(),
    postedAt: z.string().nullable(),
    proxySubmitter: z.string().nullable(),
    redoRequest: z.boolean().nullable(),
    score: z.number().nullable(),
    secondsLate: z.number().nullable(),
    state: ZSubmissionState,
    sticker: z.string().nullable(),
    subAssignmentSubmissions: z.array(ZSubAssignmentSubmission).nullable(),
    submissionType: ZSubmissionType.nullable(),
    submittedAt: z.string().nullable(),
    turnitinData: z.array(ZTurnitinData).nullable(),
    vericiteData: z.array(ZVericiteData).nullable(),
    updatedAt: z.string().nullable(),
    userId: z.string().nullable(),
  })
  .strict()

export type Submission = z.infer<typeof ZSubmission>

const ZSubmissionConnection = z
  .object({pageInfo: ZNextPageInfo, nodes: z.array(ZSubmission)})
  .strict()

const ZGetSubmissionsResult = z
  .object({course: z.object({}).catchall(ZSubmissionConnection)})
  .strict()

export type GetSubmissionsResult = z.infer<typeof ZGetSubmissionsResult>

const nodeFields = [
  '_id',
  'anonymousId',
  'attempt',
  'cachedDueDate',
  'customGradeStatusId',
  'deductedPoints',
  'enteredGrade',
  'enteredScore',
  'excused',
  'grade',
  'gradeMatchesCurrentSubmission',
  'gradingPeriodId',
  'hasOriginalityReport',
  'hasPostableComments',
  'late',
  'latePolicyStatus',
  'missing',
  'postedAt',
  'proxySubmitter',
  'redoRequest',
  'score',
  'secondsLate',
  'state',
  'sticker',
  'submissionType',
  'submittedAt',
  'updatedAt',
  'userId',
  {name: 'assignment', fields: ['_id', 'hasSubAssignments']},
  {
    name: 'attachments',
    fields: ['_id'],
  },
  {
    name: 'turnitinData',
    fields: ['assetString', 'score', 'state', 'status'],
  },
  {
    name: 'vericiteData',
    fields: ['assetString', 'score', 'state', 'status'],
  },
  {
    name: 'subAssignmentSubmissions',
    fields: [
      'customGradeStatusId',
      'enteredGrade',
      'enteredScore',
      'excused',
      'grade',
      'gradeMatchesCurrentSubmission',
      'late',
      'latePolicyStatus',
      'missing',
      'publishedGrade',
      'publishedScore',
      'score',
      'secondsLate',
      'subAssignmentTag',
    ],
  },
]

type SubmissionsConnectionNodeParams = {
  alias: string
  after: string
  studentIds: string[]
}

const submissionsConnectionNode = ({
  alias,
  after,
  studentIds,
}: SubmissionsConnectionNodeParams) => ({
  alias,
  name: 'submissionsConnection',
  args: {
    after,
    first: 100,
    studentIds,
    // States is an array of enums.
    // buildGraphQLQuery would wrap each enum in quotes, causing the query to fail.
    // So we pass it as a variable.
    filter: {states: '$states'},
  },
  fields: [
    {name: 'pageInfo', fields: ['hasNextPage', 'endCursor']},
    {name: 'nodes', fields: nodeFields},
  ],
})

export type GetSubmissionsParams = {
  courseId: string
  userIds: string[]
  after?: Record<string, string | null>
}

export const getSubmissions = async ({courseId, userIds, after}: GetSubmissionsParams) => {
  const courseNode = {
    name: 'course',
    args: {id: '$courseId'},
    fields: userIds.map(id => {
      const alias = numberToLetters(parseInt(id, 10))
      const cursor = after?.[alias]
      if (cursor === null) return ''
      return submissionsConnectionNode({alias, after: cursor ?? '', studentIds: [id]})
    }),
  }
  const query = buildGraphQLQuery(
    [courseNode],
    'query',
    'getSubmissions',
    '$courseId: ID!, $states: [SubmissionState!]',
  )
  const data = await executeQuery<GetSubmissionsResult>(query, {
    courseId,
    states: ['graded', 'pending_review', 'submitted', 'ungraded', 'unsubmitted'],
  })

  const validation = ZGetSubmissionsResult.safeParse(data)
  if (!validation.success) {
    console.error('Validation failed:', validation.error.format())
  }
  return data
}
