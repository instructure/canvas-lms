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
import {render, screen} from '@testing-library/react'
import {ScoreWithLabel, ScoreWithLabelProps} from '../ScoreWithLabel'
import {ScoreDisplayFormat} from '@canvas/outcomes/react/utils/constants'

describe('ScoreWithLabel', () => {
  const defaultProps: ScoreWithLabelProps = {
    score: 3,
    label: 'Mastery',
    icon: <div data-testid="test-icon">Icon</div>,
  }

  it('renders with icon and label', () => {
    render(
      <ScoreWithLabel {...defaultProps} scoreDisplayFormat={ScoreDisplayFormat.ICON_AND_LABEL} />,
    )
    expect(screen.getByTestId('test-icon')).toBeInTheDocument()
    expect(screen.getByText('Mastery')).toBeInTheDocument()
  })

  describe('scoreDisplayFormat', () => {
    it('shows label in ScreenReaderContent with ICON_ONLY format (default)', () => {
      render(<ScoreWithLabel {...defaultProps} scoreDisplayFormat={ScoreDisplayFormat.ICON_ONLY} />)
      expect(screen.getByTestId('test-icon')).toBeInTheDocument()
      expect(screen.queryByText('Mastery')).not.toBeInTheDocument()
    })

    it('shows visible label with ICON_AND_LABEL format', () => {
      render(
        <ScoreWithLabel {...defaultProps} scoreDisplayFormat={ScoreDisplayFormat.ICON_AND_LABEL} />,
      )
      const labelText = screen.getByText('Mastery')
      expect(labelText).toBeInTheDocument()
      expect(labelText.closest('[class*="screenReaderContent"]')).not.toBeInTheDocument()
    })

    it('shows visible score with ICON_AND_POINTS format', () => {
      render(
        <ScoreWithLabel
          {...defaultProps}
          scoreDisplayFormat={ScoreDisplayFormat.ICON_AND_POINTS}
        />,
      )
      const pointsText = screen.getByText('3')
      expect(pointsText).toBeInTheDocument()
      expect(pointsText.closest('[class*="screenReaderContent"]')).not.toBeInTheDocument()
    })
  })

  it('renders without icon', () => {
    render(
      <ScoreWithLabel
        {...defaultProps}
        icon={undefined}
        scoreDisplayFormat={ScoreDisplayFormat.ICON_AND_LABEL}
      />,
    )
    expect(screen.queryByTestId('test-icon')).not.toBeInTheDocument()
    expect(screen.getByText('Mastery')).toBeInTheDocument()
  })

  it('renders without score', () => {
    render(
      <ScoreWithLabel
        {...defaultProps}
        score={undefined}
        label="Unassessed"
        scoreDisplayFormat={ScoreDisplayFormat.ICON_AND_LABEL}
      />,
    )
    expect(screen.getByText('Unassessed')).toBeInTheDocument()
  })

  it('uses default ICON_ONLY format when not specified', () => {
    render(<ScoreWithLabel {...defaultProps} />)
    expect(screen.getByTestId('test-icon')).toBeInTheDocument()
    expect(screen.queryByText('Mastery')).not.toBeInTheDocument()
  })
})
