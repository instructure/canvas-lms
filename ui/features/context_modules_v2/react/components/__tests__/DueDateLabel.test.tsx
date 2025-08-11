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

import React from 'react'
import {render, fireEvent, waitFor} from '@testing-library/react'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import type {ModuleItemContent} from '../../utils/types'
import {format} from '@instructure/moment-utils'
import DueDateLabel from '../DueDateLabel'

const currentDate = new Date().toISOString()
const defaultContent: ModuleItemContent = {
  id: '19',
  dueAt: currentDate,
  pointsPossible: 100,
}

const contentWithManyDueDates: ModuleItemContent = {
  ...defaultContent,
  assignmentOverrides: {
    edges: [
      {
        cursor: 'cursor',
        node: {
          set: {
            students: [
              {
                id: 'student_id_1',
              },
            ],
          },
          dueAt: new Date().addDays(-1).toISOString(), // # yesterday
        },
      },
      {
        cursor: 'cursor_2',
        node: {
          set: {
            sectionId: 'section_id',
          },
          dueAt: new Date().addDays(1).toISOString(), // # tomorrow
        },
      },
    ],
  },
}

const contentWithRedundantDueDates: ModuleItemContent = {
  ...defaultContent,
  assignmentOverrides: {
    edges: [
      {
        cursor: 'cursor',
        node: {
          set: {
            students: [
              {
                id: 'student_id_1',
              },
            ],
          },
          dueAt: currentDate,
        },
      },
    ],
  },
}

const gradedDiscussionWithAssignmentOverrides: ModuleItemContent = {
  id: '1',
  _id: '1',
  type: 'Discussion',
  graded: true,
  dueAt: '2024-01-15T23:59:59Z',
  assignment: {
    _id: 'assignment-1',
    dueAt: '2024-01-15T23:59:59Z',
    assignmentOverrides: {
      edges: [
        {
          cursor: 'MQ',
          node: {
            dueAt: '2024-01-16T23:59:59Z',
            set: {sectionId: '1'},
          },
        },
        {
          cursor: 'Mg',
          node: {
            dueAt: '2024-01-17T23:59:59Z',
            set: {sectionId: '2'},
          },
        },
      ],
    },
  },
}

const gradedDiscussionWithAssignmentBaseDuePlusOverride: ModuleItemContent = {
  id: '2',
  _id: '2',
  type: 'Discussion',
  graded: true,
  assignment: {
    _id: 'assignment-2',
    dueAt: '2024-01-15T23:59:59Z',
    assignmentOverrides: {
      edges: [
        {
          cursor: 'MQ',
          node: {
            dueAt: '2024-01-16T23:59:59Z',
            set: {
              students: [{id: '123'}],
            },
          },
        },
      ],
    },
  },
}

const assignmentWithBaseDueDateAndStudentOverride: ModuleItemContent = {
  id: '1',
  _id: '1',
  type: 'Assignment',
  graded: true,
  dueAt: '2024-01-15T23:59:59Z',
  assignmentOverrides: {
    edges: [
      {
        cursor: 'MQ',
        node: {
          dueAt: '2024-01-16T23:59:59Z',
          set: {
            students: [{id: '123'}],
          },
        },
      },
    ],
  },
}

const assignmentWithSameDueDateInOverride: ModuleItemContent = {
  id: '2',
  _id: '2',
  type: 'Assignment',
  graded: true,
  dueAt: '2024-01-15T23:59:59Z',
  assignmentOverrides: {
    edges: [
      {
        cursor: 'MQ',
        node: {
          dueAt: '2024-01-15T23:59:59Z',
          set: {
            students: [{id: '123'}],
          },
        },
      },
    ],
  },
}

const setUp = (content: ModuleItemContent = defaultContent) => {
  return render(
    <ContextModuleProvider {...contextModuleDefaultProps}>
      <DueDateLabel content={content} contentTagId="19" />
    </ContextModuleProvider>,
  )
}

