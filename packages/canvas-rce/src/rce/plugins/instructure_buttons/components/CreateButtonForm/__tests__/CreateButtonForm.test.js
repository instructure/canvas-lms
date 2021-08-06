/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useStoreProps} from '../../../../shared/StoreContext'
import {CreateButtonForm} from '../CreateButtonForm'

jest.mock('../../../../shared/StoreContext')

const startButtonsAndIconsUpload = jest.fn().mockResolvedValue({url: 'https://uploaded.url'})
useStoreProps.mockReturnValue({startButtonsAndIconsUpload})

const editor = {
  dom: {
    createHTML: jest.fn((tagName, {src, alt}) => {
      const element = document.createElement(tagName)
      element.setAttribute('src', src)
      element.setAttribute('alt', alt)
      return element
    })
  },
  insertContent: jest.fn()
}

describe('<CreateButtonForm />', () => {
  const defaults = {
    editor,
    onClose: jest.fn()
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('uploads the svg', async () => {
    render(<CreateButtonForm {...defaults} />)

    userEvent.click(screen.getByRole('button', {name: /apply/i}))
    expect(startButtonsAndIconsUpload.mock.calls[0]).toMatchInlineSnapshot(`
      Array [
        Object {
          "domElement": <svg
            fill="none"
            height="122px"
            viewBox="0 0 122 122"
            width="122px"
            xmlns="http://www.w3.org/2000/svg"
          >
            <svg
              fill="none"
              height="122px"
              viewBox="0 0 122 122"
              width="122px"
              x="0"
            >
              <g
                fill="none"
              >
                <rect
                  height="114"
                  width="114"
                  x="4"
                  y="4"
                />
              </g>
            </svg>
          </svg>,
          "name": "untitled.svg",
        },
      ]
    `)
    await waitFor(() => expect(defaults.onClose).toHaveBeenCalled())
  })

  it('writes the content to the editor', async () => {
    render(<CreateButtonForm {...defaults} />)

    userEvent.click(screen.getByRole('button', {name: /apply/i}))
    await waitFor(() => expect(editor.insertContent).toHaveBeenCalled())
    expect(editor.insertContent.mock.calls[0]).toMatchInlineSnapshot(`
      Array [
        <img
          alt=""
          src="https://uploaded.url"
        />,
      ]
    `)

    await waitFor(() => expect(defaults.onClose).toHaveBeenCalled())
  })

  it('disables footer while submiting', async () => {
    render(<CreateButtonForm {...defaults} />)

    const button = screen.getByRole('button', {name: /apply/i})
    userEvent.click(button)
    expect(button).toBeDisabled()

    await waitFor(() => expect(defaults.onClose).toHaveBeenCalled())
  })
})
