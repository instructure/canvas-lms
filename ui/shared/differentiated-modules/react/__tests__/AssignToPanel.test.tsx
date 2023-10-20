/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import AssignToPanel, {AssignToPanelProps} from '../AssignToPanel'

describe('AssignToPanel', () => {
  const props: AssignToPanelProps = {
    courseId: '1',
    moduleId: '2',
    height: '500px',
    onDismiss: () => {},
  }

  const renderComponent = (overrides = {}) => render(<AssignToPanel {...props} {...overrides} />)

  it('renders', () => {
    const {getByText} = renderComponent()
    expect(
      getByText('By default everyone in this course has assigned access to this module.')
    ).toBeInTheDocument()
  })

  it('renders options', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('everyone-option')).toBeInTheDocument()
    expect(getByTestId('custom-option')).toBeInTheDocument()
  })

  it('renders everyone as the default option', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('everyone-option')).toBeChecked()
    expect(getByTestId('custom-option')).not.toBeChecked()
  })
})
