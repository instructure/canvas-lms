/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {RCSPropsContext} from '../../../../Contexts'
import {UploadRecordMediaModal} from '../UploadRecordMediaModal'
import {mockTrayProps} from './fixtures/mockTrayProps'

jest.mock('@instructure/canvas-media', () => ({
  __esModule: true,
  default: jest.fn(props => {
    return props.open && <div data-testid="upload-media-mock">UploadMedia Component</div>
  }),
}))

describe('UploadRecordMediaModal', () => {
  const defaultProps = {
    open: true,
    onSubmit: jest.fn(),
    onDismiss: jest.fn(),
    accept: 'video/*',
  }

  const renderComponent = (props = {}) => {
    return render(
      <RCSPropsContext.Provider value={mockTrayProps}>
        <UploadRecordMediaModal {...defaultProps} {...props} />
      </RCSPropsContext.Provider>,
    )
  }

  it('passes props properly on to UploadMedia to show it', () => {
    renderComponent()
    expect(screen.getByTestId('upload-media-mock')).toBeInTheDocument()
  })

  it('passes props properly on to UploadMedia as to not show it', () => {
    renderComponent({open: false})
    expect(screen.queryByTestId('upload-media-mock')).not.toBeInTheDocument()
  })
})
