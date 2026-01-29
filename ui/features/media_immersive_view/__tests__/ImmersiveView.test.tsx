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

import {render, screen} from '@testing-library/react'
import {ImmersiveView} from '../ImmersiveView'
import {vi} from 'vitest'

// Mock react-use's useMedia hook
vi.mock('react-use', () => ({
  useMedia: vi.fn(() => false), // Default to desktop
}))

// Mock CanvasStudioPlayer - this is a complex external component
vi.mock('@canvas/canvas-studio-player', () => ({
  default: () => <div data-testid="canvas-studio-player">Player</div>,
}))

describe('ImmersiveView', () => {
  const defaultProps = {
    id: 'test-media-id',
    title: 'Test Media Title',
    attachmentId: 'test-attachment-id',
    isAttachment: false,
  }

  beforeEach(() => {
    // Reset URL before each test
    delete (window as any).location
    window.location = {search: ''} as Location
  })

  describe('Header visibility', () => {
    describe('when custom_embed_hide_header is not set', () => {
      beforeEach(() => {
        window.location = {search: ''} as Location
      })

      it('displays the header', () => {
        render(<ImmersiveView {...defaultProps} />)

        expect(screen.getByText(defaultProps.title)).toBeInTheDocument()
        expect(screen.getByText('Go Back to Course')).toBeInTheDocument()
      })
    })

    describe('when custom_embed_hide_header is false', () => {
      beforeEach(() => {
        window.location = {search: '?custom_embed_hide_header=false'} as Location
      })

      it('displays the header', () => {
        render(<ImmersiveView {...defaultProps} />)

        expect(screen.getByText(defaultProps.title)).toBeInTheDocument()
        expect(screen.getByText('Go Back to Course')).toBeInTheDocument()
      })
    })

    describe('when custom_embed_hide_header is true', () => {
      beforeEach(() => {
        window.location = {search: '?custom_embed_hide_header=true'} as Location
      })

      it('hides the header', () => {
        render(<ImmersiveView {...defaultProps} />)

        expect(screen.queryByText(defaultProps.title)).not.toBeInTheDocument()
        expect(screen.queryByText('Go Back to Course')).not.toBeInTheDocument()
      })

      it('still renders the player', () => {
        render(<ImmersiveView {...defaultProps} />)

        expect(screen.getByTestId('canvas-studio-player')).toBeInTheDocument()
      })
    })

    describe('when custom_embed_hide_header is true with other params', () => {
      beforeEach(() => {
        window.location = {
          search: '?foo=bar&custom_embed_hide_header=true&baz=qux',
        } as Location
      })

      it('hides the header', () => {
        render(<ImmersiveView {...defaultProps} />)

        expect(screen.queryByText(defaultProps.title)).not.toBeInTheDocument()
        expect(screen.queryByText('Go Back to Course')).not.toBeInTheDocument()
      })
    })
  })
})
