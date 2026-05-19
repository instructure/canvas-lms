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
import userEvent from '@testing-library/user-event'
import QuizRegradeModal from '../QuizRegradeModal'
import type {QuizRegradeModalProps} from '../QuizRegradeModal'
import {RegradeOption} from '../QuizRegradeModal.utils'

const defaultProps: QuizRegradeModalProps = {
  open: true,
  regradeDisabled: false,
  multipleAnswer: false,
  onUpdate: vi.fn(),
  onDismiss: vi.fn(),
}

const renderModal = (props: Partial<QuizRegradeModalProps> = {}) =>
  render(<QuizRegradeModal {...defaultProps} {...props} />)

describe('QuizRegradeModal', () => {
  const user = userEvent.setup({delay: 0})

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders the dialog with title "Regrade Options"', () => {
    renderModal()
    expect(screen.getByText('Regrade Options')).toBeInTheDocument()
  })

  it('renders the warning banner text', () => {
    renderModal()
    expect(
      screen.getByText(/Choose a regrade option for students who have already taken the quiz/),
    ).toBeInTheDocument()
  })

  describe('when regrade is enabled for single-answer questions', () => {
    it('renders all 4 regrade options', () => {
      renderModal()
      expect(screen.getByLabelText(/Award points for both/)).toBeInTheDocument()
      expect(screen.getByLabelText(/Only award points for the correct answer/)).toBeInTheDocument()
      expect(screen.getByLabelText(/Give everyone full credit/)).toBeInTheDocument()
      expect(screen.getByLabelText(/Update question without regrading/)).toBeInTheDocument()
    })

    it('has Update button disabled when no option is selected', () => {
      renderModal()
      expect(screen.getByText('Update').closest('button')).toBeDisabled()
    })

    it('enables Update button when an option is selected', async () => {
      renderModal()
      await user.click(screen.getByLabelText(/Give everyone full credit/))
      expect(screen.getByText('Update').closest('button')).toBeEnabled()
    })

    it('pre-selects option and enables Update when regradeOption is provided', () => {
      renderModal({regradeOption: RegradeOption.CurrentCorrectOnly})
      expect(screen.getByLabelText(/Only award points for the correct answer/)).toBeChecked()
      expect(screen.getByText('Update').closest('button')).toBeEnabled()
    })
  })

  describe('when multipleAnswer is true', () => {
    it('hides the "Award points for both" option', () => {
      renderModal({multipleAnswer: true})
      expect(screen.queryByLabelText(/Award points for both/)).not.toBeInTheDocument()
      expect(screen.getByLabelText(/Only award points for the correct answer/)).toBeInTheDocument()
      expect(screen.getByLabelText(/Give everyone full credit/)).toBeInTheDocument()
      expect(screen.getByLabelText(/Update question without regrading/)).toBeInTheDocument()
    })
  })

  describe('when regrade is disabled', () => {
    it('shows the disabled message instead of radio options', () => {
      renderModal({regradeDisabled: true})
      expect(screen.getByText(/Regrading is not allowed on this question/)).toBeInTheDocument()
      expect(screen.queryByLabelText(/Award points for both/)).not.toBeInTheDocument()
      expect(
        screen.queryByLabelText(/Only award points for the correct answer/),
      ).not.toBeInTheDocument()
    })

    it('has Update button disabled', () => {
      renderModal({regradeDisabled: true})
      expect(screen.getByText('Update').closest('button')).toBeDisabled()
    })
  })

  describe('interactions', () => {
    it('calls onDismiss when Cancel is clicked', async () => {
      const onDismiss = vi.fn()
      renderModal({onDismiss})
      await user.click(screen.getByText('Cancel').closest('button')!)
      expect(onDismiss).toHaveBeenCalledOnce()
    })

    it('calls onDismiss when Close button is clicked', async () => {
      const onDismiss = vi.fn()
      renderModal({onDismiss})
      await user.click(screen.getByText('Close').closest('button')!)
      expect(onDismiss).toHaveBeenCalledOnce()
    })

    it('calls onUpdate with selected option value when Update is clicked', async () => {
      const onUpdate = vi.fn()
      renderModal({onUpdate})
      await user.click(screen.getByLabelText(/Give everyone full credit/))
      await user.click(screen.getByText('Update').closest('button')!)
      expect(onUpdate).toHaveBeenCalledWith('full_credit')
    })

    it('calls onUpdate with pre-selected option when Update is clicked', async () => {
      const onUpdate = vi.fn()
      renderModal({onUpdate, regradeOption: RegradeOption.NoRegrade})
      await user.click(screen.getByText('Update').closest('button')!)
      expect(onUpdate).toHaveBeenCalledWith(RegradeOption.NoRegrade)
    })
  })
})