describe('DueDateLabel', () => {
  describe('with single due date', () => {
    it('renders', () => {
      const container = setUp()
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('due-date')).toBeInTheDocument()
    })
  })
  describe('with multiple due dates', () => {
    it('renders', () => {
      const container = setUp(contentWithManyDueDates)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Multiple Due Dates')).toBeInTheDocument()
    })

    it('shows tooltip with details upon hover', async () => {
      const container = setUp(contentWithManyDueDates)
      const dueAtFormat = '%b %-d at %l:%M%P'
      const dueDate1 = format(
        contentWithManyDueDates.assignmentOverrides?.edges?.[0].node.dueAt,
        dueAtFormat,
      ) as string
      const dueDate2 = format(
        contentWithManyDueDates.assignmentOverrides?.edges?.[1].node.dueAt,
        dueAtFormat,
      ) as string

      fireEvent.mouseOver(container.getByText('Multiple Due Dates'))

      await waitFor(() => container.getByTestId('override-details'))

      expect(container.getByTestId('override-details')).toHaveTextContent('1 student')
      expect(container.getByTestId('override-details').textContent).toContain(dueDate1)
      expect(container.getByTestId('override-details')).toHaveTextContent('1 section')
      expect(container.getByTestId('override-details').textContent).toContain(dueDate2)
    })

    it('shows a single date when overrides are redundant', () => {
      const container = setUp(contentWithRedundantDueDates)
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('due-date')).toBeInTheDocument()
    })
  })

  describe('with discussion types', () => {
    it('shows multiple due dates for graded discussion with assignment overrides', () => {
      const container = setUp(gradedDiscussionWithAssignmentOverrides)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Multiple Due Dates')).toBeInTheDocument()
      // Should show "Multiple Due Dates" link for discussions with assignment-level overrides
      expect(container.queryByText('Multiple Due Dates')).toBeInTheDocument()
    })

    it('shows multiple due dates for graded discussion with assignment base due date plus override', () => {
      const container = setUp(gradedDiscussionWithAssignmentBaseDuePlusOverride)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Multiple Due Dates')).toBeInTheDocument()
      // Should show "Multiple Due Dates" when discussion has assignment base due date + student override
      expect(container.queryByText('Multiple Due Dates')).toBeInTheDocument()
    })

    it('shows multiple due dates for assignment with base due date and student override', () => {
      const container = setUp(assignmentWithBaseDueDateAndStudentOverride)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Multiple Due Dates')).toBeInTheDocument()
      // Should show "Multiple Due Dates" when there's a base due date + individual student override
      expect(container.queryByText('Multiple Due Dates')).toBeInTheDocument()
    })

    it('shows single date when base due date and override are the same', () => {
      const container = setUp(assignmentWithSameDueDateInOverride)
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('due-date')).toBeInTheDocument()
      expect(container.queryByText('Multiple Due Dates')).not.toBeInTheDocument()
    })

    describe('comprehensive discussion date handling', () => {
      const gradedDiscussionWithAssignmentDueAt: ModuleItemContent = {
        id: '13',
        _id: '13',
        type: 'Discussion',
        graded: true,
        assignment: {
          _id: 'assignment-13',
          dueAt: '2024-01-15T23:59:59Z',
        },
      }

      const gradedDiscussionWithCheckpointOverrides: ModuleItemContent = {
        id: '14',
        _id: '14',
        type: 'Discussion',
        graded: true,
        checkpoints: [
          {
            dueAt: '2024-01-20T23:59:59Z',
            name: 'Reply to Topic',
            tag: 'reply_to_topic',
          },
        ],
        assignment: {
          _id: 'assignment-14',
          assignmentOverrides: {
            edges: [
              {
                cursor: 'MQ',
                node: {
                  dueAt: '2024-01-21T23:59:59Z',
                  set: {sectionId: '1'},
                },
              },
            ],
          },
        },
      }

      const gradedDiscussionWithStandardizedDates: ModuleItemContent = {
        id: '15',
        _id: '15',
        type: 'Discussion',
        graded: true,
        assignedToDates: [
          {
            id: 'everyone',
            dueAt: '2024-01-15T23:59:59Z',
            title: 'Everyone',
            base: true,
          },
          {
            id: 'section-1',
            dueAt: '2024-01-16T23:59:59Z',
            title: 'Section 1',
            set: {
              id: '1',
              type: 'CourseSection',
            },
          },
        ],
      }

      beforeEach(() => {
        // Reset ENV for each test
        ENV.FEATURES = {standardize_assignment_date_formatting: false}
      })

      describe('graded discussions', () => {
        it('shows assignment.dueAt for graded discussion', () => {
          const container = setUp(gradedDiscussionWithAssignmentDueAt)
          expect(container.getByTestId('due-date')).toBeInTheDocument()
          expect(container.queryByText('Multiple Due Dates')).not.toBeInTheDocument()
        })

        it('shows single date for checkpointed discussion with overrides', () => {
          const container = setUp(gradedDiscussionWithCheckpointOverrides)
          // Checkpointed discussions show individual checkpoint dates, not "Multiple Due Dates"
          expect(container.getByTestId('due-date')).toBeInTheDocument()
          expect(container.queryByText('Multiple Due Dates')).not.toBeInTheDocument()
        })

        it('shows Multiple Due Dates for graded discussion with standardized dates', () => {
          ENV.FEATURES = {standardize_assignment_date_formatting: true}
          const container = setUp(gradedDiscussionWithStandardizedDates)
          expect(container.getByText('Multiple Due Dates')).toBeInTheDocument()
          // The tooltip contains multiple due-date elements, but the main display should not show individual dates
          expect(container.queryByText('Multiple Due Dates')).toBeInTheDocument()
        })

        it('shows single date for graded discussion with single standardized date', () => {
          ENV.FEATURES = {standardize_assignment_date_formatting: true}
          const singleDateContent = {
            ...gradedDiscussionWithStandardizedDates,
            assignedToDates: [gradedDiscussionWithStandardizedDates.assignedToDates![0]],
          }
          const container = setUp(singleDateContent)
          expect(container.getByTestId('due-date')).toBeInTheDocument()
          expect(container.queryByText('Multiple Due Dates')).not.toBeInTheDocument()
        })
      })

      describe('edge cases', () => {
        const discussionWithNullDates: ModuleItemContent = {
          id: '17',
          _id: '17',
          type: 'Discussion',
          graded: false,
          todoDate: undefined,
          lockAt: undefined,
          dueAt: undefined,
        }

        const discussionWithEmptyOverrides: ModuleItemContent = {
          id: '18',
          _id: '18',
          type: 'Discussion',
          graded: true,
          assignment: {
            _id: 'assignment-18',
            dueAt: '2024-01-15T23:59:59Z',
            assignmentOverrides: {
              edges: [],
            },
          },
        }

        const discussionWithOverridesButNoDates: ModuleItemContent = {
          id: '19',
          _id: '19',
          type: 'Discussion',
          graded: true,
          assignment: {
            _id: 'assignment-19',
            assignmentOverrides: {
              edges: [
                {
                  cursor: 'MQ',
                  node: {
                    dueAt: undefined,
                    set: {sectionId: '1'},
                  },
                },
              ],
            },
          },
        }

        it('returns null when discussion has no dates', () => {
          const container = setUp(discussionWithNullDates)
          expect(container.container.firstChild).toBeNull()
        })

        it('shows single date when discussion has empty overrides', () => {
          const container = setUp(discussionWithEmptyOverrides)
          expect(container.getByTestId('due-date')).toBeInTheDocument()
          expect(container.queryByText('Multiple Due Dates')).not.toBeInTheDocument()
        })

        it('handles overrides with no due dates gracefully', () => {
          const container = setUp(discussionWithOverridesButNoDates)
          expect(container.container.firstChild).toBeNull()
        })
      })

      describe('standardized dates feature flag', () => {
        const discussionWithBothFormats: ModuleItemContent = {
          id: '20',
          _id: '20',
          type: 'Discussion',
          graded: true,
          dueAt: '2024-01-15T23:59:59Z',
          assignment: {
            _id: 'assignment-20',
            dueAt: '2024-01-15T23:59:59Z',
            assignmentOverrides: {
              edges: [
                {
                  cursor: 'MQ',
                  node: {
                    dueAt: '2024-01-16T23:59:59Z',
                    set: {sectionId: '1'},
                  },
                },
              ],
            },
          },
          assignedToDates: [
            {
              id: 'everyone',
              dueAt: '2024-01-15T23:59:59Z',
              title: 'Everyone',
              base: true,
            },
            {
              id: 'section-1',
              dueAt: '2024-01-16T23:59:59Z',
              title: 'Section 1',
              set: {
                id: '1',
                type: 'CourseSection',
              },
            },
          ],
        }

        it('uses standardized dates when feature flag is enabled', () => {
          ENV.FEATURES = {standardize_assignment_date_formatting: true}
          const container = setUp(discussionWithBothFormats)
          expect(container.getByText('Multiple Due Dates')).toBeInTheDocument()
        })

        it('uses legacy dates when feature flag is disabled', () => {
          ENV.FEATURES = {standardize_assignment_date_formatting: false}
          const container = setUp(discussionWithBothFormats)
          expect(container.getByText('Multiple Due Dates')).toBeInTheDocument()
        })

        it('falls back to legacy when standardized dates are empty', () => {
          ENV.FEATURES = {standardize_assignment_date_formatting: true}
          const contentNoStandardized = {
            ...discussionWithBothFormats,
            assignedToDates: [],
          }
          const container = setUp(contentNoStandardized)
          expect(container.getByText('Multiple Due Dates')).toBeInTheDocument()
        })
      })
    })
  })
})
