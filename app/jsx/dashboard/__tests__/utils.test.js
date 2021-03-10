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

import fetchMock from 'fetch-mock'

import {
  fetchCourseInstructors,
  fetchGrades,
  fetchGradesForGradingPeriod,
  fetchLatestAnnouncement,
  readableRoleName,
  fetchCourseApps
} from 'jsx/dashboard/utils'

const ANNOUNCEMENT_URL =
  '/api/v1/announcements?context_codes=course_test&active_only=true&per_page=1'

const GRADES_URL = /\/api\/v1\/users\/self\/courses\?.*/
const GRADING_PERIODS_URL = /\/api\/v1\/users\/self\/enrollments\?.*/

const USERS_URL =
  '/api/v1/courses/test/users?enrollment_type[]=teacher&enrollment_type[]=ta&include[]=avatar_url&include[]=bio&include[]=enrollments'

const APPS_URL = '/api/v1/courses/test/external_tools/visible_course_nav_tools'

afterEach(() => {
  fetchMock.restore()
})

describe('fetchLatestAnnouncement', () => {
  it('returns the first announcement if multiple are returned', async () => {
    fetchMock.get(
      ANNOUNCEMENT_URL,
      JSON.stringify([
        {
          title: 'I am first'
        },
        {
          title: 'I am not'
        }
      ])
    )
    const announcement = await fetchLatestAnnouncement('test')
    expect(announcement).toEqual({title: 'I am first'})
  })

  it('returns null if an empty array is returned', async () => {
    fetchMock.get(ANNOUNCEMENT_URL, '[]')
    const announcement = await fetchLatestAnnouncement('test')
    expect(announcement).toBeNull()
  })

  it('returns null if something falsy is returned', async () => {
    fetchMock.get(ANNOUNCEMENT_URL, 'null')
    const announcement = await fetchLatestAnnouncement('test')
    expect(announcement).toBeNull()
  })
})

describe('fetchCourseInstructors', () => {
  it('returns multiple instructors if applicable', async () => {
    fetchMock.get(
      USERS_URL,
      JSON.stringify([
        {
          id: 14
        },
        {
          id: 15
        }
      ])
    )
    const instructors = await fetchCourseInstructors('test')
    expect(instructors.length).toBe(2)
    expect(instructors[0].id).toBe(14)
    expect(instructors[1].id).toBe(15)
  })
})

describe('readableRoleName', () => {
  it('returns correct role names for standard enrollment types', () => {
    expect(readableRoleName('TeacherEnrollment')).toBe('Teacher')
    expect(readableRoleName('TaEnrollment')).toBe('Teaching Assistant')
    expect(readableRoleName('DesignerEnrollment')).toBe('Designer')
    expect(readableRoleName('StudentEnrollment')).toBe('Student')
    expect(readableRoleName('StudentViewEnrollment')).toBe('Student')
    expect(readableRoleName('ObserverEnrollment')).toBe('Observer')
  })

  it('returns correct role name for custom role', () => {
    const customName = 'Super Cool Teacher'
    expect(readableRoleName(customName)).toBe(customName)
  })
})

describe('fetchGrades', () => {
  const defaultCourse = {
    id: '1',
    name: 'Intro to Everything',
    image_download_url: 'https://course.img',
    has_grading_periods: true,
    homeroom_course: false,
    enrollments: [
      {
        current_grading_period_id: '1',
        current_grading_period_title: 'The first one',
        current_period_computed_current_score: 80,
        current_period_computed_current_grade: 'B-',
        computed_current_score: 89,
        computed_current_grade: 'B+'
      }
    ],
    grading_periods: [
      {
        id: '1',
        title: 'The first one'
      },
      {
        id: '2',
        title: 'The second one'
      }
    ]
  }

  it('translates courses to just course and grade-relevant properties', async () => {
    fetchMock.get(GRADES_URL, JSON.stringify([defaultCourse]))
    const courseGrades = await fetchGrades()
    expect(courseGrades).toEqual([
      {
        courseId: '1',
        courseName: 'Intro to Everything',
        courseImage: 'https://course.img',
        currentGradingPeriodId: '1',
        currentGradingPeriodTitle: 'The first one',
        gradingPeriods: [
          {
            id: '1',
            title: 'The first one'
          },
          {
            id: '2',
            title: 'The second one'
          }
        ],
        hasGradingPeriods: true,
        score: 80,
        grade: 'B-',
        isHomeroom: false
      }
    ])
  })

  it("doesn't use current period score if the course has only one grading period", async () => {
    fetchMock.get(GRADES_URL, JSON.stringify([{...defaultCourse, has_grading_periods: false}]))
    const courseGrades = await fetchGrades()
    expect(courseGrades).toEqual([
      {
        courseId: '1',
        courseName: 'Intro to Everything',
        courseImage: 'https://course.img',
        currentGradingPeriodId: '1',
        currentGradingPeriodTitle: 'The first one',
        gradingPeriods: [],
        hasGradingPeriods: false,
        score: 89,
        grade: 'B+',
        isHomeroom: false
      }
    ])
  })
})

describe('fetchGradesForGradingPeriod', () => {
  const defaultEnrollment = {
    course_id: '1',
    grades: {
      current_score: 76,
      current_grade: 'C'
    },
    role: 'StudentEnrollment',
    root_account_id: '1'
  }

  it('translates grading period grades to just the ones we care about', async () => {
    fetchMock.get(GRADING_PERIODS_URL, JSON.stringify([defaultEnrollment]))
    const enrollments = await fetchGradesForGradingPeriod(12)
    expect(enrollments).toEqual([
      {
        courseId: '1',
        score: 76,
        grade: 'C'
      }
    ])
  })

  it("doesn't include score and grade if the grades object is missing", async () => {
    fetchMock.get(GRADING_PERIODS_URL, JSON.stringify([{...defaultEnrollment, grades: undefined}]))
    const enrollments = await fetchGradesForGradingPeriod(12)
    expect(enrollments).toEqual([
      {
        courseId: '1',
        score: undefined,
        grade: undefined
      }
    ])
  })
})

describe('fetchCourseApps', () => {
  it('calls apps api and returns list of apps', async () => {
    fetchMock.get(
      APPS_URL,
      JSON.stringify([
        {
          id: 1
        },
        {
          id: 2
        }
      ])
    )
    const apps = await fetchCourseApps('test')
    expect(apps.length).toBe(2)
    expect(apps[0].id).toBe(1)
    expect(apps[1].id).toBe(2)
  })
})
