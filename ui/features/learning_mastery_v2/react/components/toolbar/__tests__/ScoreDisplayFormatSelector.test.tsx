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
  ScoreDisplayFormatSelector,
  ScoreDisplayFormatSelectorProps,
} from '../ScoreDisplayFormatSelector'
import {ScoreDisplayFormat} from '../../../utils/constants'

describe('ScoreDisplayFormatSelector', () => {
  const defaultProps: ScoreDisplayFormatSelectorProps = {
    value: ScoreDisplayFormat.ICON_ONLY,
    onChange: vi.fn(),
  }

  it('renders all format options', () => {
    const {getByText} = render(<ScoreDisplayFormatSelector {...defaultProps} />)
    expect(getByText('Scoring')).toBeInTheDocument()
    expect(getByText('Icons Only')).toBeInTheDocument()
    expect(getByText('Icons + Descriptor')).toBeInTheDocument()
    expect(getByText('Icons + Points')).toBeInTheDocument()
  })

  it('renders the correct label for ICON_ONLY', () => {
    const {getByLabelText} = render(
      <ScoreDisplayFormatSelector {...defaultProps} value={ScoreDisplayFormat.ICON_ONLY} />,
    )
    expect(getByLabelText('Icons Only')).toBeInTheDocument()
  })

  it('renders the correct label for ICON_AND_LABEL', () => {
    const {getByLabelText} = render(
      <ScoreDisplayFormatSelector {...defaultProps} value={ScoreDisplayFormat.ICON_AND_LABEL} />,
    )
    expect(getByLabelText('Icons + Descriptor')).toBeInTheDocument()
  })

  it('renders the correct label for ICON_AND_POINTS', () => {
    const {getByLabelText} = render(
      <ScoreDisplayFormatSelector {...defaultProps} value={ScoreDisplayFormat.ICON_AND_POINTS} />,
    )
    expect(getByLabelText('Icons + Points')).toBeInTheDocument()
  })

  it('calls onChange when an option is clicked', () => {
    const onChange = vi.fn()
    const {getByLabelText} = render(
      <ScoreDisplayFormatSelector {...defaultProps} onChange={onChange} />,
    )
    getByLabelText('Icons + Descriptor').click()
    expect(onChange).toHaveBeenCalledWith(ScoreDisplayFormat.ICON_AND_LABEL)

    getByLabelText('Icons + Points').click()
    expect(onChange).toHaveBeenCalledWith(ScoreDisplayFormat.ICON_AND_POINTS)
  })

  it('checks the ICON_ONLY radio when value is ICON_ONLY', () => {
    const {getByLabelText} = render(
      <ScoreDisplayFormatSelector {...defaultProps} value={ScoreDisplayFormat.ICON_ONLY} />,
    )
    const iconOnlyRadio = getByLabelText('Icons Only') as HTMLInputElement
    expect(iconOnlyRadio.checked).toBe(true)
  })

  it('checks the ICON_AND_LABEL radio when value is ICON_AND_LABEL', () => {
    const {getByLabelText} = render(
      <ScoreDisplayFormatSelector {...defaultProps} value={ScoreDisplayFormat.ICON_AND_LABEL} />,
    )
    const iconAndLabelRadio = getByLabelText('Icons + Descriptor') as HTMLInputElement
    expect(iconAndLabelRadio.checked).toBe(true)
  })

  it('checks the ICON_AND_POINTS radio when value is ICON_AND_POINTS', () => {
    const {getByLabelText} = render(
      <ScoreDisplayFormatSelector {...defaultProps} value={ScoreDisplayFormat.ICON_AND_POINTS} />,
    )
    const iconAndPointsRadio = getByLabelText('Icons + Points') as HTMLInputElement
    expect(iconAndPointsRadio.checked).toBe(true)
  })

  it('defaults to ICON_ONLY when value is undefined', () => {
    const {getByLabelText} = render(
      <ScoreDisplayFormatSelector {...defaultProps} value={undefined} />,
    )
    const iconOnlyRadio = getByLabelText('Icons Only') as HTMLInputElement
    expect(iconOnlyRadio.checked).toBe(true)
  })
})
