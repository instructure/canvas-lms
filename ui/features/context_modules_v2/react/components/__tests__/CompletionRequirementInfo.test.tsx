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
import CompletionRequirementInfo from '../CompletionRequirementInfo'

const setUp = (
  type: string = 'must_view',
  completed: boolean = false,
  options: {minScore?: number; minPercentage?: number} = {
    minScore: undefined,
    minPercentage: undefined,
  },
) => {
  return render(
    <ContextModuleProvider {...contextModuleDefaultProps}>
      <CompletionRequirementInfo
        id="19"
        type={type}
        minScore={options.minScore}
        minPercentage={options.minPercentage}
        completed={completed}
      />
    </ContextModuleProvider>,
  )
}

describe('CompletionRequirementInfo', () => {
  describe('must_view', () => {
    it('renders', () => {
      const container = setUp('must_view')
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('View')).toBeInTheDocument()
    })

    it('renders completed', () => {
      const container = setUp('must_view', true)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Viewed')).toBeInTheDocument()
    })
  })

  describe('must_mark_done', () => {
    it('renders', () => {
      const container = setUp('must_mark_done')
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Mark done')).toBeInTheDocument()
    })

    it('renders completed', () => {
      const container = setUp('must_mark_done', true)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Marked done')).toBeInTheDocument()
    })
  })

  describe('min_score', () => {
    it('renders', () => {
      const container = setUp('min_score', false, {minScore: 80})
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Score at least 80.0')).toBeInTheDocument()
    })

    it('renders completed', () => {
      const container = setUp('min_score', true, {minScore: 80})
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Scored at least 80.0')).toBeInTheDocument()
    })
  })

  describe('min_percentage', () => {
    it('renders', () => {
      const container = setUp('min_percentage', false, {minPercentage: 80})
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Score at least 80%')).toBeInTheDocument()
    })

    it('renders completed', () => {
      const container = setUp('min_percentage', true, {minPercentage: 80})
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Scored at least 80%')).toBeInTheDocument()
    })
  })

  describe('must_contribute', () => {
    it('renders', () => {
      const container = setUp('must_contribute')
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Contribute')).toBeInTheDocument()
    })

    it('renders completed', () => {
      const container = setUp('must_contribute', true)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Contributed')).toBeInTheDocument()
    })
  })

  describe('must_submit', () => {
    it('renders', () => {
      const container = setUp('must_submit')
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Submit')).toBeInTheDocument()
    })

    it('renders completed', () => {
      const container = setUp('must_submit', true)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Submitted')).toBeInTheDocument()
    })
  })
})
