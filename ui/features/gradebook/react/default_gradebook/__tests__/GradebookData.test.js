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

import {createGradebook} from './GradebookSpecHelper'

window.ENV.SETTINGS = {}

describe('Gradebook#setAssignmentsLoaded', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    gradebook.contentLoadStates.assignmentsLoaded.gradingPeriod = {2: false, 59: false}
  })

  it('sets all assignments as loaded', () => {
    gradebook.setAssignmentsLoaded()
    expect(gradebook.contentLoadStates.assignmentsLoaded.all).toBe(true)
  })

  it('sets all grading periods as loaded', () => {
    gradebook.setAssignmentsLoaded()
    const gpLoadStates = Object.values(gradebook.contentLoadStates.assignmentsLoaded.gradingPeriod)
    expect(gpLoadStates.every(loaded => loaded)).toBe(true)
  })

  describe('when assignments are loaded for particular grading periods', () => {
    it('sets assignments loaded for the expected grading period', () => {
      gradebook.setAssignmentsLoaded(['59'])
      expect(gradebook.contentLoadStates.assignmentsLoaded.gradingPeriod[59]).toBe(true)
    })

    it('does not set assignments loaded for excluded grading periods', () => {
      gradebook.setAssignmentsLoaded(['59'])
      expect(gradebook.contentLoadStates.assignmentsLoaded.gradingPeriod[2]).toBe(false)
    })

    it('sets all assignments loaded if all grading periods are loaded', () => {
      gradebook.setAssignmentsLoaded(['59', '2'])
      expect(gradebook.contentLoadStates.assignmentsLoaded.all).toBe(true)
    })

    it('does not set all assignments loaded if not all grading periods are loaded', () => {
      gradebook.setAssignmentsLoaded(['59'])
      expect(gradebook.contentLoadStates.assignmentsLoaded.all).toBe(false)
    })
  })
})

describe('Gradebook#getSubmission', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    gradebook.students = {
      1101: {id: '1101', assignment_201: {score: 10, possible: 20}, assignment_202: {}},
      1102: {id: '1102', assignment_201: {}},
    }
  })

  it('returns the submission when the student and submission are both present', () => {
    expect(gradebook.getSubmission('1101', '201')).toEqual({score: 10, possible: 20})
  })

  it('returns undefined when the student is present but the submission is not', () => {
    expect(gradebook.getSubmission('1101', '999')).toBeUndefined()
  })

  it('returns undefined when the student is not present', () => {
    expect(gradebook.getSubmission('2202', '201')).toBeUndefined()
  })
})

