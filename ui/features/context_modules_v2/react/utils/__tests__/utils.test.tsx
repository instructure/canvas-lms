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
import {
  getItemIcon,
  validateModuleStudentRenderRequirements,
  validateModuleItemStudentRenderRequirements,
  getIconColor,
  getItemTypeText,
} from '../utils'

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

    it('should return the correct icon for a new quiz', () => {
      const container = render(
        getItemIcon({type: 'Assignment', title: 'New Quiz', isNewQuiz: true}),
      )
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('new-quiz-icon')).toBeInTheDocument()
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

  describe('getItemTypeText', () => {
    it('should return "Assignment" for an assignment', () => {
      expect(getItemTypeText({type: 'Assignment', title: 'Assignment'})).toBe('Assignment')
    })

    it('should return "New Quiz" for a new quiz', () => {
      expect(getItemTypeText({type: 'Assignment', title: 'New Quiz', isNewQuiz: true})).toBe(
        'New Quiz',
      )
    })

    it('should return "Quiz" for a quiz', () => {
      expect(getItemTypeText({type: 'Quiz', title: 'Quiz'})).toBe('Quiz')
    })

    it('should return "Discussion" for a discussion', () => {
      expect(getItemTypeText({type: 'Discussion', title: 'Discussion'})).toBe('Discussion')
    })

    it('should return "File" for a file', () => {
      expect(getItemTypeText({type: 'File', title: 'File'})).toBe('File')
    })

    it('should return "File" for an attachment', () => {
      expect(getItemTypeText({type: 'Attachment', title: 'Attachment'})).toBe('File')
    })

    it('should return "External Url" for an external URL', () => {
      expect(getItemTypeText({type: 'ExternalUrl', title: 'ExternalUrl'})).toBe('External Url')
    })

    it('should return "Page" for a page', () => {
      expect(getItemTypeText({type: 'Page', title: 'Page'})).toBe('Page')
    })

    it('should return "Unknown" for an unknown type', () => {
      expect(getItemTypeText({type: 'unknown' as any, title: 'Unknown'})).toBe('Unknown')
    })

    it('should return "Unknown" on missing content', () => {
      expect(getItemTypeText(null)).toBe('Unknown')
    })
  })

  describe('validateModuleStudentRenderRequirements', () => {
    const defaultProps = {
      id: '1',
      url: 'https://example.com',
      indent: 0,
      index: 0,
      content: {
        id: '1',
        type: 'Assignment',
        title: 'Assignment',
      },
    }
    it('should return true when the props are the same', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
      }
      expect(validateModuleStudentRenderRequirements(prevProps, nextProps)).toBe(true)
    })

    it('should return false when the props are different - id', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        id: '2',
      }
      expect(validateModuleStudentRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - expanded', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        expanded: false,
      }
      expect(validateModuleStudentRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - name', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        name: 'Module 2',
      }
      expect(validateModuleStudentRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - completionRequirements', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        completionRequirements: [],
      }
      expect(validateModuleStudentRenderRequirements(prevProps, nextProps)).toBe(false)
    })
  })

  describe('validateModuleItemStudentRenderRequirements', () => {
    const defaultProps = {
      id: '1',
      url: 'https://example.com',
      indent: 0,
      index: 0,
      content: {
        id: '1',
        type: 'Assignment',
        title: 'Assignment',
      },
    }
    it('should return true when the props are the same', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
      }
      expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(true)
    })

    it('should return false when the props are different - id', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        id: '2',
      }
      expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - url', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        url: 'https://example.com/2',
      }
      expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - indent', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        indent: 1,
      }
      expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - index', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        index: 1,
      }
      expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - content', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        content: {
          ...defaultProps.content,
          id: '2',
        },
      }
      expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false)
    })
  })
})
