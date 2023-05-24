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
  transformGrades,
  fetchGradesForGradingPeriod,
  fetchLatestAnnouncement,
  readableRoleName,
  fetchCourseApps,
  sendMessage,
  getAssignmentGroupTotals,
  getAssignmentGrades,
  getTotalGradeStringFromEnrollments,
  fetchImportantInfos,
  parseAnnouncementDetails,
  groupAnnouncementsByHomeroom,
  groupImportantDates,
} from '../utils'

import {MOCK_ASSIGNMENTS, MOCK_EVENTS} from './fixtures'

const ANNOUNCEMENT_URL =
  '/api/v1/announcements?context_codes=course_test&active_only=true&per_page=1'
const GRADING_PERIODS_URL = /\/api\/v1\/users\/self\/enrollments\?.*/
const USERS_URL =
  '/api/v1/courses/test/users?enrollment_type[]=teacher&enrollment_type[]=ta&include[]=avatar_url&include[]=bio&include[]=enrollments'
const APPS_URL = '/api/v1/external_tools/visible_course_nav_tools?context_codes[]=course_test'
const CONVERSATIONS_URL = '/api/v1/conversations'
const getSyllabusUrl = courseId => encodeURI(`/api/v1/courses/${courseId}?include[]=syllabus_body`)

const DEFAULT_GRADING_SCHEME = [
  ['A', 0.94],
  ['A-', 0.9],
  ['B+', 0.87],
  ['B', 0.84],
  ['B-', 0.8],
  ['C+', 0.77],
  ['C', 0.74],
  ['C-', 0.7],
  ['D+', 0.67],
  ['D', 0.64],
  ['D-', 0.61],
  ['F', 0.0],
]

afterEach(() => {
  fetchMock.restore()
})