describe('Gradebook#gotAllAssignmentGroups', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
  })

  it('sets the "assignment groups loaded" state', () => {
    vi.spyOn(gradebook, 'setAssignmentGroupsLoaded')
    gradebook.gotAllAssignmentGroups([])
    expect(gradebook.setAssignmentGroupsLoaded).toHaveBeenCalledTimes(1)
  })

  it('sets the "assignment groups loaded" state to true', () => {
    vi.spyOn(gradebook, 'setAssignmentGroupsLoaded')
    gradebook.gotAllAssignmentGroups([])
    expect(gradebook.setAssignmentGroupsLoaded).toHaveBeenCalledWith(true)
  })

  it('adds the assignment group to the group definitions if it is new', () => {
    vi.spyOn(gradebook, 'setAssignmentGroupsLoaded')
    const assignmentGroup = {
      id: '12',
      assignments: [{id: '35', name: 'An Assignment', due_at: null}],
    }
    gradebook.gotAllAssignmentGroups([assignmentGroup])
    expect(gradebook.assignmentGroups['12']).toEqual(assignmentGroup)
  })

  it('adds new assignments to existing assignment groups', () => {
    vi.spyOn(gradebook, 'setAssignmentGroupsLoaded')
    gradebook.assignmentGroups['12'] = {
      id: '12',
      assignments: [{id: '22', name: 'Some Other Assignment', due_at: null}],
    }
    const assignmentGroup = {
      id: '12',
      assignments: [{id: '35', name: 'An Assignment', due_at: null}],
    }
    gradebook.gotAllAssignmentGroups([assignmentGroup])
    const assignmentIds = gradebook.assignmentGroups['12'].assignments.map(a => a.id)
    expect(assignmentIds).toEqual(['22', '35'])
  })

  it('does not add duplicate assignments to assignment groups', () => {
    vi.spyOn(gradebook, 'setAssignmentGroupsLoaded')
    gradebook.assignmentGroups['12'] = {
      id: '12',
      assignments: [{id: '35', name: 'An Assignment', due_at: null}],
    }
    const assignmentGroup = {
      id: '12',
      assignments: [{id: '35', name: 'An Assignment', due_at: null}],
    }
    gradebook.gotAllAssignmentGroups([assignmentGroup])
    const assignmentIds = gradebook.assignmentGroups['12'].assignments.map(a => a.id)
    expect(assignmentIds).toEqual(['35'])
  })

  describe('peer review sub assignments', () => {
    beforeEach(() => {
      window.ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED = true
    })

    afterEach(() => {
      window.ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED = false
    })

    it('adds peer review sub assignments to the assignment group', () => {
      vi.spyOn(gradebook, 'setAssignmentGroupsLoaded')
      vi.spyOn(gradebook, 'addAssignmentColumnDefinition')
      const assignmentGroup = {
        id: '12',
        assignment_group_id: '12',
        assignments: [
          {
            id: '35',
            name: 'An Assignment',
            due_at: null,
            assignment_group_id: '12',
            peer_reviews: true,
            peer_review_sub_assignment: {
              id: '36',
              name: 'Peer Review',
              due_at: null,
            },
          },
        ],
      }
      gradebook.gotAllAssignmentGroups([assignmentGroup])
      const assignmentIds = gradebook.assignmentGroups['12'].assignments.map(a => a.id)
      expect(assignmentIds).toEqual(['35', '36'])
    })

    it('adds peer review sub assignments to the assignments object', () => {
      vi.spyOn(gradebook, 'setAssignmentGroupsLoaded')
      vi.spyOn(gradebook, 'addAssignmentColumnDefinition')
      const assignmentGroup = {
        id: '12',
        assignment_group_id: '12',
        assignments: [
          {
            id: '35',
            name: 'An Assignment',
            due_at: null,
            assignment_group_id: '12',
            peer_reviews: true,
            peer_review_sub_assignment: {
              id: '36',
              name: 'Peer Review',
              due_at: null,
            },
          },
        ],
      }
      gradebook.gotAllAssignmentGroups([assignmentGroup])
      expect(gradebook.assignments['36']).toBeDefined()
      expect(gradebook.assignments['36'].parent_assignment_id).toBe('35')
    })

    it('adds parent_assignment reference to peer review sub assignments', () => {
      vi.spyOn(gradebook, 'setAssignmentGroupsLoaded')
      vi.spyOn(gradebook, 'addAssignmentColumnDefinition')
      const parentAssignment = {
        id: '35',
        name: 'An Assignment',
        due_at: null,
        assignment_group_id: '12',
        peer_reviews: true,
        peer_review_sub_assignment: {
          id: '36',
          name: 'Peer Review',
          due_at: null,
        },
      }
      const assignmentGroup = {
        id: '12',
        assignment_group_id: '12',
        assignments: [parentAssignment],
      }
      gradebook.gotAllAssignmentGroups([assignmentGroup])
      expect(gradebook.assignments['36'].parent_assignment).toEqual(parentAssignment)
    })

    it('adds column definition for peer review sub assignments', () => {
      vi.spyOn(gradebook, 'setAssignmentGroupsLoaded')
      vi.spyOn(gradebook, 'addAssignmentColumnDefinition')
      const assignmentGroup = {
        id: '12',
        assignment_group_id: '12',
        assignments: [
          {
            id: '35',
            name: 'An Assignment',
            due_at: null,
            assignment_group_id: '12',
            peer_reviews: true,
            peer_review_sub_assignment: {
              id: '36',
              name: 'Peer Review',
              due_at: null,
            },
          },
        ],
      }
      gradebook.gotAllAssignmentGroups([assignmentGroup])
      expect(gradebook.addAssignmentColumnDefinition).toHaveBeenCalledTimes(2)
    })
  })

  it('does not add peer review sub assignments when peer_review_sub_assignment is missing', () => {
    vi.spyOn(gradebook, 'setAssignmentGroupsLoaded')
    vi.spyOn(gradebook, 'addAssignmentColumnDefinition')
    const assignmentGroup = {
      id: '12',
      assignment_group_id: '12',
      assignments: [
        {
          id: '35',
          name: 'An Assignment',
          due_at: null,
          assignment_group_id: '12',
          peer_reviews: true,
        },
      ],
    }
    gradebook.gotAllAssignmentGroups([assignmentGroup])
    expect(gradebook.addAssignmentColumnDefinition).toHaveBeenCalledTimes(1)
    expect(gradebook.assignments['36']).toBeUndefined()
  })

  it('does not add peer review sub assignments when assignment does not have peer reviews enabled', () => {
    vi.spyOn(gradebook, 'setAssignmentGroupsLoaded')
    vi.spyOn(gradebook, 'addAssignmentColumnDefinition')
    const assignmentGroup = {
      id: '12',
      assignment_group_id: '12',
      assignments: [
        {
          id: '35',
          name: 'An Assignment',
          due_at: null,
          assignment_group_id: '12',
          peer_reviews: false,
          peer_review_sub_assignment: {
            id: '36',
            name: 'Peer Review',
            due_at: null,
          },
        },
      ],
    }
    gradebook.gotAllAssignmentGroups([assignmentGroup])
    expect(gradebook.addAssignmentColumnDefinition).toHaveBeenCalledTimes(1)
    expect(gradebook.assignments['36']).toBeUndefined()
  })
})

