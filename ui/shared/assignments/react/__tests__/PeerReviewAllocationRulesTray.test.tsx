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
import {render, screen, waitFor, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import PeerReviewAllocationRulesTray from '../PeerReviewAllocationRulesTray'
import {AllocationRuleType} from '@canvas/assignments/graphql/teacher/AssignmentTeacherTypes'
import {executeQuery} from '@canvas/graphql'

vi.mock('../images/pandasBalloon.svg', () => ({default: 'mock-pandas-balloon.svg'}))
vi.mock('@canvas/graphql', () => ({
  executeQuery: vi.fn(),
}))
vi.mock('../peerReviewConstants', async importOriginal => {
  const actual = await importOriginal<typeof import('../peerReviewConstants')>()
  return {
    ...actual,
    SEARCH_DEBOUNCE_DELAY: 0,
    SEARCH_RESULT_ANNOUNCEMENT_DELAY: 0,
  }
})
vi.mock('../AllocationRuleCard', () => {
  return {
    default: function MockAllocationRuleCard({rule}: {rule: any}) {
      return <div data-testid="allocation-rule-card">{rule.id}</div>
    },
  }
})
vi.mock('../CreateEditAllocationRuleModal', () => {
  return {
    default: function MockCreateEditAllocationRuleModal({isOpen}: {isOpen: boolean}) {
      return isOpen ? <div data-testid="create-rule-modal">Modal</div> : null
    },
  }
})

const mockExecuteQuery = vi.mocked(executeQuery)

const mockAllocationRules: AllocationRuleType[] = [
  {
    _id: '1',
    mustReview: true,
    reviewPermitted: true,
    appliesToAssessor: true,
    assessor: {
      _id: 'assessor-1',
      name: 'John Smith',
      peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
    },
    assessee: {
      _id: 'assessee-1',
      name: 'Jane Doe',
      peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
    },
  },
  {
    _id: '2',
    mustReview: false,
    reviewPermitted: true,
    appliesToAssessor: false,
    assessor: {
      _id: 'assessor-2',
      name: 'Bob Johnson',
      peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
    },
    assessee: {
      _id: 'assessee-2',
      name: 'Alice Brown',
      peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
    },
  },
  {
    _id: '3',
    mustReview: true,
    reviewPermitted: false,
    appliesToAssessor: true,
    assessor: {
      _id: 'assessor-3',
      name: 'Charlie Wilson',
      peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
    },
    assessee: {
      _id: 'assessee-3',
      name: 'Diana Prince',
      peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
    },
  },
]

describe('PeerReviewAllocationRulesTray', () => {
  const defaultProps = {
    assignmentId: '456',
    requiredPeerReviewsCount: 2,
    isTrayOpen: true,
    closeTray: vi.fn(),
    canEdit: false,
  }

  let user: ReturnType<typeof userEvent.setup>

  beforeEach(() => {
    user = userEvent.setup()
    vi.clearAllMocks()
    ENV.COURSE_ID = '1'

    Object.defineProperty(HTMLElement.prototype, 'clientHeight', {
      configurable: true,
      value: 600,
    })

    global.ResizeObserver = vi.fn().mockImplementation(() => ({
      observe: vi.fn(),
      unobserve: vi.fn(),
      disconnect: vi.fn(),
    }))
  })

  const renderWithQueryClient = (ui: React.ReactElement) => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    return render(<MockedQueryClientProvider client={queryClient}>{ui}</MockedQueryClientProvider>)
  }

  describe('Tray visibility', () => {
    it('renders the tray when isTrayOpen is true', async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: [],
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 0,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      expect(screen.getByTestId('allocation-rules-tray')).toBeInTheDocument()

      await waitFor(() => {
        expect(screen.getByText('Allocation Rules')).toBeInTheDocument()
      })
    })

    it('does not render tray content when isTrayOpen is false', () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: [],
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 0,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} isTrayOpen={false} />)

      expect(screen.getByTestId('allocation-rules-tray')).toBeInTheDocument()
      expect(screen.queryByText('Allocation Rules')).not.toBeInTheDocument()
    })
  })

  describe('Header section', () => {
    beforeEach(async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: [],
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 0,
          },
        },
      })
      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)
      await waitFor(() => {
        expect(screen.getByText('Allocation Rules')).toBeInTheDocument()
      })
    })

    it('displays the correct heading', () => {
      expect(screen.getByText('Allocation Rules')).toBeInTheDocument()
    })

    it('calls closeTray when close button is clicked', async () => {
      const closeButtonWrapper = screen.getByTestId('allocation-rules-tray-close-button')
      const closeButton = closeButtonWrapper.querySelector('button')

      if (closeButton) {
        await user.click(closeButton)
      }

      expect(defaultProps.closeTray).toHaveBeenCalledTimes(1)
    })
  })

  describe('Navigation section', () => {
    beforeEach(async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: [],
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 0,
          },
        },
      })
      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)
      await waitFor(() => {
        expect(screen.getByText('Allocation Rules')).toBeInTheDocument()
      })
    })

    it('displays navigation text', () => {
      expect(screen.getByText(/For peer review configuration return to/)).toBeInTheDocument()
    })

    it('renders Edit Assignment link with correct href', () => {
      const editLink = screen.getByText('Edit Assignment')
      expect(editLink).toBeInTheDocument()
      expect(editLink.closest('a')).toHaveAttribute(
        'href',
        `/courses/${ENV.COURSE_ID}/assignments/${defaultProps.assignmentId}/edit?scrollTo=assignment_peer_reviews_fields`,
      )
    })
  })

  describe('Add Rule section', () => {
    it('renders the Add Rule button if canEdit is true', async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: [],
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 0,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} canEdit={true} />)

      await waitFor(() => {
        const addRuleButton = screen.getByText('+ Rule')
        expect(addRuleButton).toBeInTheDocument()
        expect(addRuleButton.closest('button')).toBeInTheDocument()
      })
    })

    it('Add Rule button is not rendered when canEdit is false', async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: [],
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 0,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Create New Rules')).toBeInTheDocument()
      })

      const addRuleButton = screen.queryByText('+ Rule')
      expect(addRuleButton).not.toBeInTheDocument()
    })
  })

  describe('Empty state', () => {
    beforeEach(async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: [],
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 0,
          },
        },
      })
      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)
      await waitFor(() => {
        expect(screen.getByText('Create New Rules')).toBeInTheDocument()
      })
    })

    it('displays empty state when no rules exist', () => {
      expect(screen.getByText('Create New Rules')).toBeInTheDocument()
    })

    it('displays empty state image', () => {
      const image = screen.getByAltText('')
      expect(image).toBeInTheDocument()
      expect(image).toHaveAttribute('src', 'mock-pandas-balloon.svg')
    })

    it('displays descriptive text about allocation', () => {
      expect(
        screen.getByText(/Allocation of peer reviews happens behind the scenes/),
      ).toBeInTheDocument()
      expect(
        screen.getByText(/You can create rules that support your learning goals/),
      ).toBeInTheDocument()
    })
  })

  describe('Loading state', () => {
    it('displays loading spinner when data is being fetched', () => {
      mockExecuteQuery.mockImplementation(() => new Promise(() => {}))

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      expect(screen.getByText('Loading allocation rules')).toBeInTheDocument()
    })
  })

  describe('Rules display and pagination', () => {
    it('displays allocation rule cards when rules exist', async () => {
      Object.defineProperty(HTMLElement.prototype, 'clientHeight', {
        configurable: true,
        get() {
          if (this.dataset?.testid === 'allocation-rule-card-wrapper') {
            return 120
          }
          return 1000
        },
      })

      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: mockAllocationRules,
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: mockAllocationRules.length,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      await waitFor(() => {
        const cards = screen.getAllByTestId('allocation-rule-card')
        expect(cards).toHaveLength(mockAllocationRules.length)
      })
    })

    it('opens create modal when Add Rule button is clicked', async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: [],
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 0,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} canEdit={true} />)

      await waitFor(() => {
        expect(screen.getByTestId('add-rule-button')).toBeInTheDocument()
      })

      await user.click(screen.getByTestId('add-rule-button'))

      expect(screen.getByTestId('create-rule-modal')).toBeInTheDocument()
    })
  })

  describe('Pagination', () => {
    beforeEach(() => {
      Object.defineProperty(HTMLElement.prototype, 'clientHeight', {
        configurable: true,
        get() {
          if (this.dataset?.testid === 'allocation-rule-card-wrapper') {
            return 120
          }
          return 240
        },
      })
    })

    it('calculates totalPages directly from totalCount and itemsPerPage', async () => {
      const rules = Array.from({length: 12}, (_, i) => ({
        _id: `rule-${i + 1}`,
        mustReview: true,
        reviewPermitted: true,
        appliesToAssessor: true,
        assessor: {
          _id: `assessor-${i + 1}`,
          name: `Assessor ${i + 1}`,
          peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
        },
        assessee: {
          _id: `assessee-${i + 1}`,
          name: `Assessee ${i + 1}`,
          peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
        },
      }))

      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: rules,
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 12,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getAllByText('Next Allocation Rules Page: Page 2')).toHaveLength(2)
      })
    })

    it('hides pagination when all rules fit on one page', async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: mockAllocationRules.slice(0, 2),
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 2,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getAllByTestId('allocation-rule-card')).toHaveLength(2)
      })

      expect(screen.queryByText('Next Allocation Rules Page: Page 2')).not.toBeInTheDocument()
    })
  })

  describe('Dynamic items per page calculation', () => {
    it('calculates items per page based on container height', async () => {
      Object.defineProperty(HTMLElement.prototype, 'clientHeight', {
        configurable: true,
        get() {
          if (this.dataset?.testid === 'allocation-rule-card-wrapper') {
            return 100
          }
          return 500
        },
      })

      const rules = Array.from({length: 10}, (_, i) => ({
        _id: `rule-${i + 1}`,
        mustReview: true,
        reviewPermitted: true,
        appliesToAssessor: true,
        assessor: {
          _id: `assessor-${i + 1}`,
          name: `Assessor ${i + 1}`,
          peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
        },
        assessee: {
          _id: `assessee-${i + 1}`,
          name: `Assessee ${i + 1}`,
          peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
        },
      }))

      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: rules,
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 10,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getAllByTestId('allocation-rule-card')).toHaveLength(5)
      })
    })
  })

  describe('Search functionality', () => {
    beforeEach(() => {
      Object.defineProperty(HTMLElement.prototype, 'clientHeight', {
        configurable: true,
        get() {
          if (this.dataset?.testid === 'allocation-rule-card-wrapper') {
            return 120
          }
          return 600
        },
      })
    })

    it('displays search input when rules exist', async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: mockAllocationRules,
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: mockAllocationRules.length,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByPlaceholderText('Type to search')).toBeInTheDocument()
      })
    })

    it('does not display search input when no rules exist and no search value', async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: [],
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 0,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Create New Rules')).toBeInTheDocument()
      })

      expect(screen.queryByPlaceholderText('Type to search')).not.toBeInTheDocument()
    })
  })

  describe('Screen reader alerts', () => {
    beforeEach(() => {
      vi.useFakeTimers()
      HTMLElement.prototype.focus = vi.fn()
    })

    afterEach(() => {
      vi.runOnlyPendingTimers()
      vi.useRealTimers()
    })

    it('renders aria-live region with correct attributes', async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: [],
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 0,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Allocation Rules')).toBeInTheDocument()
      })

      const ariaLiveRegion = screen.getByTestId('allocation-rules-tray-alert')
      expect(ariaLiveRegion).toBeInTheDocument()
      expect(ariaLiveRegion).toHaveAttribute('aria-live', 'polite')
    })

    it('initially renders with empty screen reader announcement', async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: [],
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 0,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Allocation Rules')).toBeInTheDocument()
      })

      const ariaLiveRegion = screen.getByTestId('allocation-rules-tray-alert')
      expect(ariaLiveRegion.textContent).toBe('')
    })

    it('uses polite aria-live to avoid interrupting current screen reader speech', async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: [],
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 0,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Allocation Rules')).toBeInTheDocument()
      })

      const ariaLiveRegion = screen.getByTestId('allocation-rules-tray-alert')
      expect(ariaLiveRegion).toHaveAttribute('aria-live', 'polite')
      expect(ariaLiveRegion).not.toHaveAttribute('aria-live', 'assertive')
    })

    it('clears timeout on unmount to prevent memory leaks', async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: [],
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: 0,
          },
        },
      })

      const clearTimeoutSpy = vi.spyOn(global, 'clearTimeout')

      const {unmount} = renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByText('Allocation Rules')).toBeInTheDocument()
      })

      unmount()

      expect(clearTimeoutSpy).toHaveBeenCalled()
      clearTimeoutSpy.mockRestore()
    })

    it('announces search results when search completes', async () => {
      Object.defineProperty(HTMLElement.prototype, 'clientHeight', {
        configurable: true,
        get() {
          if (this.dataset?.testid === 'allocation-rule-card-wrapper') {
            return 120
          }
          return 600
        },
      })

      let callCount = 0
      mockExecuteQuery.mockImplementation(() => {
        callCount++
        if (callCount === 1) {
          return Promise.resolve({
            assignment: {
              allocationRules: {
                rulesConnection: {
                  nodes: mockAllocationRules,
                  pageInfo: {hasNextPage: false, endCursor: null},
                },
                count: mockAllocationRules.length,
              },
            },
          })
        } else {
          return Promise.resolve({
            assignment: {
              allocationRules: {
                rulesConnection: {
                  nodes: mockAllocationRules.filter(rule => rule.assessor.name.includes('John')),
                  pageInfo: {hasNextPage: false, endCursor: null},
                },
                count: 1,
              },
            },
          })
        }
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByPlaceholderText('Type to search')).toBeInTheDocument()
      })

      const searchInput = screen.getByPlaceholderText('Type to search')
      fireEvent.change(searchInput, {target: {value: 'Jo'}})

      await waitFor(() => {
        const ariaLiveRegion = screen.getByTestId('allocation-rules-tray-alert')
        expect(ariaLiveRegion.textContent).toBe('Search Results for "Jo"')
      })
    })
  })

  describe('Accessibility - List semantics', () => {
    beforeEach(() => {
      Object.defineProperty(HTMLElement.prototype, 'clientHeight', {
        configurable: true,
        get() {
          if (this.dataset?.testid === 'allocation-rule-card-wrapper') {
            return 120
          }
          return 1000
        },
      })
    })

    it('renders rules in a list with proper role', async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: mockAllocationRules,
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: mockAllocationRules.length,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getAllByTestId('allocation-rule-card')).toHaveLength(
          mockAllocationRules.length,
        )
      })

      const list = screen.getByTestId('allocation-rules-list')
      expect(list).toBeInTheDocument()
      expect(list.tagName).toBe('UL')
    })

    it('renders each rule as a list item with descriptive aria-label', async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          allocationRules: {
            rulesConnection: {
              nodes: mockAllocationRules,
              pageInfo: {hasNextPage: false, endCursor: null},
            },
            count: mockAllocationRules.length,
          },
        },
      })

      renderWithQueryClient(<PeerReviewAllocationRulesTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getAllByTestId('allocation-rule-card')).toHaveLength(
          mockAllocationRules.length,
        )
      })

      expect(screen.getByLabelText('John Smith must review Jane Doe')).toBeInTheDocument()
      expect(
        screen.getByLabelText('Alice Brown should be reviewed by Bob Johnson'),
      ).toBeInTheDocument()
      expect(
        screen.getByLabelText('Charlie Wilson must not review Diana Prince'),
      ).toBeInTheDocument()
    })
  })
})