describe('fetchLatestAnnouncement', () => {
  it('returns the first announcement if multiple are returned', async () => {
    fetchMock.get(
      ANNOUNCEMENT_URL,
      JSON.stringify([
        {
          title: 'I am first',
        },
        {
          title: 'I am not',
        },
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
          id: 14,
        },
        {
          id: 15,
        },
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

describe('transformGrades', () => {
  const defaultCourse = {
    id: '1',
    name: 'Intro to Everything',
    image_download_url: 'https://course.img',
    course_color: '#ace',
    has_grading_periods: true,
    homeroom_course: false,
    hide_final_grades: false,
    enrollments: [
      {
        current_grading_period_id: '1',
        current_grading_period_title: 'The first one',
        totals_for_all_grading_periods_option: false,
        current_period_computed_current_score: 80,
        current_period_computed_current_grade: 'B-',
        computed_current_score: 89,
        computed_current_grade: 'B+',
        type: 'student',
      },
    ],
    grading_periods: [
      {
        id: '1',
        title: 'The first one',
      },
      {
        id: '2',
        title: 'The second one',
      },
    ],
  }

  it('translates courses to just course and grade-relevant properties', async () => {
    const courseGrades = transformGrades([defaultCourse])
    expect(courseGrades).toEqual([
      {
        courseId: '1',
        courseName: 'Intro to Everything',
        courseImage: 'https://course.img',
        courseColor: '#ace',
        currentGradingPeriodId: '1',
        currentGradingPeriodTitle: 'The first one',
        enrollmentType: 'student',
        finalGradesHidden: false,
        gradingPeriods: [
          {
            id: '1',
            title: 'The first one',
          },
          {
            id: '2',
            title: 'The second one',
          },
        ],
        hasGradingPeriods: true,
        score: 80,
        grade: 'B-',
        isHomeroom: false,
        showTotalsForAllGradingPeriods: false,
        totalGradeForAllGradingPeriods: null,
        totalScoreForAllGradingPeriods: null,
        enrollments: [
          {
            current_grading_period_id: '1',
            current_grading_period_title: 'The first one',
            totals_for_all_grading_periods_option: false,
            current_period_computed_current_score: 80,
            current_period_computed_current_grade: 'B-',
            computed_current_score: 89,
            computed_current_grade: 'B+',
            type: 'student',
          },
        ],
      },
    ])
  })

  it("doesn't use current period score if the course has only one grading period", async () => {
    const courseGrades = transformGrades([{...defaultCourse, has_grading_periods: false}])
    expect(courseGrades).toEqual([
      {
        courseId: '1',
        courseName: 'Intro to Everything',
        courseImage: 'https://course.img',
        courseColor: '#ace',
        currentGradingPeriodId: '1',
        currentGradingPeriodTitle: 'The first one',
        enrollmentType: 'student',
        finalGradesHidden: false,
        gradingPeriods: [],
        hasGradingPeriods: false,
        score: 89,
        grade: 'B+',
        isHomeroom: false,
        showTotalsForAllGradingPeriods: false,
        totalGradeForAllGradingPeriods: null,
        totalScoreForAllGradingPeriods: null,
        enrollments: [
          {
            current_grading_period_id: '1',
            current_grading_period_title: 'The first one',
            totals_for_all_grading_periods_option: false,
            current_period_computed_current_score: 80,
            current_period_computed_current_grade: 'B-',
            computed_current_score: 89,
            computed_current_grade: 'B+',
            type: 'student',
          },
        ],
      },
    ])
  })

  it('populates totalGradeForAllGradingPeriods and totalScoreForAllGradingPeriods if totals option is true', async () => {
    const courseWithTotals = [
      {
        ...defaultCourse,
        enrollments: [
          {
            current_grading_period_id: '1',
            current_grading_period_title: 'The first one',
            totals_for_all_grading_periods_option: true,
            current_period_computed_current_score: 80,
            current_period_computed_current_grade: 'B-',
            computed_current_score: 89,
            computed_current_grade: 'B+',
            type: 'student',
          },
        ],
      },
    ]

    const courseGrades = transformGrades(courseWithTotals)
    expect(courseGrades).toEqual([
      {
        courseId: '1',
        courseName: 'Intro to Everything',
        courseImage: 'https://course.img',
        courseColor: '#ace',
        currentGradingPeriodId: '1',
        currentGradingPeriodTitle: 'The first one',
        enrollmentType: 'student',
        finalGradesHidden: false,
        gradingPeriods: [
          {
            id: '1',
            title: 'The first one',
          },
          {
            id: '2',
            title: 'The second one',
          },
        ],
        hasGradingPeriods: true,
        score: 80,
        grade: 'B-',
        isHomeroom: false,
        showTotalsForAllGradingPeriods: true,
        totalGradeForAllGradingPeriods: 'B+',
        totalScoreForAllGradingPeriods: 89,
        enrollments: [
          {
            current_grading_period_id: '1',
            current_grading_period_title: 'The first one',
            totals_for_all_grading_periods_option: true,
            current_period_computed_current_score: 80,
            current_period_computed_current_grade: 'B-',
            computed_current_score: 89,
            computed_current_grade: 'B+',
            type: 'student',
          },
        ],
      },
    ])
  })
})

describe('fetchGradesForGradingPeriod', () => {
  const defaultEnrollment = {
    course_id: '1',
    grades: {
      current_score: 76,
      current_grade: 'C',
    },
    role: 'StudentEnrollment',
    root_account_id: '1',
  }

  it('translates grading period grades to just the ones we care about', async () => {
    fetchMock.get(GRADING_PERIODS_URL, JSON.stringify([defaultEnrollment]))
    const enrollments = await fetchGradesForGradingPeriod(12)
    expect(enrollments).toEqual([
      {
        courseId: '1',
        score: 76,
        grade: 'C',
      },
    ])
  })

  it("doesn't include score and grade if the grades object is missing", async () => {
    fetchMock.get(GRADING_PERIODS_URL, JSON.stringify([{...defaultEnrollment, grades: undefined}]))
    const enrollments = await fetchGradesForGradingPeriod(12)
    expect(enrollments).toEqual([
      {
        courseId: '1',
        score: undefined,
        grade: undefined,
      },
    ])
  })
})

describe('fetchCourseApps', () => {
  it('calls apps api and returns list of apps', async () => {
    fetchMock.get(
      APPS_URL,
      JSON.stringify([
        {
          id: 1,
        },
        {
          id: 2,
        },
      ])
    )
    const apps = await fetchCourseApps(['test'])
    expect(apps.length).toBe(2)
    expect(apps[0].id).toBe(1)
    expect(apps[1].id).toBe(2)
  })
})

describe('sendMessage', () => {
  it('posts to the conversations endpoint', async () => {
    fetchMock.post(CONVERSATIONS_URL, 200)
    const result = await sendMessage(1, 'Hello user #1!', null)
    expect(result.response.ok).toBeTruthy()
  })
})

describe('getAssignmentGroupTotals', () => {
  it('returns an array of objects that have id, name, and score', () => {
    const data = [
      {
        id: '49',
        name: 'Assignments',
        rules: {},
        group_weight: 0.0,
        assignments: [
          {
            id: 149,
            name: '1',
            points_possible: 10.0,
            grading_type: 'points',
            submission: {
              score: 7.0,
              grade: '7.0',
              late: false,
              excused: false,
              missing: false,
            },
          },
          {
            id: 150,
            name: '2',
            points_possible: 5.0,
            grading_type: 'points',
            submission: {
              score: 5.0,
              grade: '5.0',
              late: false,
              excused: false,
              missing: false,
            },
          },
        ],
      },
    ]
    const totals = getAssignmentGroupTotals(data)
    expect(totals.length).toBe(1)
    expect(totals[0].id).toBe('49')
    expect(totals[0].name).toBe('Assignments')
    expect(totals[0].score).toBe('80.00%')
  })

  it('returns an array of objects that have id, name, and letter grade as score when Restrict Quantitative Data', () => {
    const data = [
      {
        id: '49',
        name: 'Assignments',
        rules: {},
        group_weight: 0.0,
        assignments: [
          {
            id: 149,
            name: '1',
            points_possible: 10.0,
            grading_type: 'points',
            submission: {
              score: 7.0,
              grade: '7.0',
              late: false,
              excused: false,
              missing: false,
            },
          },
          {
            id: 150,
            name: '2',
            points_possible: 5.0,
            grading_type: 'points',
            submission: {
              score: 5.0,
              grade: '5.0',
              late: false,
              excused: false,
              missing: false,
            },
          },
        ],
      },
    ]
    const totals = getAssignmentGroupTotals(data, null, null, true, DEFAULT_GRADING_SCHEME)
    expect(totals.length).toBe(1)
    expect(totals[0].id).toBe('49')
    expect(totals[0].name).toBe('Assignments')
    expect(totals[0].score).toBe('B-')
  })

  it('returns n/a for assignment groups with no assignments', () => {
    const data = [
      {
        id: '49',
        name: 'Assignments',
        rules: {},
        group_weight: 0.0,
        assignments: [],
      },
    ]
    const totals = getAssignmentGroupTotals(data)
    expect(totals[0].score).toBe('n/a')
  })

  it('excludes assignment groups without assignments in provided gradingPeriodId', () => {
    const data = [
      {
        id: '49',
        name: 'Assignments',
        rules: {},
        group_weight: 0.0,
        assignments: [
          {
            id: 149,
            name: '1',
            points_possible: 10.0,
            grading_type: 'points',
            submission: {
              score: 7.0,
              grade: '7.0',
              grading_period_id: 1,
            },
          },
        ],
      },
      {
        id: '55',
        name: 'Papers',
        rules: {},
        group_weight: 0.0,
        assignments: [
          {
            id: 178,
            name: '2',
            points_possible: 10.0,
            grading_type: 'points',
            submission: {
              score: 7.0,
              grade: '7.0',
              grading_period_id: 2,
            },
          },
        ],
      },
    ]
    const totals = getAssignmentGroupTotals(data, 1)
    expect(totals.length).toBe(1)
    expect(totals[0].name).toBe('Assignments')
  })
})

describe('getAssignmentGrades', () => {
  it('includes assignments from different groups in returned array', () => {
    const data = [
      {
        id: '49',
        name: 'Assignments',
        assignments: [
          {
            id: 149,
            name: '1',
            html_url: 'http://localhost/1',
            due_at: null,
            points_possible: 10.0,
            grading_type: 'points',
          },
        ],
      },
      {
        id: '50',
        name: 'Essays',
        assignments: [
          {
            id: 150,
            name: '2',
            html_url: 'http://localhost/2',
            due_at: '2020-04-18T05:59:59Z',
            points_possible: 10.0,
            grading_type: 'points',
          },
        ],
      },
    ]
    const totals = getAssignmentGrades(data)
    expect(totals.length).toBe(2)
    expect(totals[0].assignmentName).toBe('2')
    expect(totals[1].assignmentName).toBe('1')
  })

  it('saves unread as true if read_state is unread', () => {
    const data = [
      {
        id: '49',
        name: 'Assignments',
        assignments: [
          {
            id: 149,
            name: '1',
            points_possible: 10.0,
            grading_type: 'points',
            submission: {
              read_state: 'unread',
            },
          },
        ],
      },
    ]
    const totals = getAssignmentGrades(data)
    expect(totals[0].unread).toBeTruthy()
  })

  it('sets hasComments appropriately', () => {
    const data = [
      {
        id: '49',
        assignments: [
          {
            id: 149,
            submission: {
              submission_comments: [
                {
                  id: 1,
                },
              ],
            },
          },
          {
            id: 150,
            submission: {
              submission_comments: [],
            },
          },
          {
            id: 151,
          },
        ],
      },
    ]
    const totals = getAssignmentGrades(data)
    expect(totals.find(({id}) => id === 149).hasComments).toBe(true)
    expect(totals.find(({id}) => id === 150).hasComments).toBe(false)
    expect(totals.find(({id}) => id === 151).hasComments).toBe(false)
  })
})

describe('getTotalGradeStringFromEnrollments', () => {
  it("returns n/a if there's no score or grade", () => {
    const enrollments = [
      {
        user_id: '2',
        grades: {
          current_score: null,
          current_grade: null,
        },
      },
    ]
    expect(getTotalGradeStringFromEnrollments(enrollments, '2')).toBe('n/a')
  })

  it('returns just the B Letter Grade if Restrict Quantitative Data is true', () => {
    const enrollments = [
      {
        user_id: '2',
        grades: {
          current_score: 84,
          current_grade: null,
        },
      },
    ]
    expect(
      getTotalGradeStringFromEnrollments(enrollments, '2', false, true, DEFAULT_GRADING_SCHEME)
    ).toBe('B')
  })

  it('returns just the F Letter Grade if Restrict Quantitative Data is true', () => {
    const enrollments = [
      {
        user_id: '2',
        grades: {
          current_score: 0,
          current_grade: null,
        },
      },
    ]

    expect(
      getTotalGradeStringFromEnrollments(enrollments, '2', false, true, DEFAULT_GRADING_SCHEME)
    ).toBe('F')
  })

  it("returns just the percent with 2 decimals if there's no grade", () => {
    const enrollments = [
      {
        user_id: '2',
        grades: {
          current_score: 84,
          current_grade: null,
        },
      },
    ]

    expect(getTotalGradeStringFromEnrollments(enrollments, '2')).toBe('84.00%')
  })

  it('returns formatted score and grade if both exist', () => {
    const enrollments = [
      {
        user_id: '2',
        grades: {
          current_score: 87.34,
          current_grade: 'B+',
        },
      },
    ]
    expect(getTotalGradeStringFromEnrollments(enrollments, '2')).toBe('87.34% (B+)')
  })

  it('finds the correct enrollment if multiple are returned', () => {
    const enrollments = [
      {
        user_id: '1',
        grades: {
          current_score: 1,
        },
      },
      {
        user_id: '2',
        grades: {
          current_score: 2,
        },
      },
      {
        user_id: '3',
        grades: {
          current_score: 3,
        },
      },
    ]
    expect(getTotalGradeStringFromEnrollments(enrollments, '2')).toBe('2.00%')
  })
})

describe('fetchImportantInfos', () => {
  it('returns syllabus objects for each homeroom course', async () => {
    fetchMock.get(getSyllabusUrl('32'), {syllabus_body: 'Hello!'})
    fetchMock.get(getSyllabusUrl('35'), {syllabus_body: 'Welcome'})
    const response = await fetchImportantInfos([
      {
        id: '32',
        shortName: 'Course 1',
        canManage: true,
      },
      {
        id: '35',
        shortName: 'Course 2',
        canManage: false,
      },
    ])

    expect(response[0].courseId).toBe('32')
    expect(response[0].courseName).toBe('Course 1')
    expect(response[0].canEdit).toBe(true)
    expect(response[0].content).toBe('Hello!')

    expect(response[1].courseId).toBe('35')
    expect(response[1].courseName).toBe('Course 2')
    expect(response[1].canEdit).toBe(false)
    expect(response[1].content).toBe('Welcome')
  })

  it("doesn't return data for homerooms with no syllabus content", async () => {
    fetchMock.get(getSyllabusUrl('32'), {syllabus_body: null})
    const response = await fetchImportantInfos([
      {
        id: '32',
        shortName: 'Course 1',
        canManage: true,
      },
    ])
    expect(response.length).toBe(0)
  })
})

describe('parseAnnouncementDetails', () => {
  const announcement = {
    title: 'Hello class',
    message: '<p>Some details</p>',
    html_url: 'http://localhost:3000/courses/78/discussion_topics/72',
    id: '72',
    permissions: {
      update: true,
    },
    attachments: [
      {
        id: '409',
        display_name: 'File.pdf',
        filename: 'file12.pdf',
        url: 'http://localhost:3000/files/longpath',
      },
    ],
    posted_at: '2021-05-14T17:06:21-06:00',
  }

  const course = {
    id: '78',
    shortName: 'Reading',
    href: 'http://localhost:3000/courses/78',
    canManage: false,
    published: true,
  }

  it('filters and renames attributes in received object', () => {
    const announcementDetails = parseAnnouncementDetails(announcement, course)

    expect(announcementDetails.courseId).toBe('78')
    expect(announcementDetails.courseName).toBe('Reading')
    expect(announcementDetails.courseUrl).toBe('http://localhost:3000/courses/78')
    expect(announcementDetails.canEdit).toBe(true)
    expect(announcementDetails.published).toBe(true)
    expect(announcementDetails.announcement.title).toBe('Hello class')
    expect(announcementDetails.announcement.message).toBe('<p>Some details</p>')
    expect(announcementDetails.announcement.url).toBe(
      'http://localhost:3000/courses/78/discussion_topics/72'
    )
    expect(announcementDetails.announcement.attachment.display_name).toBe('File.pdf')
    expect(announcementDetails.announcement.attachment.url).toBe(
      'http://localhost:3000/files/longpath'
    )
    expect(announcementDetails.announcement.attachment.filename).toBe('file12.pdf')
    expect(new Date(announcementDetails.announcement.postedDate)).toEqual(
      new Date('2021-05-14T17:06:21-06:00')
    )
  })

  it('handles a missing attachment', () => {
    const announcementDetails = parseAnnouncementDetails({...announcement, attachments: []}, course)
    expect(announcementDetails.announcement.attachment).toBeUndefined()
  })

  it('handles a missing posted_at date', () => {
    const announcementDetails = parseAnnouncementDetails(
      {...announcement, posted_at: undefined},
      course
    )
    expect(announcementDetails.announcement.postedDate).toBeUndefined()
  })
})

describe('groupAnnouncementsByHomeroom', () => {
  const announcements = [
    {
      id: '10',
      context_code: 'course_1',
    },
    {
      id: '11',
      context_code: 'course_2',
      permissions: {
        update: false,
      },
      attachments: [],
    },
    {
      id: '12',
      context_code: 'course_3',
    },
  ]
  const courses = [
    {
      id: '1',
      isHomeroom: false,
    },
    {
      id: '2',
      isHomeroom: true,
    },
  ]

  it('groups returned announcements by whether they are associated with a homeroom or not', () => {
    const grouped = groupAnnouncementsByHomeroom(announcements, courses)
    expect(Object.keys(grouped)).toEqual(['true', 'false'])
    expect(grouped.true).toHaveLength(1)
    expect(grouped.false).toHaveLength(1)
    expect(grouped.true[0].announcement.id).toBe('11')
    expect(grouped.false[0].id).toBe('10')
  })

  it('parses announcement details on homeroom announcements only', () => {
    const grouped = groupAnnouncementsByHomeroom(announcements, courses)
    expect(grouped.true[0].courseId).toBe('2')
    expect(grouped.false[0].courseId).toBeUndefined()
  })

  it('ignores announcements not associated with a passed-in course', () => {
    const grouped = groupAnnouncementsByHomeroom(announcements, courses)
    expect([...grouped.true, ...grouped.false]).toHaveLength(2)
  })

  it('handles missing announcements and courses gracefully', () => {
    const emptyGroups = {true: [], false: []}
    expect(groupAnnouncementsByHomeroom([], courses)).toEqual({
      true: [{courseId: '2'}],
      false: [],
    })
    expect(groupAnnouncementsByHomeroom(announcements, [])).toEqual(emptyGroups)
    expect(groupAnnouncementsByHomeroom()).toEqual(emptyGroups)
  })
})

describe('groupImportantDates', () => {
  const mountainTime = 'America/Denver'
  const kathmanduTime = 'Asia/Kathmandu'

  it('combines assignments and events into sorted array with items grouped by date bucket', () => {
    const items = groupImportantDates(MOCK_ASSIGNMENTS, MOCK_EVENTS, mountainTime)
    expect(items.length).toBe(3)
    expect(items[0].date).toBe('2021-06-30T06:00:00.000Z')
    expect(items[1].date).toBe('2021-07-02T06:00:00.000Z')
    expect(items[2].date).toBe('2021-07-04T06:00:00.000Z')
    expect(items[0].items[0].id).toBe('99')
    expect(items[1].items[0].id).toBe('assignment_175')
    expect(items[2].items[0].id).toBe('assignment_176')
    expect(items[2].items[1].id).toBe('assignment_177')
  })

  it('groups items into date buckets correctly for different timezones', () => {
    const items = groupImportantDates(MOCK_ASSIGNMENTS, MOCK_EVENTS, kathmanduTime)
    expect(items.length).toBe(4)
    expect(items[0].date).toBe('2021-06-29T18:15:00.000Z')
    expect(items[1].date).toBe('2021-07-01T18:15:00.000Z')
    expect(items[2].date).toBe('2021-07-03T18:15:00.000Z')
    expect(items[3].date).toBe('2021-07-04T18:15:00.000Z')
    expect(items[0].items[0].id).toBe('99')
    expect(items[1].items[0].id).toBe('assignment_175')
    expect(items[2].items[0].id).toBe('assignment_176')
    expect(items[3].items[0].id).toBe('assignment_177')
  })

  it('returns an empty array if no items are received', () => {
    const items = groupImportantDates([], [], mountainTime)
    expect(items).toEqual([])
  })

  it('still works if only assignments are passed', () => {
    const items = groupImportantDates(MOCK_ASSIGNMENTS, [], mountainTime)
    expect(items.length).toBe(2)
    expect(items[0].items[0].id).toBe('assignment_175')
  })

  it('still works if only events are passed', () => {
    const items = groupImportantDates([], MOCK_EVENTS, kathmanduTime)
    expect(items.length).toBe(1)
    expect(items[0].items[0].id).toBe('99')
  })

  it('uses default color if item does not supply a context_color', () => {
    const items = groupImportantDates([MOCK_ASSIGNMENTS[0]], [], mountainTime)
    expect(items[0].items[0].color).toBe('#394B58')
  })

  it('renames variables properly for assignment types', () => {
    const items = groupImportantDates([MOCK_ASSIGNMENTS[1]], [], mountainTime)
    const assignment = items[0].items[0]
    expect(assignment.id).toBe('assignment_176')
    expect(assignment.title).toBe('History Discussion')
    expect(assignment.context).toBe('History')
    expect(assignment.color).toBe('#CCCCCC')
    expect(assignment.type).toBe('discussion_topic')
    expect(assignment.url).toBe('http://localhost:3000/courses/31/assignments/176')
    expect(assignment.start).toBe('2021-07-04T11:30:00Z')
  })

  it('renames variables properly for event types', () => {
    const items = groupImportantDates([], MOCK_EVENTS, mountainTime)
    const event = items[0].items[0]
    expect(event.id).toBe('99')
    expect(event.title).toBe('Morning Yoga')
    expect(event.context).toBe('History')
    expect(event.color).toBe('#CCCCCC')
    expect(event.type).toBe('event')
    expect(event.url).toBe('http://localhost:3000/calendar?event_id=99&include_contexts=course_30')
    expect(event.start).toBe('2021-06-30T07:00:00Z')
  })
})
