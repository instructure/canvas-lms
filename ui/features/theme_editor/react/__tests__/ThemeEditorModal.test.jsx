/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import ThemeEditorModal from '../ThemeEditorModal'

describe('ThemeEditorModal Component', () => {
  const defaultProps = {
    showProgressModal: false,
    showSubAccountProgress: false,
    progress: 0.5,
    activeSubAccountProgresses: [],
  }

  test('modalOpen', () => {
    // Test when modal is closed
    const {queryByRole} = render(<ThemeEditorModal {...defaultProps} />)
    expect(queryByRole('dialog')).not.toBeInTheDocument()
  })

  test('modal opens when showProgressModal is true', () => {
    const {getByRole} = render(<ThemeEditorModal {...defaultProps} showProgressModal={true} />)
    expect(getByRole('dialog')).toBeInTheDocument()
  })

  test('modal opens when showSubAccountProgress is true', () => {
    const {getByRole} = render(<ThemeEditorModal {...defaultProps} showSubAccountProgress={true} />)
    expect(getByRole('dialog')).toBeInTheDocument()
  })

  test('shows progress content when showProgressModal is true', () => {
    const {getByText, getByRole} = render(
      <ThemeEditorModal {...defaultProps} showProgressModal={true} />,
    )
    expect(getByText('Generating preview...')).toBeInTheDocument()
    expect(getByRole('progressbar')).toBeInTheDocument()
  })

  test('shows sub-account content when showSubAccountProgress is true', () => {
    const {getByText} = render(<ThemeEditorModal {...defaultProps} showSubAccountProgress={true} />)
    expect(getByText('Changes will still apply if you leave this page.')).toBeInTheDocument()
  })
})
