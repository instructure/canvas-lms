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

import React from 'react'
import {render, waitFor, act} from '@testing-library/react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {GradesPage} from '../GradesPage'
import {
  MOCK_GRADING_PERIODS_EMPTY,
  MOCK_GRADING_PERIODS_NORMAL,
  MOCK_ASSIGNMENT_GROUPS,
  MOCK_ENROLLMENTS,
} from './mocks'

const server = setupServer()

beforeAll(() => {
  server.listen()
})

afterAll(() => {
  server.close()
})

const dtf = new Intl.DateTimeFormat('en', {
  // MMM D, YYYY h:mma
  weekday: 'short',
  month: 'short',
  day: 'numeric',
  year: 'numeric',
  hour: 'numeric',
  minute: 'numeric',
  timeZone: ENV.TIMEZONE,
})

const dateFormatter = d => dtf.format(d instanceof Date ? d : new Date(d))

describe('GradesPage', () => {
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

  const getProps = (overrides = {}) => ({
    courseId: '12',
    courseName: 'History',
    userIsStudent: true,
    userIsCourseAdmin: false,
    hideFinalGrades: false,
    currentUser: {
      id: '1',
    },
    showLearningMasteryGradebook: false,
    observedUserId: null,
    ...overrides,
  })

  afterEach(() => {
    server.resetHandlers()
    localStorage.clear()
  })

  describe('without grading periods', () => {
    beforeEach(() => {
      server.use(
        http.get('*/api/v1/courses/12', ({request}) => {
          const url = new URL(request.url)
          const include = url.searchParams.getAll('include[]')
          if (include.includes('grading_periods')) {
            return HttpResponse.json(MOCK_GRADING_PERIODS_EMPTY)
          }
          return HttpResponse.json({})
        }),
        http.get('*/api/v1/courses/12/assignment_groups', () => {
          return HttpResponse.json(MOCK_ASSIGNMENT_GROUPS)
        }),
        http.get('*/api/v1/courses/12/enrollments', () => {
          return HttpResponse.json(MOCK_ENROLLMENTS)
        }),
      )
    })

    it('renders loading skeletons while fetching content', async () => {
      const {getAllByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => {
        const skeletons = getAllByText('Loading grades for History')
        expect(skeletons[0]).toBeInTheDocument()
        expect(skeletons).toHaveLength(10)
      })
    })

    it('renders a flashAlert if an error happens on fetch', async () => {
      server.use(
        http.get('*/api/v1/courses/12/assignment_groups', () => {
          return new HttpResponse(null, {status: 400})
        }),
      )
      const {getAllByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() =>
        expect(getAllByText('Failed to load grade details for History')[0]).toBeInTheDocument(),
      )
    })

    it('renders a table with 4 headers', async () => {
      const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      ;['Assignment', 'Due Date', 'Assignment Group', 'Score'].forEach(header => {
        expect(getByText(header)).toBeInTheDocument()
      })
    })

    it('shows a panda and text for students with no grades', async () => {
      server.use(
        http.get('*/api/v1/courses/12/assignment_groups', () => {
          return HttpResponse.json([])
        }),
      )
      const {getByTestId, getByText, queryByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      expect(getByText("You don't have any grades yet.")).toBeInTheDocument()
      expect(getByTestId('empty-grades-panda')).toBeInTheDocument()
      ;['Assignment', 'Due Date', 'Assignment Group', 'Score'].forEach(header => {
        expect(queryByText(header)).not.toBeInTheDocument()
      })
    })

    it('shows a panda and text for users who are neither a student nor instructor', async () => {
      const {getByTestId, getByText, queryByText} = render(
        <GradesPage {...getProps({userIsStudent: false})} />,
      )
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      expect(getByText("You don't have any grades yet.")).toBeInTheDocument()
      expect(getByTestId('empty-grades-panda')).toBeInTheDocument()
    })

    it('renders the returned assignment details', async () => {
      const {queryByText, findByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      const formattedDueDate = dateFormatter('2020-04-18T05:59:59Z')

      // Wait for and verify each element individually with more flexible matchers
      await findByText('WWII Report')
      await findByText(formattedDueDate)
      await findByText('Reports')
      await findByText(/9\.5\s*pts/i)
      await findByText(/Out of 10\s*pts/i)
    })

    it('shows a panda and link to gradebook for teachers', async () => {
      const {getByText, getByTestId, getByRole, queryByText} = render(
        <GradesPage {...getProps({userIsCourseAdmin: true, userIsStudent: false})} />,
      )
      await waitFor(() => expect(getByText('Students see their grades here.')).toBeInTheDocument())
      expect(getByTestId('empty-grades-panda')).toBeInTheDocument()
      const gradebookButton = getByRole('link', {name: 'View History Gradebook'})
      expect(gradebookButton).toBeInTheDocument()
      expect(getByText('View Gradebook')).toBeInTheDocument()
      expect(gradebookButton.href).toContain('/courses/12/gradebook')
      expect(queryByText('Assignment')).not.toBeInTheDocument()
    })

    it('shows view feedback link', async () => {
      const {queryByText, getByRole} = render(<GradesPage {...getProps()} />)
      await waitFor(() => expect(queryByText('Loading grades for History')).not.toBeInTheDocument())
      const link = getByRole('link', {name: 'View feedback'})
      expect(link).toBeInTheDocument()
      expect(link.href).toBe('http://localhost/wwii-report/submissions/1')
    })

    describe('totals', () => {
      it('displays fetched course total grade', async () => {
        const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
        await waitFor(() =>
          expect(queryByText('Loading total grade for History')).not.toBeInTheDocument(),
        )
        expect(getByText('Total: 89.39%')).toBeInTheDocument()
        expect(getByText('History Total: 89.39%')).toBeInTheDocument()
      })

      it('displays fetched course total Letter Grade when Restrict Quantitative Data', async () => {
        const {getByText, queryByText} = render(
          <GradesPage
            {...getProps({gradingScheme: DEFAULT_GRADING_SCHEME, restrictQuantitativeData: true})}
          />,
        )
        await waitFor(() =>
          expect(queryByText('Loading total grade for History')).not.toBeInTheDocument(),
        )
        expect(getByText('Total: B+')).toBeInTheDocument()
        expect(getByText('History Total: B+')).toBeInTheDocument()
      })

      it('displays button to expand assignment group totals', async () => {
        const {getByText, queryByText} = render(<GradesPage {...getProps()} />)
        await waitFor(() =>
          expect(queryByText('Loading assignment group totals')).not.toBeInTheDocument(),
        )
        expect(getByText('View Assignment Group Totals')).toBeInTheDocument()
        expect(getByText("View History's Assignment Group Totals")).toBeInTheDocument()
      })

      it('displays assignment group totals when expanded', async () => {
        const {getByText, findByText, queryByText} = render(<GradesPage {...getProps()} />)
        const totalsButton = await findByText('View Assignment Group Totals')
        expect(queryByText('Reports: 95.00%')).not.toBeInTheDocument()
        act(() => totalsButton.click())
        expect(getByText('Reports: 95.00%')).toBeInTheDocument()
      })

      it('displays assignment group totals Letter Grade when expanded and Restrict Quantitative Data', async () => {
        const {getByText, findByText, queryByText} = render(
          <GradesPage
            {...getProps({gradingScheme: DEFAULT_GRADING_SCHEME, restrictQuantitativeData: true})}
          />,
        )
        const totalsButton = await findByText('View Assignment Group Totals')
        expect(queryByText('Reports: A')).not.toBeInTheDocument()
        act(() => totalsButton.click())
        expect(getByText('Reports: A')).toBeInTheDocument()
      })

      it("doesn't show any totals if hideFinalGrades is set", async () => {
        const {queryByText} = render(<GradesPage {...getProps({hideFinalGrades: true})} />)
        await waitFor(() => {
          expect(queryByText('Loading grades for History')).not.toBeInTheDocument()
          expect(queryByText('Loading total grade for History')).not.toBeInTheDocument()
        })
        expect(queryByText('Total: 89.39%')).not.toBeInTheDocument()
        expect(queryByText('Reports: 95.00%')).not.toBeInTheDocument()
      })

      it('total shows n/a if the fetched score is null', async () => {
        const enrollmentsData = [
          {
            user_id: '1',
            grades: {
              current_score: null,
            },
          },
        ]
        server.use(
          http.get('*/api/v1/courses/12/enrollments', () => {
            return HttpResponse.json(enrollmentsData)
          }),
        )
        const {findByText} = render(<GradesPage {...getProps()} />)
        expect(await findByText('Total: n/a')).toBeInTheDocument()
      })

      it('shows the grading scheme grade next to percent if course has grading scheme', async () => {
        const enrollmentsData = [
          {
            user_id: '1',
            grades: {
              current_score: 84.6,
              current_grade: 'B',
            },
          },
        ]
        server.use(
          http.get('*/api/v1/courses/12/enrollments', () => {
            return HttpResponse.json(enrollmentsData)
          }),
        )
        const {findByText} = render(<GradesPage {...getProps()} />)
        expect(await findByText('Total: 84.60% (B)')).toBeInTheDocument()
      })

      it('shows a message explaining how totals are calculated if totals are shown', async () => {
        const {findByText, getByText} = render(<GradesPage {...getProps()} />)
        expect(await findByText('Total: 89.39%')).toBeInTheDocument()
        expect(
          getByText('Totals are calculated based only on graded assignments.'),
        ).toBeInTheDocument()
      })
    })
  })

  describe('with grading periods', () => {
    beforeEach(() => {
      server.use(
        http.get('*/api/v1/courses/12', ({request}) => {
          const url = new URL(request.url)
          const include = url.searchParams.getAll('include[]')
          if (include.includes('grading_periods')) {
            return HttpResponse.json(MOCK_GRADING_PERIODS_NORMAL)
          }
          return HttpResponse.json({})
        }),
        http.get('*/api/v1/courses/12/assignment_groups', () => {
          return HttpResponse.json(MOCK_ASSIGNMENT_GROUPS)
        }),
        http.get('*/api/v1/courses/12/enrollments', () => {
          return HttpResponse.json(MOCK_ENROLLMENTS)
        }),
      )
    })

    it('shows a grading period select when grading periods are returned', async () => {
      const {getByText, findByText} = render(<GradesPage {...getProps()} />)
      const select = await findByText('Select Grading Period')
      act(() => select.click())
      expect(getByText('Quarter 1')).toBeInTheDocument()
      expect(getByText('Quarter 2 (Current)')).toBeInTheDocument()
      expect(getByText('All Grading Periods')).toBeInTheDocument()
    })

    it('shows an error if fetching fails', async () => {
      server.use(
        http.get('*/api/v1/courses/12', ({request}) => {
          const url = new URL(request.url)
          const include = url.searchParams.getAll('include[]')
          if (include.includes('grading_periods')) {
            return new HttpResponse(null, {status: 400})
          }
          return HttpResponse.json({})
        }),
      )
      const {getAllByText} = render(<GradesPage {...getProps()} />)
      await waitFor(() =>
        expect(getAllByText('Failed to load grading periods for History')[0]).toBeInTheDocument(),
      )
    })

    it('shows only assignments in current grading period', async () => {
      server.use(
        http.get('*/api/v1/courses/12/assignment_groups', ({request}) => {
          const url = new URL(request.url)
          const gradingPeriodId = url.searchParams.get('grading_period_id')
          if (gradingPeriodId === '1') {
            return HttpResponse.json([])
          }
          return HttpResponse.json(MOCK_ASSIGNMENT_GROUPS)
        }),
      )
      const {getByText, findByText, queryByText} = render(<GradesPage {...getProps()} />)
      expect(await findByText('WWII Report')).toBeInTheDocument()
      const select = getByText('Select Grading Period')
      act(() => select.click())
      act(() => getByText('Quarter 1').click())
      await waitFor(() => expect(queryByText('Loading grades for history')).not.toBeInTheDocument())
      expect(queryByText('WWII Report')).not.toBeInTheDocument()
    })

    it('hides totals on All Grading Periods if not allowed', async () => {
      const gradingPeriods = {...MOCK_GRADING_PERIODS_NORMAL}
      gradingPeriods.enrollments[0].totals_for_all_grading_periods_option = false
      server.use(
        http.get('*/api/v1/courses/12', ({request}) => {
          const url = new URL(request.url)
          const include = url.searchParams.getAll('include[]')
          if (include.includes('grading_periods')) {
            return HttpResponse.json(gradingPeriods)
          }
          return HttpResponse.json({})
        }),
      )
      const {findByText, getByText, queryByText} = render(<GradesPage {...getProps()} />)
      const select = await findByText('Select Grading Period')
      act(() => select.click())
      act(() => getByText('All Grading Periods').click())
      await waitFor(() => expect(getByText('WWII Report')).toBeInTheDocument())
      expect(queryByText('Total: 89.39%')).not.toBeInTheDocument()
      expect(queryByText('View Assignment Group Totals')).not.toBeInTheDocument()
    })

    it('waits for grading periods to load before firing other requests', async () => {
      let apiCallCount = 0
      server.use(
        http.get('*/api/v1/courses/12', ({request}) => {
          apiCallCount++
          const url = new URL(request.url)
          const include = url.searchParams.getAll('include[]')
          if (include.includes('grading_periods')) {
            return HttpResponse.json(MOCK_GRADING_PERIODS_NORMAL)
          }
          return HttpResponse.json({})
        }),
        http.get('*/api/v1/courses/12/assignment_groups', () => {
          apiCallCount++
          return HttpResponse.json(MOCK_ASSIGNMENT_GROUPS)
        }),
        http.get('*/api/v1/courses/12/enrollments', () => {
          apiCallCount++
          return HttpResponse.json(MOCK_ENROLLMENTS)
        }),
      )
      const {getByText, getAllByText} = render(<GradesPage {...getProps()} />)
      expect(getAllByText('Loading grades for History')[0]).toBeInTheDocument()
      expect(getByText('Loading total grade for History')).toBeInTheDocument()
      await waitFor(() => {
        expect(getByText('WWII Report')).toBeInTheDocument()
        expect(getByText('Total: 89.39%')).toBeInTheDocument()
      })
      expect(apiCallCount).toBe(3)
    })
  })
})