describe('Gradebook#updateFilterAssignmentIds', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    gradebook.setAssignments({
      2301: {
        id: '2301',
        name: 'Assignment 1',
        published: true,
      },
      2302: {
        id: '2302',
        name: 'Assignment 2',
        published: true,
        peer_review_sub_assignment: {
          id: '2303',
          name: 'Peer Review',
        },
      },
      2303: {
        id: '2303',
        name: 'Peer Review',
        published: true,
        parent_assignment_id: '2302',
      },
      2304: {
        id: '2304',
        name: 'Assignment 3',
        published: true,
      },
    })
  })

  it('includes peer review sub assignments right after their parent assignments', () => {
    gradebook.updateFilterAssignmentIds()
    expect(gradebook.filteredAssignmentIds).toEqual(['2301', '2302', '2303', '2304'])
  })

  it('removes duplicate peer review sub assignments', () => {
    gradebook.updateFilterAssignmentIds()
    const counts = gradebook.filteredAssignmentIds.reduce((acc, id) => {
      acc[id] = (acc[id] || 0) + 1
      return acc
    }, {})
    expect(counts['2303']).toBe(1)
  })

  it('maintains correct order with multiple peer review sub assignments', () => {
    gradebook.setAssignments({
      2301: {
        id: '2301',
        name: 'Assignment 1',
        published: true,
        peer_review_sub_assignment: {
          id: '2305',
          name: 'Peer Review 1',
        },
      },
      2302: {
        id: '2302',
        name: 'Assignment 2',
        published: true,
        peer_review_sub_assignment: {
          id: '2306',
          name: 'Peer Review 2',
        },
      },
      2303: {
        id: '2303',
        name: 'Assignment 3',
        published: true,
      },
      2305: {
        id: '2305',
        name: 'Peer Review 1',
        published: true,
        parent_assignment_id: '2301',
      },
      2306: {
        id: '2306',
        name: 'Peer Review 2',
        published: true,
        parent_assignment_id: '2302',
      },
    })
    gradebook.updateFilterAssignmentIds()
    expect(gradebook.filteredAssignmentIds).toEqual(['2301', '2305', '2302', '2306', '2303'])
  })

  it('does not add peer review sub assignments if they are not in filtered assignments', () => {
    gradebook.setAssignments({
      2301: {
        id: '2301',
        name: 'Assignment 1',
        published: true,
        peer_review_sub_assignment: {
          id: '2305',
          name: 'Peer Review 1',
        },
      },
      2305: {
        id: '2305',
        name: 'Peer Review 1',
        published: false,
        parent_assignment_id: '2301',
      },
    })
    vi.spyOn(gradebook, 'filterAssignments').mockReturnValue([
      {
        id: '2301',
        name: 'Assignment 1',
        published: true,
        peer_review_sub_assignment: {
          id: '2305',
          name: 'Peer Review 1',
        },
      },
    ])
    gradebook.updateFilterAssignmentIds()
    expect(gradebook.filteredAssignmentIds).toEqual(['2301'])
  })
})

