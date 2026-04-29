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
import {MediaRecordingSubmissionDisplay} from '../MediaRecordingSubmissionDisplay'
import type {MediaObject} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

vi.mock('@canvas/canvas-studio-player', () => ({
  default: () => <div data-testid="canvas-studio-player" />,
}))

describe('MediaRecordingSubmissionDisplay', () => {
  const createMediaObject = (overrides: Partial<MediaObject> = {}): MediaObject => ({
    _id: 'media-123',
    mediaType: 'video',
    title: 'Test Video Recording',
    ...overrides,
  })

  describe('rendering', () => {
    it('renders container with correct data-testid', () => {
      render(<MediaRecordingSubmissionDisplay mediaObject={createMediaObject()} />)

      expect(screen.getByTestId('media-recording-submission-display')).toBeInTheDocument()
    })

    it('renders media recording element', () => {
      render(<MediaRecordingSubmissionDisplay mediaObject={createMediaObject()} />)

      expect(screen.getByTestId('media-recording')).toBeInTheDocument()
    })

    it('renders CanvasStudioPlayer', () => {
      render(<MediaRecordingSubmissionDisplay mediaObject={createMediaObject()} />)

      expect(screen.getByTestId('canvas-studio-player')).toBeInTheDocument()
    })

    it('displays the title when provided', () => {
      render(
        <MediaRecordingSubmissionDisplay mediaObject={createMediaObject({title: 'My Video'})} />,
      )

      expect(screen.getByTitle('My Video')).toBeInTheDocument()
    })

    it('does not display title section when title is null', () => {
      render(<MediaRecordingSubmissionDisplay mediaObject={createMediaObject({title: null})} />)

      expect(screen.queryByText('Test Video Recording')).not.toBeInTheDocument()
    })
  })
})
