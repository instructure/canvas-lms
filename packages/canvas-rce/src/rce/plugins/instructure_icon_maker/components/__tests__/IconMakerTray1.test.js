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
import {render, fireEvent, screen, waitFor, act, within} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {IconMakerTray} from '../IconMakerTray'
import {useStoreProps} from '../../../shared/StoreContext'
import FakeEditor from '../../../../__tests__/FakeEditor'
import RceApiSource from '../../../../../rcs/api'
import bridge from '../../../../../bridge'
import base64EncodedFont from '../../svg/font'
import * as shouldIgnoreCloseRef from '../../utils/IconMakerClose'

jest.useFakeTimers()
jest.mock('../../../../../bridge')
jest.mock('../../svg/font')
jest.mock('../../../../../rcs/api')
jest.mock('../../../shared/StoreContext')
jest.mock('../../utils/useDebouncedValue', () =>
  jest.requireActual('../../utils/__tests__/useMockedDebouncedValue'),
)
const startIconMakerUpload = jest.fn().mockResolvedValue({
  url: 'https://uploaded.url',
  display_name: 'untitled.svg',
})

useStoreProps.mockReturnValue({startIconMakerUpload})

// The real font is massive so lets avoid it in snapshots
base64EncodedFont.mockReturnValue('data:;base64,')

const setIconColor = hex => {
  const input = screen.getByTestId('icon-maker-color-input-icon-color')
  fireEvent.input(input, {target: {value: hex}})
}

