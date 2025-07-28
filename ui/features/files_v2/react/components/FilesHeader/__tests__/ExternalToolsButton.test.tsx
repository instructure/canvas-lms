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
import ExternalToolsButton from '../ExternalToolsButton'
import {FileManagementProvider} from '../../../contexts/FileManagementContext'
import {createMockFileManagementContext} from '../../../__tests__/createMockContext'
import {type ExternalToolsButtonProps} from '../ExternalToolsButton'

describe('ExternalToolsButton', () => {
  const renderComponent = (props = {}, contextOverrides = {}) => {
    const defaultProps: ExternalToolsButtonProps = {
      buttonDisplay: 'block',
      size: 'large',
    }

    const contextProps = {
      fileIndexMenuTools: [
        {
          id: 'tool1',
          title: 'Test Tool',
          base_url: 'http://example.com/tool1',
          icon_url: 'http://example.com/tool1/icon.png',
        },
      ],
    }

    return render(
      <FileManagementProvider
        value={createMockFileManagementContext({...contextProps, ...contextOverrides})}
      >
        <ExternalToolsButton {...defaultProps} {...props} />
      </FileManagementProvider>,
    )
  }

  it('renders the button when external tools are available', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('lti-index-button')).toBeInTheDocument()
  })

  describe('when no external tools are available', () => {
    it('does not render', () => {
      const {queryByTestId} = renderComponent({}, {fileIndexMenuTools: []})
      expect(queryByTestId('lti-index-button')).not.toBeInTheDocument()
    })
  })

  it('renders mobile view when size is small', () => {
    const {getByText} = renderComponent({size: 'small'})
    expect(getByText('More')).toBeInTheDocument()
  })
})
