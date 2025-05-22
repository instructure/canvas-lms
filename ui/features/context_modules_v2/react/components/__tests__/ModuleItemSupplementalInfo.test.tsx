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
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import ModuleItemSupplementalInfo from '../ModuleItemSupplementalInfo'
import type {ModuleItemContent, CompletionRequirement} from '../../utils/types'

const defaultCompletionRequirement: CompletionRequirement = {
  id: '19',
  type: 'must_view',
  completed: false,
}

const currentDate = new Date().toISOString()
const defaultContent: ModuleItemContent = {
  id: '19',
  title: 'Test Module Item',
  dueAt: currentDate,
  pointsPossible: 100,
}

const setUp = (
  content: ModuleItemContent = defaultContent,
  completionRequirement: CompletionRequirement | null = defaultCompletionRequirement,
) => {
  return render(
    <ContextModuleProvider {...contextModuleDefaultProps}>
      <ModuleItemSupplementalInfo
        content={content}
        completionRequirement={completionRequirement ?? undefined}
        contentTagId="19"
      />
    </ContextModuleProvider>,
  )
}

describe('ModuleItemSupplementalInfo', () => {
  it('renders', () => {
    const container = setUp()
    expect(container.container).toBeInTheDocument()
    expect(container.getAllByText('|')).toHaveLength(2)
  })

  it('does not render', () => {
    const container = setUp({...defaultContent, dueAt: undefined, pointsPossible: undefined}, null)
    expect(container.container).toBeInTheDocument()
    expect(
      container.queryByText(new Date(currentDate).toLocaleDateString()),
    ).not.toBeInTheDocument()
    expect(container.queryAllByText('|')).toHaveLength(0)
  })

  describe('due at', () => {
    it('renders', () => {
      const container = setUp(defaultContent, null)
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('due-date')).toBeInTheDocument()
      expect(container.getAllByText('|')).toHaveLength(1)
    })

    it('does not render', () => {
      const container = setUp({...defaultContent, dueAt: undefined})
      expect(container.container).toBeInTheDocument()
      expect(
        container.queryByText(new Date(currentDate).toLocaleDateString()),
      ).not.toBeInTheDocument()
      expect(container.queryAllByText('|')).toHaveLength(1)
    })
  })

  describe('points possible', () => {
    it('renders', () => {
      const container = setUp()
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('100 pts')).toBeInTheDocument()
    })

    it('does not render', () => {
      const container = setUp({...defaultContent, pointsPossible: undefined})
      expect(container.container).toBeInTheDocument()
      expect(container.queryByText('100 pts')).not.toBeInTheDocument()
    })
  })
})