describe('Gradebook#gotGradingPeriodAssignments', () => {
  it('sets the grading period assignments', () => {
    const gradebook = createGradebook()
    const gradingPeriodAssignments = {1: [12, 7, 4], 8: [6, 2, 9]}
    const fakeResponse = {grading_period_assignments: gradingPeriodAssignments}
    gradebook.gotGradingPeriodAssignments(fakeResponse)
    expect(gradebook.courseContent.gradingPeriodAssignments).toEqual(gradingPeriodAssignments)
  })
})

describe('Gradebook#updateStudentHeadersAndReloadData', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
  })

  it('makes a call to update column headers', () => {
    const updateColumnHeaders = vi.spyOn(
      gradebook.gradebookGrid.gridSupport.columns,
      'updateColumnHeaders',
    )
    gradebook.updateStudentHeadersAndReloadData()
    expect(updateColumnHeaders).toHaveBeenCalledTimes(1)
  })

  it('updates the student column header', () => {
    const updateColumnHeaders = vi.spyOn(
      gradebook.gradebookGrid.gridSupport.columns,
      'updateColumnHeaders',
    )
    gradebook.updateStudentHeadersAndReloadData()
    const [columnHeadersToUpdate] = updateColumnHeaders.mock.calls[0]
    expect(columnHeadersToUpdate).toEqual(['student'])
  })
})

describe('Gradebook#gotCustomColumnDataChunk', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    gradebook.students = {
      1101: {id: '1101', assignment_201: {}, assignment_202: {}},
      1102: {id: '1102', assignment_201: {}},
    }
    vi.spyOn(gradebook, 'invalidateRowsForStudentIds')
  })

  it('updates students with custom column data', () => {
    const data = [
      {user_id: '1101', content: 'example'},
      {user_id: '1102', content: 'sample'},
    ]
    gradebook.gotCustomColumnDataChunk('2401', data)
    expect(gradebook.students[1101].custom_col_2401).toBe('example')
    expect(gradebook.students[1102].custom_col_2401).toBe('sample')
  })

  it('invalidates rows for related students', () => {
    const data = [
      {user_id: '1101', content: 'example'},
      {user_id: '1102', content: 'sample'},
    ]
    gradebook.gotCustomColumnDataChunk('2401', data)
    expect(gradebook.invalidateRowsForStudentIds).toHaveBeenCalledTimes(1)
    const [studentIds] = gradebook.invalidateRowsForStudentIds.mock.calls[0]
    expect(studentIds).toEqual(['1101', '1102'])
  })

  it('ignores students without custom column data', () => {
    const data = [{user_id: '1102', content: 'sample'}]
    gradebook.gotCustomColumnDataChunk('2401', data)
    const [studentIds] = gradebook.invalidateRowsForStudentIds.mock.calls[0]
    expect(studentIds).toEqual(['1102'])
  })

  it('invalidates rows after updating students', () => {
    const data = [
      {user_id: '1101', content: 'example'},
      {user_id: '1102', content: 'sample'},
    ]
    gradebook.invalidateRowsForStudentIds.mockImplementation(() => {
      expect(gradebook.students[1101].custom_col_2401).toBe('example')
      expect(gradebook.students[1102].custom_col_2401).toBe('sample')
    })
    gradebook.gotCustomColumnDataChunk('2401', data)
  })
})

describe('Gradebook#getStudentOrder', () => {
  it('returns the IDs of the ordered students in Gradebook', () => {
    const gradebook = createGradebook()
    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z'},
      {id: '4', sortable_name: 'A'},
      {id: '1', sortable_name: 'C'},
    ]
    expect(gradebook.getStudentOrder()).toEqual(['3', '4', '1'])
  })
})

