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
import {render, screen} from '@testing-library/react'
import CommentsTrayContentWithApollo from '../CommentsTrayContentWithApollo'
import {GlobalEnv} from '@canvas/global/env/GlobalEnv'

vi.mock('@canvas/apollo-v3', () => ({
  ApolloProvider: ({children}: {children: React.ReactNode}) => (
    <div data-testid="apollo-provider">{children}</div>
  ),
  createClient: jest.fn(() => ({})),
}))

vi.mock('@canvas/assignments/react/CommentsTray', () => ({
  __esModule: true,
  default: (props: any) => <div data-testid="comments-tray">{JSON.stringify(props)}</div>,
  TrayContent: (props: any) => <div data-testid="tray-content">{JSON.stringify(props)}</div>,
}))

describe('CommentsTrayContentWithApollo', () => {
  const defaultProps = {
    submission: {id: '1', _id: '1', attempt: 1, submissionType: 'online_text_entry'},
    assignment: {
      _id: '1',
      name: 'Test Assignment',
      dueAt: null,
      description: null,
      expectsSubmission: true,
      nonDigitalSubmission: false,
      pointsPossible: 100,
      courseId: '1',
      peerReviews: null,
      submissionsConnection: null,
      assessmentRequestsForCurrentUser: null,
    },
    isPeerReviewEnabled: true,
    renderTray: false,
    closeTray: jest.fn(),
    open: false,
  }

  it('renders TrayContent when renderTray is false', () => {
    render(<CommentsTrayContentWithApollo {...defaultProps} renderTray={false} />)

    expect(screen.getByTestId('tray-content')).toBeInTheDocument()
    expect(screen.queryByTestId('comments-tray')).not.toBeInTheDocument()
  })

  it('renders CommentsTray when renderTray is true', () => {
    render(<CommentsTrayContentWithApollo {...defaultProps} renderTray={true} />)

    expect(screen.getByTestId('comments-tray')).toBeInTheDocument()
    expect(screen.queryByTestId('tray-content')).not.toBeInTheDocument()
  })

  it('wraps content with ApolloProvider', () => {
    render(<CommentsTrayContentWithApollo {...defaultProps} />)

    expect(screen.getByTestId('apollo-provider')).toBeInTheDocument()
  })

  it('passes props correctly to TrayContent', () => {
    render(<CommentsTrayContentWithApollo {...defaultProps} renderTray={false} />)

    const trayContent = screen.getByTestId('tray-content')
    const props = JSON.parse(trayContent.textContent || '{}')

    expect(props.submission._id).toBe(defaultProps.submission._id)
    expect(props.submission.attempt).toBe(defaultProps.submission.attempt)
    expect(props.assignment.courseId).toBe(defaultProps.assignment.courseId)
    expect(props.isPeerReviewEnabled).toBe(true)
    expect(props.renderTray).toBe(false)
    expect(props.open).toBe(false)
  })

  it('passes props correctly to CommentsTray', () => {
    render(<CommentsTrayContentWithApollo {...defaultProps} renderTray={true} />)

    const commentsTray = screen.getByTestId('comments-tray')
    const props = JSON.parse(commentsTray.textContent || '{}')

    expect(props.submission._id).toBe(defaultProps.submission._id)
    expect(props.submission.attempt).toBe(defaultProps.submission.attempt)
    expect(props.assignment.courseId).toBe(defaultProps.assignment.courseId)
    expect(props.isPeerReviewEnabled).toBe(true)
    expect(props.renderTray).toBe(true)
    expect(props.open).toBe(false)
  })

  it('passes closeTray callback', () => {
    const closeTray = jest.fn()
    render(<CommentsTrayContentWithApollo {...defaultProps} closeTray={closeTray} />)

    const trayContent = screen.getByTestId('tray-content')
    expect(trayContent).toBeInTheDocument()
  })

  it('passes open state', () => {
    render(<CommentsTrayContentWithApollo {...defaultProps} open={true} />)

    const trayContent = screen.getByTestId('tray-content')
    const props = JSON.parse(trayContent.textContent || '{}')

    expect(props.open).toBe(true)
  })

  describe('data formatting', () => {
    let globalEnv: GlobalEnv

    const ENV = {
      current_user: {
        id: '123',
        display_name: 'Test User',
        anonymous_id: 'anon1',
        html_url: '',
        pronouns: null,
        fake_student: false,
        avatar_is_fallback: false,
        avatar_image_url: 'http://example.com/avatar.jpg',
      },
    }

    beforeAll(() => {
      globalEnv = {...window.ENV}
    })

    beforeEach(() => {
      window.ENV = {...globalEnv, ...ENV}
    })

    it('formats submission ID as base64-encoded GraphQL global ID', () => {
      render(<CommentsTrayContentWithApollo {...defaultProps} renderTray={false} />)

      const trayContent = screen.getByTestId('tray-content')
      const props = JSON.parse(trayContent.textContent || '{}')

      const expectedId = btoa(`Submission-${defaultProps.submission._id}`)
      expect(props.submission.id).toBe(expectedId)
      expect(props.submission._id).toBe(defaultProps.submission._id)
    })

    it('adds ENV data to assignment', () => {
      render(<CommentsTrayContentWithApollo {...defaultProps} renderTray={false} />)

      const trayContent = screen.getByTestId('tray-content')
      const props = JSON.parse(trayContent.textContent || '{}')

      expect(props.assignment.env.currentUser).toEqual(window.ENV.current_user)
      expect(props.assignment.env.courseId).toBe(defaultProps.assignment.courseId)
    })

    it('formats data correctly when renderTray is true', () => {
      render(<CommentsTrayContentWithApollo {...defaultProps} renderTray={true} />)

      const commentsTray = screen.getByTestId('comments-tray')
      const props = JSON.parse(commentsTray.textContent || '{}')

      const expectedId = btoa(`Submission-${defaultProps.submission._id}`)
      expect(props.submission.id).toBe(expectedId)
      expect(props.assignment.env.courseId).toBe(defaultProps.assignment.courseId)
    })
  })
})
