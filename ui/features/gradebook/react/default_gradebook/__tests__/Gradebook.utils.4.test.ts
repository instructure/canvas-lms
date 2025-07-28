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

import {
  filterStudentBySectionFn,
  getLabelForFilter,
  formatGradingPeriodTitleForDisplay,
} from '../Gradebook.utils'
import type {Filter, EnrollmentFilter} from '../gradebook.d'
import type {Student, Enrollment} from '../../../../../api.d'
import {enrollment, student, enrollmentFilter, appliedFilters, student2} from './fixtures'
import type {CamelizedGradingPeriod} from '@canvas/grading/grading'

describe('filterStudentBySectionFn', () => {
  describe('section filtering', () => {
    let modifiedStudents: Student[]
    let enrollmentFilterTest: EnrollmentFilter
    let appliedFilterTest: Filter[]
    beforeEach(() => {
      enrollmentFilterTest = {...enrollmentFilter}
      appliedFilterTest = [...appliedFilters]

      const enrollment1: Enrollment = {
        ...enrollment,
        course_section_id: 'section1',
        enrollment_state: 'active',
      }
      const enrollment2: Enrollment = {
        ...enrollment,
        course_section_id: 'section1',
        enrollment_state: 'active',
      }
      const enrollment3: Enrollment = {
        ...enrollment,
        course_section_id: 'section2',
        enrollment_state: 'active',
      }
      const modifiedStudent1: Student = {...student, name: 'Jim Doe', enrollments: [enrollment1]}
      const modifiedStudent2: Student = {
        ...student,
        name: 'Bob Jim',
        enrollments: [enrollment2, enrollment3],
      }
      modifiedStudents = [modifiedStudent1, modifiedStudent2]
    })
    it('students appear in the correct sections when switching between filters', () => {
      appliedFilterTest[0].value = 'section1'
      const filteredStudentsSection1 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilters, enrollmentFilterTest),
      )
      expect(filteredStudentsSection1).toHaveLength(2)
      appliedFilterTest[0].value = 'section2'
      const filteredStudentsSection2 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilters, enrollmentFilterTest),
      )
      expect(filteredStudentsSection2[0].name).toBe('Bob Jim')
    })
  })

  describe('enrollment filters', () => {
    let modifiedStudents: Student[]
    let enrollmentFilterTest: EnrollmentFilter
    let appliedFilterTest: Filter[]
    beforeEach(() => {
      enrollmentFilterTest = {...enrollmentFilter}
      appliedFilterTest = [...appliedFilters]

      const enrollment1: Enrollment = {
        ...enrollment,
        course_section_id: 'section1',
        enrollment_state: 'completed',
      }
      const enrollment2: Enrollment = {
        ...enrollment,
        course_section_id: 'section1',
        enrollment_state: 'inactive',
      }
      const modifiedStudent1: Student = {...student, name: 'Jim Doe', enrollments: [enrollment1]}
      const modifiedStudent2: Student = {...student, name: 'Bob Jim', enrollments: [enrollment2]}
      modifiedStudents = [modifiedStudent1, modifiedStudent2]
    })
    it('student appears in section 1 with a completed enrollment when the concluded enrollment filter is on ', () => {
      enrollmentFilterTest.inactive = false
      enrollmentFilterTest.concluded = true
      appliedFilterTest[0].value = 'section1'
      const filteredStudentsSection1 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilters, enrollmentFilterTest),
      )
      expect(filteredStudentsSection1).toHaveLength(1)
      expect(filteredStudentsSection1[0].name).toBe('Jim Doe')
    })
    it('student appears in section 1 with a inactive enrollment when the inactive enrollment filter is on ', () => {
      enrollmentFilterTest.inactive = true
      enrollmentFilterTest.concluded = false
      appliedFilterTest[0].value = 'section1'
      const filteredStudentsSection1 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilters, enrollmentFilterTest),
      )
      expect(filteredStudentsSection1).toHaveLength(1)
      expect(filteredStudentsSection1[0].name).toBe('Bob Jim')
    })
    it('both students appear in section 1 when concluded and inactive enrollment filters are both on ', () => {
      enrollmentFilterTest.inactive = true
      enrollmentFilterTest.concluded = true
      appliedFilterTest[0].value = 'section1'
      const filteredStudentsSection1 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilters, enrollmentFilterTest),
      )
      expect(filteredStudentsSection1).toHaveLength(2)
    })
  })

  describe('dual enrollment', () => {
    let enrollmentFilterTest: EnrollmentFilter
    let appliedFilterTest: Filter[]
    let modifiedStudents: Student[]
    const enrollment3: Enrollment = {
      ...enrollment,
      course_section_id: 'section2',
      enrollment_state: 'active',
    }
    const modifiedStudent2: Student = {...student2, enrollments: [enrollment3]}
    beforeEach(() => {
      enrollmentFilterTest = {...enrollmentFilter}
      appliedFilterTest = [...appliedFilters]

      const enrollment1: Enrollment = {
        ...enrollment,
        course_section_id: 'section1',
        enrollment_state: 'active',
      }
      const enrollment2: Enrollment = {
        ...enrollment,
        course_section_id: 'section2',
        enrollment_state: 'completed',
      }
      const modifiedStudent: Student = {...student, enrollments: [enrollment1, enrollment2]}
      modifiedStudents = [modifiedStudent]
    })
    it('dual enrollment student appears in section 1 with an active enrollment ', () => {
      appliedFilterTest[0].value = 'section1'
      const filteredStudentsSection1 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilterTest, enrollmentFilterTest),
      )
      expect(filteredStudentsSection1[0].name).toBe('Jim Doe')
    })

    it('dual enrollment student does not appear section 2 with a concluded enrollment ', () => {
      appliedFilterTest[0].value = 'section2'
      const filteredStudentsSection2 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilterTest, enrollmentFilterTest),
      )
      expect(filteredStudentsSection2).toHaveLength(0)
    })

    it('dual enrollment student appears in section 2 with a concluded enrollment when the concluded enrollment filter is on ', () => {
      enrollmentFilterTest.concluded = true
      appliedFilterTest[0].value = 'section2'
      const filteredStudentsSection2 = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilterTest, enrollmentFilterTest),
      )
      expect(filteredStudentsSection2[0].name).toBe('Jim Doe')
    })

    it('filteredStudents include all students when appliedFilters includes multiple sections when multiselect_gradebook_filters_enabled is true', () => {
      modifiedStudents.push(modifiedStudent2)
      ENV.GRADEBOOK_OPTIONS = {multiselect_gradebook_filters_enabled: true}
      const appliedFilters: Filter[] = [
        {
          id: '1',
          type: 'section',
          created_at: '',
          value: 'section1',
        },
        {
          id: '1',
          type: 'section',
          created_at: '',
          value: 'section2',
        },
      ]
      const filteredStudents = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilters, enrollmentFilterTest),
      )
      expect(filteredStudents).toHaveLength(2)
    })

    it('filteredStudents does not include all students when appliedFilters includes multiple sections when multiselect_gradebook_filters_enabled is false', () => {
      modifiedStudents.push(modifiedStudent2)
      ENV.GRADEBOOK_OPTIONS = {multiselect_gradebook_filters_enabled: false}
      const appliedFilters: Filter[] = [
        {
          id: '1',
          type: 'section',
          created_at: '',
          value: 'section1',
        },
        {
          id: '1',
          type: 'section',
          created_at: '',
          value: 'section2',
        },
      ]
      const filteredStudents = modifiedStudents.filter(
        filterStudentBySectionFn(appliedFilters, enrollmentFilterTest),
      )
      expect(filteredStudents).toHaveLength(1)
    })
  })

  describe('filter start and end date pill display', () => {
    ENV.TIMEZONE = 'Asia/Tokyo'

    const startFilter: Filter = {
      id: '1',
      type: 'start-date',
      created_at: '',
      value: '2023-12-13T16:00:00.000Z',
    }

    const endFilter: Filter = {
      id: '1',
      type: 'end-date',
      created_at: '',
      value: '2023-12-15T16:00:00.000Z',
    }

    it('takes the UTC filter start-date and converts it to user local time for filter pill display', () => {
      const result = getLabelForFilter(startFilter, [], [], [], [], {}, [])
      expect(result).toEqual('Start Date 12/14/2023')
    })

    it('takes the UTC filter end-date and converts it to user local time for filter pill display', () => {
      const result = getLabelForFilter(endFilter, [], [], [], [], {}, [])
      expect(result).toEqual('End Date 12/16/2023')
    })
  })
})

