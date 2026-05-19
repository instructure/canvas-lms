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

import {render, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import RegenerateCriteriaModal from '../RegenerateCriteriaModal'

describe('RegenerateCriteriaModal', () => {
  const defaultProps = {
    open: true,
    additionalPrompt: '',
    onClose: vi.fn(),
    onRegenerate: vi.fn(),
    onAdditionalPromptChange: vi.fn(),
  }

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('does not render when open is false', () => {
    const {queryByTestId} = render(<RegenerateCriteriaModal {...defaultProps} open={false} />)
    expect(queryByTestId('regenerate-criteria-modal-description')).not.toBeInTheDocument()
  })

  it('renders when open is true', () => {
    const {getByTestId} = render(<RegenerateCriteriaModal {...defaultProps} />)
    expect(getByTestId('regenerate-criteria-modal-description')).toBeInTheDocument()
  })

  it('shows "Regenerate Criteria" label when isCriterion is false', () => {
    const {getByText} = render(<RegenerateCriteriaModal {...defaultProps} isCriterion={false} />)
    expect(getByText('Regenerate Criteria')).toBeInTheDocument()
  })

  it('shows "Regenerate Criterion" label when isCriterion is true', () => {
    const {getByText} = render(<RegenerateCriteriaModal {...defaultProps} isCriterion={true} />)
    expect(getByText('Regenerate Criterion')).toBeInTheDocument()
  })

  it('shows criteria description text when isCriterion is false', () => {
    const {getByText} = render(<RegenerateCriteriaModal {...defaultProps} isCriterion={false} />)
    expect(
      getByText(
        'Please provide more information about how you would like to regenerate the criteria.',
      ),
    ).toBeInTheDocument()
  })

  it('shows criterion description text when isCriterion is true', () => {
    const {getByText} = render(<RegenerateCriteriaModal {...defaultProps} isCriterion={true} />)
    expect(
      getByText(
        'Please provide more information about how you would like to regenerate the criterion.',
      ),
    ).toBeInTheDocument()
  })

  it('calls onClose when cancel button is clicked', async () => {
    const user = userEvent.setup()
    const onClose = vi.fn()
    const {getByTestId} = render(<RegenerateCriteriaModal {...defaultProps} onClose={onClose} />)
    await user.click(getByTestId('regenerate-criteria-cancel-button'))
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('calls onRegenerate when submit button is clicked', async () => {
    const user = userEvent.setup()
    const onRegenerate = vi.fn()
    const {getByTestId} = render(
      <RegenerateCriteriaModal {...defaultProps} onRegenerate={onRegenerate} />,
    )
    await user.click(getByTestId('regenerate-criteria-submit-button'))
    expect(onRegenerate).toHaveBeenCalledTimes(1)
  })

  it('calls onAdditionalPromptChange when textarea value changes', () => {
    const onAdditionalPromptChange = vi.fn()
    const {getByTestId} = render(
      <RegenerateCriteriaModal
        {...defaultProps}
        onAdditionalPromptChange={onAdditionalPromptChange}
      />,
    )
    fireEvent.change(getByTestId('additional-prompt-textarea'), {target: {value: 'a'}})
    expect(onAdditionalPromptChange).toHaveBeenCalledWith('a')
  })

  it('disables submit button when additionalPrompt exceeds 1000 characters', () => {
    const {getByTestId} = render(
      <RegenerateCriteriaModal {...defaultProps} additionalPrompt={'a'.repeat(1001)} />,
    )
    expect(getByTestId('regenerate-criteria-submit-button')).toBeDisabled()
  })

  it('enables submit button when additionalPrompt is 1000 characters or fewer', () => {
    const {getByTestId} = render(
      <RegenerateCriteriaModal {...defaultProps} additionalPrompt={'a'.repeat(1000)} />,
    )
    expect(getByTestId('regenerate-criteria-submit-button')).toBeEnabled()
  })

  it('shows error message when additionalPrompt exceeds 1000 characters', () => {
    const {getByText} = render(
      <RegenerateCriteriaModal {...defaultProps} additionalPrompt={'a'.repeat(1001)} />,
    )
    expect(
      getByText('Additional prompt information must be less than 1000 characters'),
    ).toBeInTheDocument()
  })

  it('does not show error message when additionalPrompt is within limit', () => {
    const {queryByText} = render(
      <RegenerateCriteriaModal {...defaultProps} additionalPrompt={'a'.repeat(1000)} />,
    )
    expect(
      queryByText('Additional prompt information must be less than 1000 characters'),
    ).not.toBeInTheDocument()
  })
})
