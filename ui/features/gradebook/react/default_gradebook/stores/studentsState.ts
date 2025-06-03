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

import {difference, chunk, keyBy, groupBy, cloneDeep, setWith as lodashSetWith} from 'lodash'
import type {StoreApi} from 'zustand'
import {useScope as createI18nScope} from '@canvas/i18n'
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
import {getAllUsers} from './graphql/users/getAllUsers'
import {User, GetUsersResult} from './graphql/users/getUsers'
import {transformUser} from './graphql/users/transformUser'
import {Enrollment} from './graphql/enrollments/getEnrollments'
import {getAllEnrollments} from './graphql/enrollments/getAllEnrollments'
import {transformEnrollment} from './graphql/enrollments/transformEnrollment'
import GRADEBOOK_GRAPHQL_CONFIG from './graphql/config'
import pLimit from 'p-limit'
import {getAllSubmissions} from './graphql/submissions/getAllSubmissions'
import {transformSubmission} from './graphql/submissions/transformSubmission'

const I18n = createI18nScope('gradebook')

export type StudentsState = {
  assignmentUserSubmissionMap: AssignmentUserSubmissionMap
  fetchStudentIds: () => Promise<string[]>
  isStudentDataLoaded: boolean
  isStudentIdsLoading: boolean
  isSubmissionDataLoaded: boolean
  loadStudentData: (useGraphQL: boolean) => Promise<void>
  loadCompositeStudentData: () => Promise<void>
  loadGraphqlStudentData: () => Promise<void>
  recentlyLoadedStudents: Student[]
  recentlyLoadedSubmissions: UserSubmissionGroup[]
  studentIds: string[]
  studentList: Student[]
  studentMap: StudentMap
  totalSubmissionsLoaded: number
  totalStudentsToLoad: number
}

export default (
  set: StoreApi<GradebookStore>['setState'],
  get: StoreApi<GradebookStore>['getState'],
): StudentsState => ({
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

  loadStudentData: async (useGraphQL: boolean) => {
    if (useGraphQL) get().loadGraphqlStudentData()
    else get().loadCompositeStudentData()
  },

  loadCompositeStudentData: async () => {
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
      performanceControls.studentsChunkSize,
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
        {...get().studentMap},
      )
      set({
        recentlyLoadedStudents: students,
        studentList: get().studentList.concat(students),
        studentMap,
      })
    }

    const gotSubmissionsChunk = (recentlyLoadedSubmissions: UserSubmissionGroup[]) => {
      const flattenedSubmissions = recentlyLoadedSubmissions.flatMap(
        userSubmissionGroup => userSubmissionGroup.submissions || [],
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
        {...get().assignmentUserSubmissionMap},
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
            gotSubmissionsChunk,
          )

          // when the current chunk requests are all enqueued

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

  loadGraphqlStudentData: async () => {
    const courseId = get().courseId
    const loadedStudentIds = get().studentIds

    set({
      isStudentDataLoaded: false,
      isSubmissionDataLoaded: false,
    })

    // this query runs pretty fast already, and it seems complex in the backend
    // let's keep it
    const studentIds = await get().fetchStudentIds()

    const studentIdsToLoad = difference(studentIds, loadedStudentIds)

    if (studentIdsToLoad.length === 0) {
      set({
        isStudentDataLoaded: true,
        isSubmissionDataLoaded: true,
      })
      return
    }

    set({
      totalStudentsToLoad: studentIdsToLoad.length,
      totalSubmissionsLoaded: 0,
    })

    const onSubmissionPageSuccess = (userSubmissionGroups: UserSubmissionGroup[]) => {
      const submissions = userSubmissionGroups.flatMap(it => it.submissions)
      // merge the submissions into the existing map
      const assignmentUserSubmissionMap: AssignmentUserSubmissionMap = cloneDeep(
        get().assignmentUserSubmissionMap,
      )
      submissions.forEach(it => {
        lodashSetWith(assignmentUserSubmissionMap, `${it.assignment_id}.${it.user_id}`, it, Object)
      })

      set({
        recentlyLoadedSubmissions: userSubmissionGroups,
        assignmentUserSubmissionMap,
        totalSubmissionsLoaded: get().totalSubmissionsLoaded + submissions.length,
      })
    }

    const onEnrollmentSuccess = async (users: User[], enrollments: Enrollment[]) => {
      // 10 submissions request max concurrently
      const limit = pLimit(GRADEBOOK_GRAPHQL_CONFIG.maxSubmissionRequestCount)
      const userIds = users.map(it => it._id)

      // Group enrollments by user_id into arrays, using lodash groupBy
      const enrollmentsByUserId = groupBy(enrollments.map(transformEnrollment), 'user_id')
      const students = users.map(it => ({
        ...transformUser(it),
        // we have to set sis_user_id from the user object
        enrollments: (enrollmentsByUserId[it._id] ?? []).map(enrollment => ({
          ...enrollment,
          sis_user_id: it.sisId,
        })),
      }))

      const studentMap = {...keyBy(students, 'id'), ...get().studentMap}
      set({
        recentlyLoadedStudents: students,
        studentList: get().studentList.concat(students),
        studentMap,
      })

      // fetch submissions for userIds
      const userIdChunks = chunk(
        userIds,
        GRADEBOOK_GRAPHQL_CONFIG.initialNumberOfStudentsPerSubmissionRequest,
      )

      const promises = userIdChunks.map(userIdChunk =>
        limit(async () => {
          const {data} = await getAllSubmissions({
            queryParams: {userIds: userIdChunk, courseId},
          })
          const submissionsByUserId = groupBy(data.map(transformSubmission), 'user_id')

          onSubmissionPageSuccess(
            Object.entries(submissionsByUserId).map(([userId, submissions]) => ({
              user_id: userId,
              submissions,
              // section_id is not used
              section_id: '',
            })),
          )
        }),
      )
      await Promise.all(promises)
    }

    const onUserPageSuccess = async (users: GetUsersResult) => {
      const userIds = users.course.usersConnection.nodes.map(it => it._id)
      const {data: enrollments} = await getAllEnrollments({
        queryParams: {userIds: userIds, courseId},
      })
      await onEnrollmentSuccess(users.course.usersConnection.nodes, enrollments)
    }

    const {onSuccessCallbacks, onErrorCallbacks} = await getAllUsers({
      queryParams: {
        userIds: studentIdsToLoad,
        courseId,
        first: GRADEBOOK_GRAPHQL_CONFIG.usersPageSize,
      },
      onSuccess: onUserPageSuccess,
    })
    await Promise.all([...onSuccessCallbacks, ...onErrorCallbacks])

    set({
      isStudentDataLoaded: true,
      isSubmissionDataLoaded: true,
    })
  },
})
