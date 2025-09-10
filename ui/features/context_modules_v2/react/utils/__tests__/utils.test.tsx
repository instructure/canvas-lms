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

import {
  getItemIcon,
  validateModuleStudentRenderRequirements,
  validateModuleItemStudentRenderRequirements,
  validateModuleItemTeacherRenderRequirements,
  validateModuleTeacherRenderRequirements,
  getIconColor,
  getItemTypeText,
  filterRequirementsMet,
} from '../utils'
import {CompletionRequirement, ModuleRequirement} from '../types'
import React from 'react'
import {render, screen} from '@testing-library/react'

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
    const renderIcon = (content: any) =>
      render(<div data-testid="host">{getItemIcon(content)}</div>)

    it('returns the correct icon for an assignment', () => {
      renderIcon({type: 'Assignment'})
      expect(screen.getByTestId('assignment-icon')).toBeInTheDocument()
    })

    it('returns the correct icon for a quiz', () => {
      renderIcon({type: 'Quiz'})
      expect(screen.getByTestId('quiz-icon')).toBeInTheDocument()
    })

    it('returns the correct icon for a new quiz', () => {
      renderIcon({type: 'Assignment', isNewQuiz: true})
      expect(screen.getByTestId('new-quiz-icon')).toBeInTheDocument()
    })

    it('returns the correct icon for a discussion', () => {
      renderIcon({type: 'Discussion'})
      expect(screen.getByTestId('discussion-icon')).toBeInTheDocument()
    })

    it('returns the correct icon for a file', () => {
      renderIcon({type: 'File'})
      expect(screen.getByTestId('attachment-icon')).toBeInTheDocument()
    })

    it('returns the correct icon for an attachment', () => {
      renderIcon({type: 'Attachment'})
      expect(screen.getByTestId('attachment-icon')).toBeInTheDocument()
    })

    it('returns the correct icon for an external URL', () => {
      renderIcon({type: 'ExternalUrl'})
      expect(screen.getByTestId('url-icon')).toBeInTheDocument()
    })

    it('returns the correct icon for an external tool', () => {
      renderIcon({type: 'ModuleExternalTool'})
      expect(screen.getByTestId('url-icon')).toBeInTheDocument()
    })

    it('returns the correct icon for a page', () => {
      renderIcon({type: 'Page'})
      expect(screen.getByTestId('page-icon')).toBeInTheDocument()
    })

    it('returns the default icon for an unknown type', () => {
      renderIcon({type: 'unknown' as any})
      expect(screen.getByTestId('document-icon')).toBeInTheDocument()
    })

    it('returns null for SubHeader (renders nothing)', () => {
      const {container, queryByTestId} = renderIcon({type: 'SubHeader'})
      // host div is present, but it has no children when icon is null
      expect(screen.getByTestId('host')).toBeInTheDocument()
      expect(screen.getByTestId('host').firstChild).toBeNull()
      // sanity: no known icon testids appear
      expect(queryByTestId('document-icon')).toBeNull()
      expect(queryByTestId('attachment-icon')).toBeNull()
      expect(queryByTestId('quiz-icon')).toBeNull()
    })
  })

  describe('getItemTypeText', () => {
    it('should return "Assignment" for an assignment', () => {
      expect(getItemTypeText({type: 'Assignment'})).toBe('Assignment')
    })

    it('should return "New Quiz" for a new quiz', () => {
      expect(getItemTypeText({type: 'Assignment', isNewQuiz: true})).toBe('New Quiz')
    })

    it('should return "Quiz" for a quiz', () => {
      expect(getItemTypeText({type: 'Quiz'})).toBe('Quiz')
    })

    it('should return "Discussion" for a discussion', () => {
      expect(getItemTypeText({type: 'Discussion'})).toBe('Discussion')
    })

    it('should return "File" for a file', () => {
      expect(getItemTypeText({type: 'File'})).toBe('File')
    })

    it('should return "File" for an attachment', () => {
      expect(getItemTypeText({type: 'Attachment'})).toBe('File')
    })

    it('should return "External Url" for an external URL', () => {
      expect(getItemTypeText({type: 'ExternalUrl'})).toBe('External Url')
    })

    it('should return "Page" for a page', () => {
      expect(getItemTypeText({type: 'Page'})).toBe('Page')
    })

    it('should return "Unknown" for an unknown type', () => {
      expect(getItemTypeText({type: 'unknown' as any})).toBe('Unknown')
    })

    it('should return "Unknown" on missing content', () => {
      expect(getItemTypeText(null)).toBe('Unknown')
    })

    it('should return "External Tool" for an external tool', () => {
      expect(getItemTypeText({type: 'ModuleExternalTool'})).toBe('External Tool')
    })
  })

  describe('validateModuleStudentRenderRequirements', () => {
    const defaultProps = {
      id: '1',
      url: 'https://example.com',
      indent: 0,
      index: 0,
      title: 'Assignment',
      content: {
        id: '1',
        type: 'Assignment',
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
      title: 'Assignment',
      content: {
        id: '1',
        type: 'Assignment',
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

    describe('checkpoint comparison', () => {
      const baseContentWithCheckpoints = {
        id: '1',
        type: 'Discussion',
        title: 'Discussion with Checkpoints',
        checkpoints: [
          {
            dueAt: '2024-01-20T23:59:00Z',
            name: 'Reply to Topic',
            tag: 'reply_to_topic',
          },
          {
            dueAt: '2024-01-22T23:59:00Z',
            name: 'Required Replies',
            tag: 'reply_to_entry',
          },
        ],
      }

      it('should return true when checkpoint data is identical and other content props are same', () => {
        const prevProps = {
          ...defaultProps,
          content: baseContentWithCheckpoints,
        }
        const nextProps = {
          ...defaultProps,
          content: {...baseContentWithCheckpoints},
        }
        expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(true) // identical content data
      })

      it('should return true when content objects are the same reference (with checkpoints)', () => {
        const sharedContent = baseContentWithCheckpoints
        const prevProps = {
          ...defaultProps,
          content: sharedContent,
        }
        const nextProps = {
          ...defaultProps,
          content: sharedContent,
        }
        expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(true)
      })

      it('should return false when checkpoint due dates change', () => {
        const prevProps = {
          ...defaultProps,
          content: baseContentWithCheckpoints,
        }
        const nextProps = {
          ...defaultProps,
          content: {
            ...baseContentWithCheckpoints,
            checkpoints: [
              {
                dueAt: '2024-01-21T23:59:00Z', // different date
                name: 'Reply to Topic',
                tag: 'reply_to_topic',
              },
              {
                dueAt: '2024-01-22T23:59:00Z',
                name: 'Required Replies',
                tag: 'reply_to_entry',
              },
            ],
          },
        }
        expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false)
      })

      it('should return false when checkpoint names change', () => {
        const prevProps = {
          ...defaultProps,
          content: baseContentWithCheckpoints,
        }
        const nextProps = {
          ...defaultProps,
          content: {
            ...baseContentWithCheckpoints,
            checkpoints: [
              {
                dueAt: '2024-01-20T23:59:00Z',
                name: 'Different Name', // different name
                tag: 'reply_to_topic',
              },
              {
                dueAt: '2024-01-22T23:59:00Z',
                name: 'Required Replies',
                tag: 'reply_to_entry',
              },
            ],
          },
        }
        expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false)
      })

      it('should return false when checkpoint tags change', () => {
        const prevProps = {
          ...defaultProps,
          content: baseContentWithCheckpoints,
        }
        const nextProps = {
          ...defaultProps,
          content: {
            ...baseContentWithCheckpoints,
            checkpoints: [
              {
                dueAt: '2024-01-20T23:59:00Z',
                name: 'Reply to Topic',
                tag: 'different_tag', // different tag
              },
              {
                dueAt: '2024-01-22T23:59:00Z',
                name: 'Required Replies',
                tag: 'reply_to_entry',
              },
            ],
          },
        }
        expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false)
      })

      it('should return false when number of checkpoints changes', () => {
        const prevProps = {
          ...defaultProps,
          content: baseContentWithCheckpoints,
        }
        const nextProps = {
          ...defaultProps,
          content: {
            ...baseContentWithCheckpoints,
            checkpoints: [
              {
                dueAt: '2024-01-20T23:59:00Z',
                name: 'Reply to Topic',
                tag: 'reply_to_topic',
              },
              // removed second checkpoint
            ],
          },
        }
        expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false)
      })

      it('should return false when checkpoints are added', () => {
        const prevProps = {
          ...defaultProps,
          content: {
            ...baseContentWithCheckpoints,
            checkpoints: [],
          },
        }
        const nextProps = {
          ...defaultProps,
          content: baseContentWithCheckpoints,
        }
        expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false)
      })

      it('should return false when checkpoints are removed', () => {
        const prevProps = {
          ...defaultProps,
          content: baseContentWithCheckpoints,
        }
        const nextProps = {
          ...defaultProps,
          content: {
            ...baseContentWithCheckpoints,
            checkpoints: [],
          },
        }
        expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false)
      })

      it('should handle null/undefined checkpoints correctly', () => {
        const prevProps = {
          ...defaultProps,
          content: {
            ...baseContentWithCheckpoints,
            checkpoints: undefined,
          },
        }
        const nextProps = {
          ...defaultProps,
          content: {
            ...baseContentWithCheckpoints,
            checkpoints: null,
          },
        }
        expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false) // null vs undefined are different
      })

      it('should return false when one has checkpoints and other has null', () => {
        const prevProps = {
          ...defaultProps,
          content: {
            ...baseContentWithCheckpoints,
            checkpoints: null,
          },
        }
        const nextProps = {
          ...defaultProps,
          content: baseContentWithCheckpoints,
        }
        expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false)
      })

      it('should handle content being null/undefined', () => {
        const prevProps = {
          ...defaultProps,
          content: null,
        }
        const nextProps = {
          ...defaultProps,
          content: null,
        }
        expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(true)
      })

      it('should return false when one content is null and other has checkpoints', () => {
        const prevProps = {
          ...defaultProps,
          content: null,
        }
        const nextProps = {
          ...defaultProps,
          content: baseContentWithCheckpoints,
        }
        expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false)
      })

      it('should return false when checkpoints are same but other content properties change', () => {
        const prevProps = {
          ...defaultProps,
          content: baseContentWithCheckpoints,
        }
        const nextProps = {
          ...defaultProps,
          content: {
            ...baseContentWithCheckpoints,
            title: 'Different Title', // changed title
          },
        }
        expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(false)
      })

      it('should return true when no checkpoints exist and other content props are same', () => {
        const contentWithoutCheckpoints = {
          id: '1',
          type: 'Assignment',
          title: 'Assignment',
        }
        const prevProps = {
          ...defaultProps,
          content: contentWithoutCheckpoints,
        }
        const nextProps = {
          ...defaultProps,
          content: {...contentWithoutCheckpoints},
        }
        expect(validateModuleItemStudentRenderRequirements(prevProps, nextProps)).toBe(true)
      })
    })
  })

  describe('validateModuleTeacherRenderRequirements', () => {
    const defaultLockAt = new Date(Date.now())
    const defaultProps = {
      id: '1',
      name: 'Module',
      published: true,
      hasActiveOverrides: false,
      prerequisites: [],
      completionRequirements: [],
      requirementCount: 0,
      unlockAt: null,
      lockAt: defaultLockAt.toISOString(),
    }

    it('should return true when the props are the same', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
      }
      expect(validateModuleTeacherRenderRequirements(prevProps, nextProps)).toBe(true)
    })

    it('should return false when the props are different - id', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        id: '2',
      }
      expect(validateModuleTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - name', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        name: 'Module 2',
      }
      expect(validateModuleTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - published', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        published: false,
      }
      expect(validateModuleTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - hasActiveOverrides', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        hasActiveOverrides: true,
      }
      expect(validateModuleTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - prerequisites', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        prerequisites: ['1'],
      }
      expect(validateModuleTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - completionRequirements', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        completionRequirements: ['1'],
      }
      expect(validateModuleTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - requirementCount', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        requirementCount: 1,
      }
      expect(validateModuleTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - lockAt', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        lockAt: '2025-06-27T12:52:56-06:00',
      }
      expect(validateModuleTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })
  })

  describe('validateModuleItemTeacherRenderRequirements', () => {
    const defaultDueAt = new Date(Date.now())
    const defaultProps = {
      id: '1',
      moduleId: '1',
      published: true,
      index: 0,
      content: {
        id: '1',
        type: 'Assignment',
        title: 'Assignment',
        unlockAt: new Date(defaultDueAt.getTime() + 24 * 60 * 60 * 1000), // plus 1 day
        dueAt: new Date(defaultDueAt.getTime() + 2 * 24 * 60 * 60 * 1000), // plus 2 day
        lockAt: new Date(defaultDueAt.getTime() + 3 * 24 * 60 * 60 * 1000), // plus 3 day
      },
    }

    it('should return true when the props are the same', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(true)
    })

    it('should return false when the props are different - id', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        id: '2',
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - moduleId', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        moduleId: '2',
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - published', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        published: false,
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - index', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        index: 1,
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - content - dueAt', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        content: {
          ...defaultProps.content,
          dueAt: new Date(defaultDueAt.getTime() + 6 * 24 * 60 * 60 * 1000), // plus 6 day
        },
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - content - lockAt', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        content: {
          ...defaultProps.content,
          lockAt: new Date(defaultDueAt.getTime() + 5 * 24 * 60 * 60 * 1000), // plus 5 day
        },
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when the props are different - content - unlockAt', () => {
      const prevProps = {
        ...defaultProps,
      }
      const nextProps = {
        ...defaultProps,
        content: {
          ...defaultProps.content,
          unlockAt: new Date(defaultDueAt.getTime() + 4 * 24 * 60 * 60 * 1000), // plus 4 day
        },
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return true when completionRequirements are the same', () => {
      const completionRequirements = [
        {id: '1', type: 'must_view'},
        {id: '2', type: 'min_score', minScore: 80},
      ]
      const prevProps = {
        ...defaultProps,
        completionRequirements,
      }
      const nextProps = {
        ...defaultProps,
        completionRequirements,
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(true)
    })

    it('should return true when completionRequirements are structurally identical', () => {
      const prevProps = {
        ...defaultProps,
        completionRequirements: [
          {id: '1', type: 'must_view'},
          {id: '2', type: 'min_score', minScore: 80},
        ],
      }
      const nextProps = {
        ...defaultProps,
        completionRequirements: [
          {id: '1', type: 'must_view'},
          {id: '2', type: 'min_score', minScore: 80},
        ],
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(true)
    })

    it('should return false when completionRequirements are different - added requirement', () => {
      const prevProps = {
        ...defaultProps,
        completionRequirements: [{id: '1', type: 'must_view'}],
      }
      const nextProps = {
        ...defaultProps,
        completionRequirements: [
          {id: '1', type: 'must_view'},
          {id: '2', type: 'min_score', minScore: 80},
        ],
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when completionRequirements are different - removed requirement', () => {
      const prevProps = {
        ...defaultProps,
        completionRequirements: [
          {id: '1', type: 'must_view'},
          {id: '2', type: 'min_score', minScore: 80},
        ],
      }
      const nextProps = {
        ...defaultProps,
        completionRequirements: [{id: '1', type: 'must_view'}],
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when completionRequirements are different - changed type', () => {
      const prevProps = {
        ...defaultProps,
        completionRequirements: [{id: '1', type: 'must_view'}],
      }
      const nextProps = {
        ...defaultProps,
        completionRequirements: [{id: '1', type: 'must_submit'}],
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when completionRequirements are different - changed minScore', () => {
      const prevProps = {
        ...defaultProps,
        completionRequirements: [{id: '1', type: 'min_score', minScore: 80}],
      }
      const nextProps = {
        ...defaultProps,
        completionRequirements: [{id: '1', type: 'min_score', minScore: 90}],
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return false when one has completionRequirements and other does not', () => {
      const prevProps = {
        ...defaultProps,
        completionRequirements: undefined,
      }
      const nextProps = {
        ...defaultProps,
        completionRequirements: [{id: '1', type: 'must_view'}],
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    it('should return true when both have no completionRequirements', () => {
      const prevProps = {
        ...defaultProps,
        completionRequirements: undefined,
      }
      const nextProps = {
        ...defaultProps,
        completionRequirements: undefined,
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(true)
    })

    it('should return true when both have empty completionRequirements arrays', () => {
      const prevProps = {
        ...defaultProps,
        completionRequirements: [],
      }
      const nextProps = {
        ...defaultProps,
        completionRequirements: [],
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(true)
    })

    it('should return false when completionRequirements change from empty to populated', () => {
      const prevProps = {
        ...defaultProps,
        completionRequirements: [],
      }
      const nextProps = {
        ...defaultProps,
        completionRequirements: [{id: '1', type: 'must_view'}],
      }
      expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
    })

    describe('checkpoint comparison', () => {
      const baseContentWithCheckpoints = {
        id: '1',
        title: 'Discussion with Checkpoints',
        type: 'Discussion',
        dueAt: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(),
        lockAt: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
        unlockAt: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000).toISOString(),
        checkpoints: [
          {
            dueAt: '2024-01-20T23:59:00Z',
            name: 'Reply to Topic',
            tag: 'reply_to_topic',
          },
          {
            dueAt: '2024-01-22T23:59:00Z',
            name: 'Required Replies',
            tag: 'reply_to_entry',
          },
        ],
      }

      it('should return false when checkpoint due dates change', () => {
        const prevProps = {
          ...defaultProps,
          content: baseContentWithCheckpoints,
        }
        const nextProps = {
          ...defaultProps,
          content: {
            ...baseContentWithCheckpoints,
            checkpoints: [
              {
                dueAt: '2024-01-21T23:59:00Z', // different date
                name: 'Reply to Topic',
                tag: 'reply_to_topic',
              },
              {
                dueAt: '2024-01-22T23:59:00Z',
                name: 'Required Replies',
                tag: 'reply_to_entry',
              },
            ],
          },
        }
        expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
      })

      it('should return true when checkpoint data is identical', () => {
        const prevProps = {
          ...defaultProps,
          content: baseContentWithCheckpoints,
        }
        const nextProps = {
          ...defaultProps,
          content: baseContentWithCheckpoints,
        }
        expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(true)
      })

      it('should return false when number of checkpoints changes', () => {
        const prevProps = {
          ...defaultProps,
          content: baseContentWithCheckpoints,
        }
        const nextProps = {
          ...defaultProps,
          content: {
            ...baseContentWithCheckpoints,
            checkpoints: [baseContentWithCheckpoints.checkpoints[0]], // removed second checkpoint
          },
        }
        expect(validateModuleItemTeacherRenderRequirements(prevProps, nextProps)).toBe(false)
      })
    })
  })

  describe('filterRequirementsMet', () => {
    it('should return the correct filtered requirements', () => {
      const requirementsMet = [
        {id: '1', type: 'must_view'},
        {id: '2', type: 'must_view'},
        {id: '3', type: 'must_view'},
      ]
      const completionRequirements = [
        {id: '1', type: 'must_view'},
        {id: '2', type: 'must_view'},
      ]
      expect(filterRequirementsMet(requirementsMet, completionRequirements)).toEqual([
        {id: '1', type: 'must_view'},
        {id: '2', type: 'must_view'},
      ])
    })

    it('should return the correct filtered requirements when ids do not match', () => {
      const requirementsMet = [
        {id: '1', type: 'must_view'},
        {id: '2', type: 'must_view'},
        {id: '3', type: 'must_view'},
      ]
      const completionRequirements = [
        {id: '1', type: 'must_view'},
        {id: '2', type: 'must_view'},
      ]
      expect(filterRequirementsMet(requirementsMet, completionRequirements)).toEqual([
        {id: '1', type: 'must_view'},
        {id: '2', type: 'must_view'},
      ])
    })

    it('should return the correct filtered requirements when types do not match', () => {
      const requirementsMet = [
        {id: '1', type: 'must_view'},
        {id: '2', type: 'must_view'},
        {id: '3', type: 'must_view'},
      ]
      const completionRequirements = [
        {id: '1', type: 'must_view'},
        {id: '2', type: 'must_mark_done'},
      ]
      expect(filterRequirementsMet(requirementsMet, completionRequirements)).toEqual([
        {id: '1', type: 'must_view'},
      ])
    })

    it('should return the correct filtered requirements when scores do not match', () => {
      const requirementsMet = [
        {id: '1', type: 'must_score', minScore: 100},
        {id: '2', type: 'must_score', minScore: 80},
        {id: '3', type: 'must_score', minScore: 75},
      ]
      const completionRequirements = [
        {id: '1', type: 'must_score', minScore: 100},
        {id: '2', type: 'must_score', minScore: 100},
      ]
      expect(filterRequirementsMet(requirementsMet, completionRequirements)).toEqual([
        {id: '1', type: 'must_score', minScore: 100},
      ])
    })

    it('should return the correct filtered requirements when percentages do not match', () => {
      const requirementsMet = [
        {id: '1', type: 'min_percentage', minPercentage: 100},
        {id: '2', type: 'min_percentage', minPercentage: 80},
        {id: '3', type: 'min_percentage', minPercentage: 75},
      ]
      const completionRequirements = [
        {id: '1', type: 'min_percentage', minPercentage: 100},
        {id: '2', type: 'min_percentage', minPercentage: 100},
      ]
      expect(filterRequirementsMet(requirementsMet, completionRequirements)).toEqual([
        {id: '1', type: 'min_percentage', minPercentage: 100},
      ])
    })

    it('should return empty array when no requirements match', () => {
      const requirementsMet = [
        {id: '1', type: 'must_view'},
        {id: '2', type: 'must_view'},
        {id: '3', type: 'must_view'},
      ]
      const completionRequirements = [
        {id: '1', type: 'must_mark_done'},
        {id: '2', type: 'must_mark_done'},
      ]
      expect(filterRequirementsMet(requirementsMet, completionRequirements)).toEqual([])
    })

    it('should return empty array when no requirements are met', () => {
      const requirementsMet = [] as ModuleRequirement[]
      const completionRequirements = [
        {id: '1', type: 'must_view'},
        {id: '2', type: 'must_view'},
      ] as CompletionRequirement[]
      expect(filterRequirementsMet(requirementsMet, completionRequirements)).toEqual([])
    })

    it('should return empty array when no requirements are set', () => {
      const requirementsMet = [] as ModuleRequirement[]
      const completionRequirements = [] as CompletionRequirement[]
      expect(filterRequirementsMet(requirementsMet, completionRequirements)).toEqual([])
    })
  })
})
