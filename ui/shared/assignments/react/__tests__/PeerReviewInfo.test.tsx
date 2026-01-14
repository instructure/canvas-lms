/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {PeerReviewInfo, type PeerReviewInfoProps} from '../PeerReviewInfo'

const mockAssignmentBase = {
  id: '1',
  name: 'Test Assignment',
  due_at: '2026-02-15T23:59:59Z',
  unlock_at: '2026-01-01T00:00:00Z',
  lock_at: '2026-03-01T23:59:59Z',
  points_possible: 100,
  html_url: '/courses/1/assignments/1',
  peer_reviews: true,
  peer_review_count: 3,
}

const mockPeerReviewSubAssignment = {
  id: 'pr_1',
  tag: 'peer_review',
  points_possible: 10,
  due_at: '2026-02-20T23:59:59Z',
  unlock_at: '2026-02-15T00:00:00Z',
  lock_at: '2026-03-01T23:59:59Z',
}

describe('PeerReviewInfo', () => {
  beforeEach(() => {
    ;(global as any).ENV = {
      TIMEZONE: 'America/Denver',
    }
  })

  describe('when peer_review_sub_assignment is null', () => {
    it('renders nothing', () => {
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          peer_review_sub_assignment: null,
        },
      }

      const {container} = render(<PeerReviewInfo {...props} />)
      expect(container).toBeEmptyDOMElement()
    })
  })

  describe('AssignmentSection', () => {
    it('renders assignment label', () => {
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      expect(screen.getByText('Assignment:')).toBeInTheDocument()
    })

    it('renders assignment due date when single date', () => {
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          due_at: '2026-02-15T23:59:59Z',
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      const assignmentLabel = screen.getByText('Assignment:')
      const assignmentSection = assignmentLabel.closest('.info-section')
      expect(assignmentSection).toHaveTextContent(/Due/)
    })

    it('renders assignment points possible', () => {
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          points_possible: 100,
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      const assignmentLabel = screen.getByText('Assignment:')
      const assignmentSection = assignmentLabel.closest('.info-section')
      expect(assignmentSection).toHaveTextContent('100 pts')
    })

    it('renders "Available until" when assignment is open', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 30)

      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          unlock_at: null,
          lock_at: futureDate.toISOString(),
          availability_status: {
            status: 'open',
            date: futureDate.toISOString(),
          },
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      const assignmentLabel = screen.getByText('Assignment:')
      const assignmentSection = assignmentLabel.closest('.info-section')
      expect(assignmentSection).toHaveTextContent(/until/)
    })

    it('renders "Not available until" when assignment is pending', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 30)

      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          unlock_at: futureDate.toISOString(),
          lock_at: null,
          availability_status: {
            status: 'pending',
            date: futureDate.toISOString(),
          },
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      const assignmentLabel = screen.getByText('Assignment:')
      const assignmentSection = assignmentLabel.closest('.info-section')
      expect(assignmentSection).toHaveTextContent(/Not available until/)
    })

    it('renders "Closed" when assignment is closed', () => {
      const pastDate = new Date()
      pastDate.setDate(pastDate.getDate() - 30)

      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          unlock_at: null,
          lock_at: pastDate.toISOString(),
          availability_status: {
            status: 'closed',
            date: null,
          },
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      expect(screen.getByText('Closed')).toBeInTheDocument()
    })

    it('renders "Multiple Dates" link when assignment has multiple dates', () => {
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          all_dates: [
            {
              dueFor: 'Section A',
              dueAt: '2026-02-15T23:59:59Z',
              lockAt: '2026-03-01T23:59:59Z',
              availabilityStatus: {
                status: 'open',
                date: '2026-03-01T23:59:59Z',
              },
            },
            {
              dueFor: 'Section B',
              dueAt: '2026-02-20T23:59:59Z',
              lockAt: '2026-03-05T23:59:59Z',
              availabilityStatus: {
                status: 'open',
                date: '2026-03-05T23:59:59Z',
              },
            },
          ],
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      const links = screen.getAllByText('Multiple Dates')
      expect(links.length).toBeGreaterThanOrEqual(1)
    })

    it('renders nothing when assignment has no availability, no due date, and no points', () => {
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          unlock_at: null,
          lock_at: null,
          due_at: null,
          points_possible: null,
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      expect(screen.queryByText('Assignment:')).not.toBeInTheDocument()
    })

    it('does not render assignment points when points_possible is 0', () => {
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          points_possible: 0,
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      const assignmentLabel = screen.getByText('Assignment:')
      const assignmentSection = assignmentLabel.closest('.info-section')
      expect(assignmentSection).not.toHaveTextContent(/pts/)
    })

    it('does not render availability info when unlock_at is in the past with no lock_at and no availability_status', () => {
      const pastDate = new Date()
      pastDate.setDate(pastDate.getDate() - 30)

      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          unlock_at: pastDate.toISOString(),
          lock_at: null,
          due_at: null,
          points_possible: null,
          availability_status: undefined,
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      expect(screen.queryByText('Assignment:')).not.toBeInTheDocument()
    })
  })

  describe('PeerReviewSection', () => {
    it('renders peer review label with count', () => {
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          peer_review_count: 5,
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      expect(screen.getByText(/Peer Reviews \(5\)/)).toBeInTheDocument()
    })

    it('renders peer review due date when single date', () => {
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          peer_review_sub_assignment: {
            ...mockPeerReviewSubAssignment,
            due_at: '2026-02-20T23:59:59Z',
          },
        },
      }

      render(<PeerReviewInfo {...props} />)
      const dueDates = screen.getAllByText(/Due/)
      expect(dueDates.length).toBeGreaterThanOrEqual(1)
    })

    it('renders peer review points possible', () => {
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          peer_review_sub_assignment: {
            ...mockPeerReviewSubAssignment,
            points_possible: 10,
          },
        },
      }

      render(<PeerReviewInfo {...props} />)
      const peerReviewLabel = screen.getByText(/Peer Review/)
      const peerReviewSection = peerReviewLabel.closest('.info-section')
      expect(peerReviewSection).toHaveTextContent('10 pts')
    })

    it('renders "Available until" for peer reviews when open', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 30)

      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          peer_review_sub_assignment: {
            ...mockPeerReviewSubAssignment,
            unlock_at: null,
            lock_at: futureDate.toISOString(),
            availability_status: {
              status: 'open',
              date: futureDate.toISOString(),
            },
          },
        },
      }

      render(<PeerReviewInfo {...props} />)
      const peerReviewLabel = screen.getByText(/Peer Review/)
      const peerReviewSection = peerReviewLabel.closest('.info-section')
      expect(peerReviewSection).toHaveTextContent(/Available until/)
    })

    it('renders "Not available until" for peer reviews when pending', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 30)

      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          peer_review_sub_assignment: {
            ...mockPeerReviewSubAssignment,
            unlock_at: futureDate.toISOString(),
            lock_at: null,
            availability_status: {
              status: 'pending',
              date: futureDate.toISOString(),
            },
          },
        },
      }

      render(<PeerReviewInfo {...props} />)
      expect(screen.getByText(/Not available until/)).toBeInTheDocument()
    })

    it('renders "Multiple Dates" link for peer reviews with multiple dates', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 30)

      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          peer_review_sub_assignment: {
            ...mockPeerReviewSubAssignment,
            all_dates: [
              {
                dueFor: 'Section A',
                dueAt: '2026-02-20T23:59:59Z',
                lockAt: '2026-03-01T23:59:59Z',
                availabilityStatus: {
                  status: 'open',
                  date: '2026-03-01T23:59:59Z',
                },
              },
              {
                dueFor: 'Section B',
                dueAt: '2026-02-25T23:59:59Z',
                lockAt: '2026-03-05T23:59:59Z',
                availabilityStatus: {
                  status: 'open',
                  date: '2026-03-05T23:59:59Z',
                },
              },
            ],
          },
        },
      }

      render(<PeerReviewInfo {...props} />)
      const links = screen.getAllByText('Multiple Dates')
      expect(links.length).toBeGreaterThanOrEqual(2)
    })

    it('renders "Closed" for peer reviews when closed', () => {
      const pastDate = new Date()
      pastDate.setDate(pastDate.getDate() - 30)

      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          peer_review_sub_assignment: {
            ...mockPeerReviewSubAssignment,
            unlock_at: null,
            lock_at: pastDate.toISOString(),
            availability_status: {
              status: 'closed',
              date: null,
            },
          },
        },
      }

      render(<PeerReviewInfo {...props} />)
      const peerReviewLabel = screen.getByText(/Peer Review/)
      const peerReviewSection = peerReviewLabel.closest('.info-section')
      expect(peerReviewSection).toHaveTextContent('Closed')
    })

    it('renders nothing when peer review has no availability, no due date, and no points', () => {
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          peer_review_sub_assignment: {
            ...mockPeerReviewSubAssignment,
            unlock_at: null,
            lock_at: null,
            due_at: null,
            points_possible: null,
          },
        },
      }

      render(<PeerReviewInfo {...props} />)
      expect(screen.queryByText(/Peer Review/)).not.toBeInTheDocument()
    })

    it('does not render peer review points when points_possible is 0', () => {
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          peer_review_sub_assignment: {
            ...mockPeerReviewSubAssignment,
            points_possible: 0,
          },
        },
      }

      render(<PeerReviewInfo {...props} />)
      const peerReviewLabel = screen.getByText(/Peer Review/)
      const peerReviewSection = peerReviewLabel.closest('.info-section')
      expect(peerReviewSection).not.toHaveTextContent(/pts/)
    })
  })

  describe('Tooltip behavior', () => {
    it('shows tooltip on hover for multiple dates link', async () => {
      const user = userEvent.setup()
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          all_dates: [
            {
              dueFor: 'Section A',
              dueAt: '2026-02-15T23:59:59Z',
            },
            {
              dueFor: 'Section B',
              dueAt: '2026-02-20T23:59:59Z',
            },
          ],
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      const links = screen.getAllByText('Multiple Dates')

      await user.hover(links[0])

      const sectionAElements = screen.getAllByText('Section A')
      const sectionBElements = screen.getAllByText('Section B')
      expect(sectionAElements.length).toBeGreaterThan(0)
      expect(sectionBElements.length).toBeGreaterThan(0)
    })

    it('shows "Available" in tooltip for dates with no availability status', async () => {
      const user = userEvent.setup()
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          all_dates: [
            {
              dueFor: 'Section C',
              dueAt: '2026-02-15T23:59:59Z',
            },
            {
              dueFor: 'Section D',
              dueAt: '2026-02-16T23:59:59Z',
            },
          ],
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      const links = screen.getAllByText('Multiple Dates')

      await user.hover(links[0])

      const availableElements = screen.getAllByText('Available')
      expect(availableElements.length).toBeGreaterThan(0)
    })

    it('handles dates with null due date in tooltips', async () => {
      const user = userEvent.setup()
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          all_dates: [
            {
              dueFor: 'Section E',
              dueAt: null,
            },
            {
              dueFor: 'Section F',
              dueAt: '2026-02-16T23:59:59Z',
            },
          ],
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      const links = screen.getAllByText('Multiple Dates')
      expect(links[0]).toBeInTheDocument()

      await user.hover(links[0])

      const sectionElements = screen.getAllByText(/Section [EF]/)
      expect(sectionElements.length).toBeGreaterThan(0)
    })

    it('prevents default action when clicking Multiple Dates link without href', async () => {
      const user = userEvent.setup()
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          html_url: undefined,
          all_dates: [
            {
              dueFor: 'Section A',
              dueAt: '2026-02-15T23:59:59Z',
            },
            {
              dueFor: 'Section B',
              dueAt: '2026-02-20T23:59:59Z',
            },
          ],
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)
      const links = screen.getAllByText('Multiple Dates')
      const link = links[0] as HTMLAnchorElement

      expect(link.href).toContain('#')

      await user.click(link)
    })
  })

  describe('Integration', () => {
    it('renders both assignment and peer review sections', () => {
      const props: PeerReviewInfoProps = {
        assignment: {
          ...mockAssignmentBase,
          peer_review_sub_assignment: mockPeerReviewSubAssignment,
        },
      }

      render(<PeerReviewInfo {...props} />)

      expect(screen.getByText('Assignment:')).toBeInTheDocument()
      expect(screen.getByText(/Peer Reviews/)).toBeInTheDocument()
    })
  })
})
