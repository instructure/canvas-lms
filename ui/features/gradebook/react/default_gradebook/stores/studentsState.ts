/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {difference, chunk} from 'lodash'
import type {SetState, GetState} from 'zustand'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {GradebookStore} from './index'
import {getContentForStudentIdChunk} from './studentsState.utils'
import {asJson, consumePrefetchedXHR} from '@canvas/util/xhr'
import type {
  AssignmentUserSubmissionMap,
  Student,
  StudentMap,
  Submission,
  UserSubmissionGroup,
} from '../../../../../api.d'

const I18n = useI18nScope('gradebook')

export type StudentsState = {
  assignmentUserSubmissionMap: AssignmentUserSubmissionMap
  fetchStudentIds: () => Promise<string[]>
  isStudentDataLoaded: boolean
  isStudentIdsLoading: boolean
  isSubmissionDataLoaded: boolean
  loadStudentData: () => Promise<void>
  recentlyLoadedStudents: Student[]
  recentlyLoadedSubmissions: UserSubmissionGroup[]
  studentIds: string[]
  studentList: Student[]
  studentMap: StudentMap
  totalSubmissionsLoaded: number
  totalStudentsToLoad: number
}

export default (set: SetState<GradebookStore>, get: GetState<GradebookStore>): StudentsState => ({
  studentIds: [],

  isStudentIdsLoading: false,

  isStudentDataLoaded: false,

  isSubmissionDataLoaded: false,

  recentlyLoadedStudents: [],

  recentlyLoadedSubmissions: [],

  studentList: [],

  studentMap: {},

  assignmentUserSubmissionMap: {},

  totalStudentsToLoad: 0,

  totalSubmissionsLoaded: 0,

  fetchStudentIds: () => {
    const dispatch = get().dispatch
    const courseId = get().courseId

    set({isStudentIdsLoading: true})

    /*
     * When user ids have been prefetched, the data is only known valid for the
     * first request. Consume it by pulling it out of the prefetch store, which
     * will force all subsequent requests for user ids to call through the
     * network.
     */
    let promise = consumePrefetchedXHR('user_ids')
    if (promise) {
      promise = asJson(promise)
    } else {
      promise = dispatch.getJSON(`/courses/${courseId}/gradebook/user_ids`)
    }

    return (
      // @ts-expect-error
      promise
        // @ts-expect-error until consumePrefetchedXHR and dispatch.getJSON support generics
        .then((data: {user_ids: string[]}) => {
          set({
            studentIds: data.user_ids,
          })
          return data.user_ids
        })
        .catch(() => {
          set({
            flashMessages: get().flashMessages.concat([
              {
                key: 'student-ids-loading-error',
                message: I18n.t('There was an error fetching student data.'),
                variant: 'error',
              },
            ]),
          })
          return []
        })
        .finally(() => {
          set({isStudentIdsLoading: false})
        })
    )
  },

  loadStudentData: async () => {
    const dispatch = get().dispatch
    const courseId = get().courseId
    const performanceControls = get().performanceControls
    const loadedStudentIds = get().studentIds

    set({
      isStudentDataLoaded: false,
      isSubmissionDataLoaded: false,
    })

    const studentIds = await get().fetchStudentIds()
    const studentIdsToLoad = difference(studentIds, loadedStudentIds)

    if (studentIdsToLoad.length === 0) {
      set({
        isStudentDataLoaded: true,
        isSubmissionDataLoaded: true,
      })
      return
    }

    const studentRequests: Promise<void>[] = []
    const submissionRequests: Promise<void>[] = []
    const studentIdChunks: string[][] = chunk(
      studentIdsToLoad,
      performanceControls.studentsChunkSize
    )
    set({
      totalStudentsToLoad: studentIdsToLoad.length,
      totalSubmissionsLoaded: 0,
    })

    const gotChunkOfStudents = (students: Student[]) => {
      const studentMap = students.reduce(
        (acc, student) => {
          acc[student.id] = student
          return acc
        },
        {...get().studentMap}
      )
      set({
        recentlyLoadedStudents: students,
        studentList: get().studentList.concat(students),
        studentMap,
      })
    }

    const gotSubmissionsChunk = (recentlyLoadedSubmissions: UserSubmissionGroup[]) => {
      const flattenedSubmissions = recentlyLoadedSubmissions.flatMap(
        userSubmissionGroup => userSubmissionGroup.submissions || []
      )
      // merge the submissions into the existing map
      const assignmentUserSubmissionMap: AssignmentUserSubmissionMap = flattenedSubmissions.reduce(
        (acc: AssignmentUserSubmissionMap, submission: Submission) => {
          return {
            ...acc,
            [submission.assignment_id]: {
              ...acc[submission.assignment_id],
              [submission.user_id]: submission,
            },
          }
        },
        {...get().assignmentUserSubmissionMap}
      )
      set({
        recentlyLoadedSubmissions,
        assignmentUserSubmissionMap,
        totalSubmissionsLoaded: get().totalSubmissionsLoaded + flattenedSubmissions.length,
      })
    }

    // wait for all chunk requests to have been enqueued
    return new Promise<void>(resolve => {
      const getNextChunk = () => {
        if (studentIdChunks.length) {
          const nextChunkIds = studentIdChunks.shift() as string[]
          const chunkRequestDatum = getContentForStudentIdChunk(
            nextChunkIds,
            courseId,
            dispatch,
            performanceControls.submissionsChunkSize,
            performanceControls.submissionsPerPage,
            gotChunkOfStudents,
            gotSubmissionsChunk
          )

          // when the current chunk requests are all enqueued
          // eslint-disable-next-line promise/catch-or-return
          chunkRequestDatum.allEnqueued.then(() => {
            submissionRequests.push(...chunkRequestDatum.submissionRequests)
            studentRequests.push(chunkRequestDatum.studentRequest)
            getNextChunk()
          })
        } else {
          resolve()
        }
      }

      getNextChunk()
    })
      .then(() => {
        // wait for all student and submission requests to return
        return Promise.all([...studentRequests, ...submissionRequests])
      })
      .then(() => {
        set({
          isStudentDataLoaded: true,
          isSubmissionDataLoaded: true,
        })
      })
  },
})
