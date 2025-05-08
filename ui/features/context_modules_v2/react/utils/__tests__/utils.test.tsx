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

import {render} from '@testing-library/react'
import {getItemIcon, getIconColor} from '../utils'

describe('utils', () => {
  describe('getIconColor', () => {
    it('should return success color for published content', () => {
      expect(getIconColor(true)).toBe('success')
    })

    it('should return primary color for unpublished content', () => {
      expect(getIconColor(false)).toBe('primary')
    })

    it('should return primary color for student view even when published', () => {
      expect(getIconColor(true, true)).toBe('primary')
    })
  })

  describe('getItemIcon', () => {
    it('should return the correct icon for an assignment', () => {
      const container = render(getItemIcon({type: 'Assignment', title: 'Assignment'}))
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('assignment-icon')).toBeInTheDocument()
    })

    it('should return the correct icon for a quiz', () => {
      const container = render(getItemIcon({type: 'Quiz', title: 'Quiz'}))
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('quiz-icon')).toBeInTheDocument()
    })

    it('should return the correct icon for a discussion', () => {
      const container = render(getItemIcon({type: 'Discussion', title: 'Discussion'}))
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('discussion-icon')).toBeInTheDocument()
    })

    it('should return the correct icon for a file', () => {
      const container = render(getItemIcon({type: 'File', title: 'File'}))
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('attachment-icon')).toBeInTheDocument()
    })

    it('should return the correct icon for a attachment', () => {
      const container = render(getItemIcon({type: 'Attachment', title: 'File'}))
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('attachment-icon')).toBeInTheDocument()
    })

    it('should return the correct icon for an external URL', () => {
      const container = render(getItemIcon({type: 'ExternalUrl', title: 'ExternalUrl'}))
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('url-icon')).toBeInTheDocument()
    })

    it('should return the correct icon for a page', () => {
      const container = render(getItemIcon({type: 'Page', title: 'Page'}))
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('page-icon')).toBeInTheDocument()
    })

    it('should return the correct icon for an unknown type (default icon)', () => {
      const container = render(getItemIcon({type: 'unknown' as any, title: 'Unknown'}))
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('document-icon')).toBeInTheDocument()
    })
  })
})
