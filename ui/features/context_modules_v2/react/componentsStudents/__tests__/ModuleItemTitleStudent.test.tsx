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
import {render} from '@testing-library/react'
import ModuleItemTitleStudent, {ModuleItemTitleStudentProps} from '../ModuleItemTitleStudent'
import {ModuleItemContent, ModuleProgression, CompletionRequirement} from '../../utils/types'

const buildDefaultProps = (overrides: Partial<ModuleItemTitleStudentProps> = {}) => {
  const defaultProps = {
    content: {
      title: 'Test Title',
      type: 'Assignment',
      isNewQuiz: false,
      published: true,
    } as ModuleItemContent,
    progression: {
      _id: '1',
      id: '1',
      workflowState: 'active',
      locked: false,
      currentPosition: 1,
      requirementsMet: [],
      completed: false,
      unlocked: true,
      started: false,
    } as ModuleProgression,
    position: 1,
    requireSequentialProgress: false,
    url: 'https://canvas.instructure.com',
    onClick: () => {},
    completionRequirements: [] as CompletionRequirement[],
  }

  return Object.assign({}, defaultProps, overrides)
}

const setUp = (props: ModuleItemTitleStudentProps) => {
  return render(<ModuleItemTitleStudent {...props} />)
}

describe('ModuleItemTitleStudent', () => {
  it('renders basic text', () => {
    const container = setUp(buildDefaultProps())
    expect(container.getByTestId('module-item-title')).toBeInTheDocument()
  })

  it('renders locked text', () => {
    const container = setUp(
      buildDefaultProps({
        progression: {
          locked: true,
          id: '1',
          _id: '1',
          workflowState: 'locked',
          requirementsMet: [],
          completed: false,
          unlocked: false,
          started: false,
        },
      }),
    )
    expect(container.getByTestId('module-item-title-locked')).toBeInTheDocument()
  })

  it('renders subheader text', () => {
    const container = setUp(
      buildDefaultProps({
        content: {
          type: 'SubHeader',
          title: 'Test SubHeader',
        },
      }),
    )
    expect(container.getByTestId('subheader-title-text')).toBeInTheDocument()
  })
})