describe('formatGradingPeriodTitleForDisplay', () => {
  ENV.GRADEBOOK_OPTIONS = {grading_periods_filter_dates_enabled: true}
  const gp: CamelizedGradingPeriod = {
    id: '1',
    title: 'GP1',
    startDate: new Date('2021-01-01'),
    endDate: new Date('2021-01-31'),
    closeDate: new Date('2021-02-01'),
    isClosed: false,
    isLast: false,
    weight: 1,
  }

  it('returns null if handed a null grading period', () => {
    const result = formatGradingPeriodTitleForDisplay(null)
    expect(result).toBeNull()
  })

  it('returns null if handed an undefined grading period', () => {
    const result = formatGradingPeriodTitleForDisplay(undefined)
    expect(result).toBeNull()
  })

  // TODO: remove "with the feature flag" from the test description when the feature flag is removed
  it('returns the grading period title with the start, end, and close dates with the feature flag', () => {
    ENV.GRADEBOOK_OPTIONS = {grading_periods_filter_dates_enabled: true}
    const result = formatGradingPeriodTitleForDisplay(gp)
    expect(result).toEqual('GP1: 1/1/21 - 1/31/21 | 2/1/21')
  })

  // TODO: remove this test when we remove the feature flag
  it('returns only the grading period title without the feature flag', () => {
    ENV.GRADEBOOK_OPTIONS = {grading_periods_filter_dates_enabled: false}
    const result = formatGradingPeriodTitleForDisplay(gp)
    expect(result).toEqual('GP1')
  })
})