describe('Gradebook#getAssignmentOrder', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    gradebook.gridData.columns.scrollable = [
      'assignment_2301',
      'assignment_2302',
      'assignment_2303',
      'assignment_2304',
      'Assignments',
      'Homework',
      'total_grade',
    ]

    const assignments = [
      {
        id: '2301',
        assignment_group_id: '2201',
      },
      {
        id: '2302',
        assignment_group_id: '2201',
      },
      {
        id: '2303',
        assignment_group_id: '2202',
      },
      {
        id: '2304',
        assignment_group_id: '2202',
      },
    ]

    gradebook.gotAllAssignmentGroups([
      {id: '2201', position: 1, name: 'Assignments', assignments: assignments.slice(0, 2)},
      {id: '2202', position: 2, name: 'Homework', assignments: assignments.slice(2, 4)},
    ])
  })

  it('returns the IDs of the assignments in the assignment group', () => {
    expect(gradebook.getAssignmentOrder('2201')).toEqual(['2301', '2302'])
  })

  it('returns the IDs of all assignments if no assignment group id is specified', () => {
    expect(gradebook.getAssignmentOrder()).toEqual(['2301', '2302', '2303', '2304'])
  })
})

describe('Gradebook#getGradingPeriodAssignments', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    gradebook.gotGradingPeriodAssignments({grading_period_assignments: {14: ['3', '92', '11']}})
  })

  it('returns the assignments for the given grading period', () => {
    expect(gradebook.getGradingPeriodAssignments(14)).toEqual(['3', '92', '11'])
  })

  it('returns an empty array if there are no assignments in the given period', () => {
    expect(gradebook.getGradingPeriodAssignments(23)).toEqual([])
  })
})

