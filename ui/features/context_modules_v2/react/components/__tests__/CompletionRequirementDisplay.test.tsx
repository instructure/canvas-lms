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
import {cleanup, render} from '@testing-library/react'
import CompletionRequirementDisplay from '../CompletionRequirementDisplay'
import {CompletionRequirement, ModuleItemContent} from '../../utils/types'

const defaultContent: ModuleItemContent = {
  type: 'Assignment',
  isNewQuiz: false,
}

describe('CompletionRequirementDisplay', () => {
  afterEach(() => {
    cleanup()
  })

  it('renders null if no completion requirement is provided', () => {
    const {container} = render(
      <CompletionRequirementDisplay
        completionRequirement={null as any}
        itemContent={defaultContent}
      />,
    )
    expect(container).toBeEmptyDOMElement()
  })

  it('renders nothing for unknown requirement types', () => {
    const completionRequirement: CompletionRequirement = {
      id: '1',
      type: 'unknown_type' as any,
      completed: false,
    }
    const {container} = render(
      <CompletionRequirementDisplay
        completionRequirement={completionRequirement}
        itemContent={defaultContent}
      />,
    )

    expect(container.querySelector('span')).toBeNull()
  })

  describe('when requirement is not yet completed', () => {
    it('renders min_score requirement correctly', () => {
      const completionRequirement: CompletionRequirement = {
        id: '1',
        type: 'min_score',
        minScore: 8.5,
        completed: false,
      }
      const {getByText} = render(
        <CompletionRequirementDisplay
          completionRequirement={completionRequirement}
          itemContent={defaultContent}
        />,
      )

      expect(getByText('To do:')).toBeInTheDocument()
      expect(getByText('Score at least 8.5 points')).toBeInTheDocument()
    })

    it('renders min_percentage requirement correctly', () => {
      const completionRequirement: CompletionRequirement = {
        id: '1',
        type: 'min_percentage',
        minPercentage: 85,
        completed: false,
      }
      const {getByText} = render(
        <CompletionRequirementDisplay
          completionRequirement={completionRequirement}
          itemContent={defaultContent}
        />,
      )

      expect(getByText('To do:')).toBeInTheDocument()
      expect(getByText('Score at least 85%')).toBeInTheDocument()
    })

    describe('renders must_view requirement correctly for different content types', () => {
      it('renders must_view requirement correctly for assignment', () => {
        const completionRequirement: CompletionRequirement = {
          id: '1',
          type: 'must_view',
          completed: false,
        }
        const {getByText} = render(
          <CompletionRequirementDisplay
            completionRequirement={completionRequirement}
            itemContent={defaultContent}
          />,
        )

        expect(getByText('To do:')).toBeInTheDocument()
        expect(getByText('View assignment')).toBeInTheDocument()
      })

      it('renders must_view requirement correctly for a new quiz', () => {
        const completionRequirement: CompletionRequirement = {
          id: '1',
          type: 'must_view',
          completed: false,
        }

        const content = {...defaultContent, isNewQuiz: true}
        const {getByText} = render(
          <CompletionRequirementDisplay
            completionRequirement={completionRequirement}
            itemContent={content}
          />,
        )

        expect(getByText('To do:')).toBeInTheDocument()
        expect(getByText('View new quiz')).toBeInTheDocument()
      })
    })

    it('renders muse_view requirement correctly for a file', () => {
      const completionRequirement: CompletionRequirement = {
        id: '1',
        type: 'must_view',
        completed: false,
      }

      const content: ModuleItemContent = {...defaultContent, type: 'File'}
      const {getByText} = render(
        <CompletionRequirementDisplay
          completionRequirement={completionRequirement}
          itemContent={content}
        />,
      )

      expect(getByText('To do:')).toBeInTheDocument()
      expect(getByText('View file')).toBeInTheDocument()
    })

    it('renders must_mark_done requirement correctly', () => {
      const completionRequirement: CompletionRequirement = {
        id: '1',
        type: 'must_mark_done',
        completed: false,
      }
      const {getByText} = render(
        <CompletionRequirementDisplay
          completionRequirement={completionRequirement}
          itemContent={defaultContent}
        />,
      )

      expect(getByText('To do:')).toBeInTheDocument()
      expect(getByText('Mark as done')).toBeInTheDocument()
    })

    it('renders must_contribute requirement correctly', () => {
      const completionRequirement: CompletionRequirement = {
        id: '1',
        type: 'must_contribute',
        completed: false,
      }
      const {getByText} = render(
        <CompletionRequirementDisplay
          completionRequirement={completionRequirement}
          itemContent={defaultContent}
        />,
      )

      expect(getByText('To do:')).toBeInTheDocument()
      expect(getByText('Contribute')).toBeInTheDocument()
    })

    it('renders must_submit requirement correctly', () => {
      const completionRequirement: CompletionRequirement = {
        id: '1',
        type: 'must_submit',
        completed: false,
      }
      const {getByText} = render(
        <CompletionRequirementDisplay
          completionRequirement={completionRequirement}
          itemContent={defaultContent}
        />,
      )

      expect(getByText('To do:')).toBeInTheDocument()
      expect(getByText('Submit assignment')).toBeInTheDocument()
    })
  })

  describe('when requirement is completed', () => {
    it('renders min_score requirement correctly', () => {
      const completionRequirement: CompletionRequirement = {
        id: '1',
        type: 'min_score',
        minScore: 8.5,
        completed: true,
      }
      const {getByText} = render(
        <CompletionRequirementDisplay
          completionRequirement={completionRequirement}
          itemContent={defaultContent}
        />,
      )

      expect(getByText('Scored at least 8.5 points')).toBeInTheDocument()
    })

    it('renders min_percentage requirement correctly', () => {
      const completionRequirement: CompletionRequirement = {
        id: '1',
        type: 'min_percentage',
        minPercentage: 85,
        completed: true,
      }
      const {getByText} = render(
        <CompletionRequirementDisplay
          completionRequirement={completionRequirement}
          itemContent={defaultContent}
        />,
      )

      expect(getByText('Scored at least 85%')).toBeInTheDocument()
    })

    it('renders must_view requirement correctly', () => {
      const completionRequirement: CompletionRequirement = {
        id: '1',
        type: 'must_view',
        completed: true,
      }
      const {getByText} = render(
        <CompletionRequirementDisplay
          completionRequirement={completionRequirement}
          itemContent={defaultContent}
        />,
      )

      expect(getByText('Viewed')).toBeInTheDocument()
    })

    it('renders must_mark_done requirement correctly', () => {
      const completionRequirement: CompletionRequirement = {
        id: '1',
        type: 'must_mark_done',
        completed: true,
      }
      const {getByText} = render(
        <CompletionRequirementDisplay
          completionRequirement={completionRequirement}
          itemContent={defaultContent}
        />,
      )

      expect(getByText('Marked done')).toBeInTheDocument()
    })

    it('renders must_contribute requirement correctly', () => {
      const completionRequirement: CompletionRequirement = {
        id: '1',
        type: 'must_contribute',
        completed: true,
      }
      const {getByText} = render(
        <CompletionRequirementDisplay
          completionRequirement={completionRequirement}
          itemContent={defaultContent}
        />,
      )

      expect(getByText('Contributed')).toBeInTheDocument()
    })

    it('renders must_submit requirement correctly', () => {
      const completionRequirement: CompletionRequirement = {
        id: '1',
        type: 'must_submit',
        completed: true,
      }
      const {getByText} = render(
        <CompletionRequirementDisplay
          completionRequirement={completionRequirement}
          itemContent={defaultContent}
        />,
      )

      expect(getByText('Submitted')).toBeInTheDocument()
    })
  })
})
