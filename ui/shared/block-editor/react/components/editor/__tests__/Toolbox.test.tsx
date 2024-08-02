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
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {Editor, useEditor} from '@craftjs/core'

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Toolbox, type ToolboxProps} from '../Toolbox'

const user = userEvent.setup()

const mockCreate = jest.fn()

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useEditor: jest.fn(() => {
      return {
        connectors: {
          create: mockCreate,
        },
      }
    }),
  }
})

const defaultProps: ToolboxProps = {
  open: true,
  container: document.createElement('div'),
  onClose: () => {},
}

const renderComponent = (props: Partial<ToolboxProps> = {}) => {
  return render(
    <Editor enabled={true}>
      <Toolbox {...defaultProps} {...props} />
    </Editor>
  )
}

const blockList = ['Button', 'Text', 'Icon', 'Heading', 'Resource Card', 'Image', 'Tabs']

describe('Toolbox', () => {
  beforeEach(() => {
    mockCreate.mockClear()
  })

  it('renders', () => {
    const {getByText} = renderComponent()

    expect(getByText('Blocks')).toBeInTheDocument()
    for (const block of blockList) {
      expect(getByText(block)).toBeInTheDocument()
    }
  })

  it('calls onClose when close button is clicked', async () => {
    const onClose = jest.fn()
    const {getByText} = renderComponent({onClose})

    await user.click(getByText('Close').closest('button') as HTMLButtonElement)

    expect(onClose).toHaveBeenCalled()
  })

  // the rest is drag and drop and will be tested in the e2e tests
})