describe('Gradebook Assignment Student Visibility', () => {
  let gradebook
  let allStudents
  let assignments

  beforeEach(() => {
    gradebook = createGradebook()

    allStudents = [
      {
        id: '1101',
        name: 'A`dam Jone`s',
        first_name: 'A`dam',
        last_name: 'Jone`s',
        enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
        sortable_name: 'Jone`s, A`dam',
      },
      {
        id: '1102',
        name: 'Betty Ford',
        enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
      },
    ]

    assignments = [
      {
        id: '2301',
        assignment_visibility: null,
        visible_to_everyone: true,
      },
      {
        id: '2302',
        assignment_visibility: ['1102'],
        visible_to_everyone: false,
      },
    ]

    gradebook.gotAllAssignmentGroups([
      {id: '2201', position: 1, name: 'Assignments', assignments: assignments.slice(0, 1)},
      {id: '2202', position: 2, name: 'Homework', assignments: assignments.slice(1, 2)},
    ])
  })

  describe('#studentsThatCanSeeAssignment', () => {
    let saveSettingsStub

    beforeEach(() => {
      saveSettingsStub = vi
        .spyOn(gradebook, 'saveSettings')
        .mockImplementation((_context_id, gradebook_settings) =>
          Promise.resolve(gradebook_settings),
        )
    })

    afterEach(() => {
      saveSettingsStub.mockRestore()
    })

    it('does not escape the grades URL for students', () => {
      gradebook.gotChunkOfStudents(allStudents)
      const student = gradebook.studentsThatCanSeeAssignment('2301')['1101']
      expect(student.enrollments[0].grades.html_url).toBe('http://example.url/')
    })

    it('does not escape the name of the student', () => {
      gradebook.gotChunkOfStudents(allStudents)
      const student = gradebook.studentsThatCanSeeAssignment('2301')['1101']
      expect(student.name).toBe('A`dam Jone`s')
    })

    it('does not escape the first name of the student', () => {
      gradebook.gotChunkOfStudents(allStudents)
      const student = gradebook.studentsThatCanSeeAssignment('2301')['1101']
      expect(student.first_name).toBe('A`dam')
    })

    it('does not escape the last name of the student', () => {
      gradebook.gotChunkOfStudents(allStudents)
      const student = gradebook.studentsThatCanSeeAssignment('2301')['1101']
      expect(student.last_name).toBe('Jone`s')
    })

    it('does not escape the sortable name of the student', () => {
      gradebook.gotChunkOfStudents(allStudents)
      const student = gradebook.studentsThatCanSeeAssignment('2301')['1101']
      expect(student.sortable_name).toBe('Jone`s, A`dam')
    })

    it('returns all students when the assignment is visible to everyone', () => {
      gradebook.gotChunkOfStudents(allStudents)
      const students = gradebook.studentsThatCanSeeAssignment('2301')
      expect(Object.keys(students).sort()).toEqual(['1101', '1102'])
    })

    it('returns only students with visibility when the assignment is not visible to everyone', () => {
      gradebook.gotChunkOfStudents(allStudents)
      const students = gradebook.studentsThatCanSeeAssignment('2302')
      expect(Object.keys(students)).toEqual(['1102'])
    })

    it('returns an empty collection when related students are not loaded', () => {
      gradebook.gotChunkOfStudents(allStudents.slice(0, 1))
      const students = gradebook.studentsThatCanSeeAssignment('2302')
      expect(Object.keys(students)).toEqual([])
    })

    it('returns an up-to-date collection when student data has changed', () => {
      gradebook.gotChunkOfStudents(allStudents.slice(0, 1))
      let students = gradebook.studentsThatCanSeeAssignment('2302') // first cache
      gradebook.gotChunkOfStudents(allStudents.slice(1, 2))
      students = gradebook.studentsThatCanSeeAssignment('2302') // re-cache
      expect(Object.keys(students)).toEqual(['1102'])
    })

    it('includes test students', () => {
      gradebook.gotChunkOfStudents(allStudents)

      const testStudent = {
        id: '9901',
        name: 'Test Student',
        enrollments: [{type: 'StudentViewEnrollment', grades: {html_url: 'http://example.ur/'}}],
      }
      gradebook.gotChunkOfStudents([testStudent])
      const students = gradebook.studentsThatCanSeeAssignment('2301')
      expect(Object.keys(students)).toEqual(['1101', '1102', '9901'])
    })
  })

  describe('#visibleStudentsThatCanSeeAssignment', () => {
    beforeEach(() => {
      gradebook.gotChunkOfStudents(allStudents)
      gradebook.courseContent.students.setStudentIds(['1101', '1102'])
      gradebook.updateFilteredStudentIds()
    })

    it('includes students who can see the assignment when no filters are active', () => {
      const students = gradebook.visibleStudentsThatCanSeeAssignment('2302')
      expect(Object.keys(students)).toContain('1102')
    })

    it('includes students who can see the assignment and match the active filters', () => {
      gradebook.filteredStudentIds = ['1102']
      gradebook.courseContent.students.setStudentIds(['1101', '1102'])

      const students = gradebook.visibleStudentsThatCanSeeAssignment('2302')
      expect(Object.keys(students)).toContain('1102')
    })

    it('excludes students who cannot see the assignment', () => {
      const students = gradebook.visibleStudentsThatCanSeeAssignment('2302')
      expect(Object.keys(students)).not.toContain('1101')
    })

    it('excludes students who can see the assignment but do not match active filters', () => {
      gradebook.filteredStudentIds = ['1102']
      gradebook.courseContent.students.setStudentIds(['1101'])

      const students = gradebook.visibleStudentsThatCanSeeAssignment('2302')
      expect(Object.keys(students)).not.toContain('1102')
    })

    it('excludes students who can see the assignment but do not match the current search', () => {
      gradebook.filteredStudentIds = ['1101']

      const students = gradebook.visibleStudentsThatCanSeeAssignment('2302')
      expect(Object.keys(students)).not.toContain('1102')
    })
  })
})

describe('Gradebook#assignmentsLoadedForCurrentView', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
  })

  it('returns false when assignments are not loaded', () => {
    expect(gradebook.assignmentsLoadedForCurrentView()).toBe(false)
  })

  it('returns true when assignments are loaded', () => {
    gradebook.setAssignmentsLoaded()
    expect(gradebook.assignmentsLoadedForCurrentView()).toBe(true)
  })

  describe('when grading periods are used', () => {
    beforeEach(() => {
      gradebook.contentLoadStates.assignmentsLoaded = {
        all: false,
        gradingPeriod: {2: false, 14: false},
      }
      gradebook.gradingPeriodId = '14'
    })

    it('returns true when assignments are loaded for the current grading period', () => {
      gradebook.setAssignmentsLoaded(['14'])
      expect(gradebook.assignmentsLoadedForCurrentView()).toBe(true)
    })

    it('returns false when assignments are not loaded', () => {
      expect(gradebook.assignmentsLoadedForCurrentView()).toBe(false)
    })

    it('returns false when assignments are loaded, but not for the current grading period', () => {
      gradebook.setAssignmentsLoaded(['2'])
      expect(gradebook.assignmentsLoadedForCurrentView()).toBe(false)
    })
  })
})