describe('RCE "Icon Maker" Plugin > IconMakerTray', () => {
  const defaults = {
    onUnmount: jest.fn(),
    editing: false,
    canvasOrigin: 'http://canvas.instructor.com',
    editor: new FakeEditor(),
  }

  let rcs
  const renderComponent = (componentProps = {}) => {
    return render(<IconMakerTray {...defaults} {...componentProps} />)
  }

  const {confirm} = window.confirm

  beforeAll(() => {
    rcs = {
      getFile: jest.fn(() => Promise.resolve({name: 'Test Icon.svg'})),
    }

    RceApiSource.mockImplementation(() => rcs)

    delete window.confirm
    window.confirm = jest.fn(() => true)
  })

  afterAll(() => {
    window.confirm = confirm
  })

  beforeEach(() => {
    jest.clearAllMocks()
  })

  afterEach(async () => {
    await act(async () => {
      jest.runOnlyPendingTimers()
    })
  })

  it('does not close when outside element clicked', async () => {
    const ignoreSpy = jest.spyOn(shouldIgnoreCloseRef, 'shouldIgnoreClose')
    const {getByText, findByTestId} = render(
      <>
        <button type="button">Outside button</button>
        <IconMakerTray {...defaults} />
      </>,
    )

    const addImageButton = getByText('Add Image')
    await fireEvent.click(addImageButton)

    await waitFor(() => expect(ignoreSpy).not.toHaveBeenCalled())
    await waitFor(() => expect(window.confirm).not.toHaveBeenCalled())
    await fireEvent.click(getByText('Outside button'))
    await waitFor(() => expect(ignoreSpy).not.toHaveBeenCalled())
    await waitFor(() => expect(window.confirm).not.toHaveBeenCalled())
  })

  it('renders the create view', () => {
    renderComponent()
    screen.getByRole('heading', {name: /create icon/i})
  })

  it('closes the tray', async () => {
    const onUnmount = jest.fn()
    renderComponent({onUnmount})
    await fireEvent.click(screen.getByText(/close/i))
    await waitFor(() => expect(onUnmount).toHaveBeenCalled())
  })

  it('does not call confirm when there are no changes', async () => {
    renderComponent()
    await fireEvent.click(screen.getByText(/close/i))
    expect(window.confirm).not.toHaveBeenCalled()
  })

  it('calls confirm when the user has unsaved changes', async () => {
    renderComponent()
    // edit the icon before clicking on close
    setIconColor('#000000')
    await fireEvent.click(screen.getByText(/close/i))
    expect(window.confirm).toHaveBeenCalled()
  })

  it('inserts a placeholder when an icon is inserted', async () => {
    const {getByTestId} = renderComponent()
    setIconColor('#000000')
    await fireEvent.click(getByTestId('create-icon-button'))
    await waitFor(() => expect(bridge.embedImage).toHaveBeenCalled())
  })

  describe('when the user has not created a valid icon', () => {
    beforeEach(async () => {
      render(<IconMakerTray {...defaults} />)
      await fireEvent.click(screen.getByTestId('create-icon-button'))
    })

    it('does not fire off the icon upload callback', () => {
      expect(startIconMakerUpload).not.toHaveBeenCalled()
    })

    it('shows an error message', () => {
      const alertMessage = screen.getByText(/one of the following styles/i)
      expect(alertMessage).toBeInTheDocument()
    })
  })

  describe('focus management', () => {
    let focusedElement, originalFocus

    beforeAll(() => {
      originalFocus = window.HTMLElement.prototype.focus
    })

    beforeEach(() => {
      window.HTMLElement.prototype.focus = jest.fn().mockImplementation(function (_args) {
        focusedElement = this
      })
    })

    afterEach(() => (window.HTMLElement.prototype.focus = originalFocus))

    describe('when the close button is focused', () => {
      describe('and the user does a forward tab', () => {
        const event = {key: 'Tab', keyCode: 9}

        it('moves focus to the "name" input', async () => {
          const {findByTestId} = render(<IconMakerTray {...defaults} />)
          const closeButton = await findByTestId('icon-maker-close-button')
          const expectedElement = await findByTestId('icon-name')
          fireEvent.keyDown(closeButton, event)
          expect(focusedElement).toEqual(expectedElement)
        })
      })

      describe('and the user does a reverse tab', () => {
        const event = {key: 'Tab', keyCode: 9, shiftKey: true}

        it('moves focus to the apply button', async () => {
          const {findByTestId} = render(<IconMakerTray {...defaults} />)
          const closeButton = await findByTestId('icon-maker-close-button')
          const expectedElement = await findByTestId('create-icon-button')
          fireEvent.keyDown(closeButton, event)
          expect(focusedElement).toEqual(expectedElement)
        })
      })
    })
  })

  describe('uploads the svg', () => {
    it('with correct content', async () => {
      render(<IconMakerTray {...defaults} />)

      setIconColor('#000000')
      await fireEvent.click(screen.getByTestId('create-icon-button'))
      let firstCall
      await waitFor(() => {
        const result = startIconMakerUpload.mock.calls[0]
        if (startIconMakerUpload.mock.calls.length <= 0) throw new Error()
        firstCall = startIconMakerUpload.mock.calls[0][0]
        expect(result[1].onDuplicate).toBe(false)
      })

      expect(firstCall).toMatchInlineSnapshot(`
        {
          "domElement": <svg
            fill="none"
            height="122px"
            viewBox="0 0 122 122"
            width="122px"
            xmlns="http://www.w3.org/2000/svg"
          >
            <metadata>
              {"type":"image/svg+xml-icon-maker-icons","shape":"square","size":"small","color":"#000000","outlineColor":"#000000","outlineSize":"none","text":"","textSize":"small","textColor":"#000000","textBackgroundColor":null,"textPosition":"below","imageSettings":{"mode":"","image":"","imageName":"","icon":"","iconFillColor":"#000000","cropperSettings":null}}
            </metadata>
            <svg
              fill="none"
              height="122px"
              viewBox="0 0 122 122"
              width="122px"
              x="0"
            >
              <g
                fill="#000000"
              >
                <rect
                  height="114"
                  width="114"
                  x="4"
                  y="4"
                />
              </g>
              <g
                stroke="#000000"
                stroke-width="0"
              >
                <clippath
                  id="clip-path-for-embed"
                >
                  <rect
                    height="114"
                    width="114"
                    x="4"
                    y="4"
                  />
                </clippath>
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
        }
      `)

      await waitFor(() => expect(defaults.onUnmount).toHaveBeenCalled())
    })

    it('with overwrite if "replace all" is checked', async () => {
      const {getByTestId} = render(<IconMakerTray {...defaults} editing={true} />)

      setIconColor('#000000')

      act(() => {
        getByTestId('cb-replace-all').click()
      })

      act(() => {
        getByTestId('icon-maker-save').click()
      })

      await waitFor(() => {
        if (startIconMakerUpload.mock.calls.length <= 0) throw new Error()
        const result = startIconMakerUpload.mock.calls[0]
        expect(result[1].onDuplicate).toBe('overwrite')
      })
    })
  })

  describe('alt text handling', () => {
    describe('writes content to the editor', () => {
      it('with alt text when it is present', async () => {
        render(<IconMakerTray {...defaults} />)

        fireEvent.change(document.querySelector('#icon-alt-text'), {
          target: {value: 'banana'},
        })
        setIconColor('#000000')
        await fireEvent.click(screen.getByTestId('create-icon-button'))
        await waitFor(() => expect(bridge.embedImage).toHaveBeenCalled())
        expect(bridge.embedImage.mock.calls[0][0]).toMatchInlineSnapshot(`
          {
            "STYLE": null,
            "alt_text": "banana",
            "data-download-url": "https://uploaded.url/?icon_maker_icon=1",
            "data-inst-icon-maker-icon": true,
            "display_name": "untitled.svg",
            "height": null,
            "isDecorativeImage": false,
            "src": "https://uploaded.url",
            "width": null,
          }
        `)

        await waitFor(() => expect(defaults.onUnmount).toHaveBeenCalled())
      })

      it('without alt attribute when no alt text entered', async () => {
        render(<IconMakerTray {...defaults} />)

        setIconColor('#000000')
        await fireEvent.click(screen.getByTestId('create-icon-button'))
        await waitFor(() => expect(bridge.embedImage).toHaveBeenCalled())
        expect(bridge.embedImage.mock.calls[0][0]).toMatchInlineSnapshot(`
          {
            "STYLE": null,
            "alt_text": "",
            "data-download-url": "https://uploaded.url/?icon_maker_icon=1",
            "data-inst-icon-maker-icon": true,
            "display_name": "untitled.svg",
            "height": null,
            "isDecorativeImage": false,
            "src": "https://uploaded.url",
            "width": null,
          }
        `)

        await waitFor(() => expect(defaults.onUnmount).toHaveBeenCalled())
      })

      it('with alt="" if is decorative', async () => {
        render(<IconMakerTray {...defaults} />)
        setIconColor('#000000')
        await fireEvent.click(screen.getByLabelText('Decorative Icon'))
        await fireEvent.click(screen.getByTestId('create-icon-button'))
        await waitFor(() => expect(bridge.embedImage).toHaveBeenCalled())
        expect(bridge.embedImage.mock.calls[0][0]).toMatchInlineSnapshot(`
          {
            "STYLE": null,
            "alt_text": "",
            "data-download-url": "https://uploaded.url/?icon_maker_icon=1",
            "data-inst-icon-maker-icon": true,
            "display_name": "untitled.svg",
            "height": null,
            "isDecorativeImage": true,
            "src": "https://uploaded.url",
            "width": null,
          }
        `)
      })
    })
  })
})
