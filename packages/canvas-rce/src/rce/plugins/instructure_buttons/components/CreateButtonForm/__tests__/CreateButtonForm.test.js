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
import FakeEditor from '../../../../shared/__tests__/FakeEditor'

jest.mock('../../../../shared/StoreContext')

const startButtonsAndIconsUpload = jest.fn().mockResolvedValue({url: 'https://uploaded.url'})
useStoreProps.mockReturnValue({startButtonsAndIconsUpload})

const editor = {
  dom: {
    createHTML: jest.fn((tagName, {src, alt, ...rest}) => {
      const element = document.createElement(tagName)
      element.setAttribute('src', src)
      element.setAttribute('alt', alt)
      element.setAttribute('data-inst-buttons-and-icons', rest['data-inst-buttons-and-icons'])
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

  beforeAll(() => {
    global.fetch = jest.fn().mockResolvedValue({
      blob: () => Promise.resolve(new Blob())
    })
  })

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('uploads the svg', async () => {
    render(<CreateButtonForm {...defaults} />)

    userEvent.click(screen.getByRole('button', {name: /apply/i}))
    await waitFor(() => {
      if (startButtonsAndIconsUpload.mock.calls.length <= 0) throw new Error()
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
              <metadata>
                {"name":"","alt":"","shape":"square","size":"small","color":null,"outlineColor":null,"outlineSize":"none","text":"","textSize":"small","textColor":null,"textBackgroundColor":null,"textPosition":"middle"}
              </metadata>
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
              <style
                type="text/css"
              >
                @font-face {font-family: "Lato Extended";font-weight: bold;src: url(data:;base64,);}
              </style>
            </svg>,
            "name": "untitled.svg",
          },
          Object {
            "onDuplicate": false,
          },
        ]
      `)
    })
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
          data-inst-buttons-and-icons="true"
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

  describe('when a button is being edited', () => {
    let ed

    beforeEach(() => {
      ed = new FakeEditor()

      // Add an image to the editor and select it
      ed.setContent(
        '<img id="test-image" src="https://canvas.instructure.com/svg" alt="a red circle" />'
      )
      ed.setSelectedNode(ed.dom.select('#test-image')[0])
    })

    const subject = () =>
      render(<CreateButtonForm onClose={jest.fn()} editing={true} editor={new FakeEditor()} />)

    beforeEach(() => {
      global.fetch = jest.fn().mockResolvedValue({
        text: () =>
          Promise.resolve(`
            <svg height="100" width="100">
              <metadata>
                {
                  "name":"Test Image",
                  "alt":"a test image",
                  "shape":"triangle",
                  "size":"large",
                  "color":"#FF2717",
                  "outlineColor":"#06A3B7",
                  "outlineSize":"small",
                  "text":"Some Text",
                  "textSize":"medium",
                  "textColor":"#009606",
                  "textBackgroundColor":"#E71F63",
                  "textPosition":"middle"
                }
              </metadata>
              <circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red"/>
            </svg>
          `)
      })
    })

    afterEach(() => jest.restoreAllMocks())

    it('loads the standard SVG metadata', async () => {
      const {getByLabelText, getByTestId} = subject()

      await waitFor(() => {
        expect(getByLabelText('Name').value).toEqual('Test Image')
        expect(getByLabelText('Button Shape').value).toEqual('Triangle')
        expect(getByLabelText('Button Size').value).toEqual('Large')
        expect(getByTestId('colorPreview-#FF2717')).toBeInTheDocument() // button color
        expect(getByTestId('colorPreview-#06A3B7')).toBeInTheDocument() // button outline
        expect(getByLabelText('Button Outline Size').value).toEqual('Small')
      })
    })

    it('loads the text-related SVG metadata', async () => {
      const {getByLabelText, getByTestId, getByText} = subject()

      await waitFor(() => {
        expect(getByText('Some Text')).toBeInTheDocument()
        expect(getByLabelText('Text Size').value).toEqual('Medium')
        expect(getByTestId('colorPreview-#009606')).toBeInTheDocument() // text color
        expect(getByTestId('colorPreview-#E71F63')).toBeInTheDocument() // text background color
        expect(getByLabelText('Text Position').value).toEqual('Middle')
      })
    })
  })
})
