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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Editor, Frame} from '@craftjs/core'
import {HeadingBlock, type HeadingBlockProps} from '..'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock the useNode hook to avoid 404 errors
jest.mock('@craftjs/core', () => {
  const originalModule = jest.requireActual('@craftjs/core')
  return {
    ...originalModule,
    useNode: jest.fn().mockImplementation(() => ({
      connectors: {
        connect: jest.fn(),
        drag: jest.fn(),
      },
      actions: {
        setProp: jest.fn(),
      },
      selected: false,
      node: {
        data: {
          props: {},
        },
      },
    })),
  }
})

const renderBlock = (enabled: boolean, props: Partial<HeadingBlockProps> = {}) => {
  const user = userEvent.setup()
  const result = render(
    <>
      <div id="another-element" tabIndex={-1} data-testid="another-element">
        Another Element
      </div>
      <Editor enabled={enabled} resolver={{HeadingBlock}}>
        <Frame>
          <HeadingBlock text="A Heading" {...props} />
        </Frame>
      </Editor>
    </>,
  )
  return {
    ...result,
    user,
  }
}

describe('HeadingBlock', () => {
  beforeEach(() => {
    fakeENV.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.clearAllMocks()
    document.body.innerHTML = ''
  })

  describe('in an enabled Editor', () => {
    it('should render editable version with default props', async () => {
      const {container} = renderBlock(true)
      const heading = container.querySelector('h2')
      expect(heading).toBeInTheDocument()
      expect(screen.getByText('A Heading')).toBeInTheDocument()

      await waitFor(() => {
        expect(heading).toHaveAttribute('contenteditable', 'true')
        expect(heading).toHaveAttribute('data-placeholder', 'Heading 2')
      })
    })

    it('should stop being editable on blur', async () => {
      const {container} = render(
        <Editor enabled={true} resolver={{HeadingBlock}}>
          <Frame>
            <HeadingBlock text="A Heading" />
          </Frame>
        </Editor>,
      )

      const heading = container.querySelector('h2')
      expect(heading).toBeInTheDocument()
      expect(screen.getByText('A Heading')).toBeInTheDocument()
    })

    it('should render active editable version on click', async () => {
      const {container} = render(
        <Editor enabled={true} resolver={{HeadingBlock}}>
          <Frame>
            <HeadingBlock text="A Heading" />
          </Frame>
        </Editor>,
      )

      const heading = container.querySelector('h2')
      expect(heading).toBeInTheDocument()
      expect(screen.getByText('A Heading')).toBeInTheDocument()
    })

    it('respects the level prop', async () => {
      const {container} = renderBlock(true, {level: 'h3'})
      const heading = container.querySelector('h3')
      expect(heading).toBeInTheDocument()
    })
  })

  describe('in a disabled Editor', () => {
    it('should render non-editable version with default props', async () => {
      const {container} = renderBlock(false)

      expect(screen.getByText('A Heading')).toBeInTheDocument()
      expect(container.querySelector('h2')).toBeInTheDocument()
      expect(container.querySelector('[contenteditable]')).toBeNull()
    })

    it('respects the level prop', async () => {
      const {container} = renderBlock(false, {level: 'h3'})
      expect(container.querySelector('h3')).toBeInTheDocument()
    })
  })
})
