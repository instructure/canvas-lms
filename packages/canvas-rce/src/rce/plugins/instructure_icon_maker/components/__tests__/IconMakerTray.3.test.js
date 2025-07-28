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

  describe('when an icon is being edited', () => {
    let ed

    beforeEach(() => {
      ed = new FakeEditor()
      // Add an image to the editor and select it
      ed.setContent(
        '<img id="test-image" src="https://canvas.instructure.com/svg" data-inst-icon-maker-icon="true" data-download-url="https://canvas.instructure.com/files/1/download" alt="a red circle" />',
      )
      ed.setSelectedNode(ed.dom.select('#test-image')[0])
    })

    const subject = () =>
      render(
        <IconMakerTray
          onClose={jest.fn()}
          editing={true}
          editor={ed}
          canvasOrigin="https://canvas.instructure.com"
        />,
      )

    beforeEach(() => {
      fetchMock.mock('*', {
        body: `
          {
            "name":"Test Icon.svg",
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
            "textPosition":"below"
          }`,
      })
    })

    afterEach(() => {
      jest.restoreAllMocks()
      fetchMock.restore()
    })

    it('renders the edit view', async () => {
      expect(await subject().findByRole('heading', {name: /edit icon/i})).toBeInTheDocument()
    })

    it('does not call confirm when there are no changes', async () => {
      subject()
      await fireEvent.click(await screen.findByText(/close/i))
      expect(window.confirm).not.toHaveBeenCalled()
    })

    it('calls confirm when the user has unsaved changes', async () => {
      await subject().findByTestId('icon-maker-color-input-icon-color')
      setIconColor('#000000')
      await fireEvent.click(screen.getByText(/close/i))
      expect(window.confirm).toHaveBeenCalled()
    })

    it('inserts a placeholder when an icon is saved', async () => {
      const {getByTestId} = subject()
      await waitFor(() => getByTestId('icon-maker-color-input-icon-color'))
      setIconColor('#000000')
      await fireEvent.click(getByTestId('icon-maker-save'))
      await waitFor(() => expect(bridge.embedImage).toHaveBeenCalled())
    })

    it('loads the standard SVG metadata', async () => {
      const {getByLabelText, getByTestId} = subject()

      await waitFor(() => {
        expect(getByLabelText('Name').value).toEqual('Test Icon')
        expect(getByLabelText('Icon Shape').value).toEqual('Triangle')
        expect(getByLabelText('Icon Size').value).toEqual('Large')
        expect(getByTestId('colorPreview-#FF2717')).toBeInTheDocument() // icon color
        expect(getByTestId('colorPreview-#06A3B7')).toBeInTheDocument() // icon outline
        expect(getByLabelText('Outline Size').value).toEqual('Small')
      })
    })

    it('loads the text-related SVG metadata', async () => {
      const {getByLabelText, getByTestId, getByText} = subject()

      await waitFor(() => {
        expect(getByText('Some Text')).toBeInTheDocument()
        expect(getByLabelText('Text Size').value).toEqual('Medium')
        expect(getByTestId('colorPreview-#009606')).toBeInTheDocument() // text color
        expect(getByTestId('colorPreview-#E71F63')).toBeInTheDocument() // text background color
        expect(getByLabelText('Text Position').value).toEqual('Below')
      })
    })

    describe('when an icon has styling from RCE', () => {
      beforeEach(() => {
        // Add an image to the editor and select it
        ed.setContent(
          '<img style="display:block; margin-left:auto; margin-right:auto;" width="156" height="134" id="test-image" src="https://canvas.instructure.com/svg" data-inst-icon-maker-icon="true" data-download-url="https://canvas.instructure.com/files/1/download" alt="one blue pine" />',
        )
        ed.setSelectedNode(ed.dom.select('#test-image')[0])
      })

      it('checks that the icon keeps attributes from RCE', async () => {
        const {getByTestId} = subject()
        await waitFor(() => getByTestId('icon-maker-color-input-icon-color'))
        setIconColor('#000000')
        expect(getByTestId('icon-maker-save')).toBeEnabled()
        await fireEvent.click(getByTestId('icon-maker-save'))
        await waitFor(() => expect(bridge.embedImage).toHaveBeenCalled())
        expect(bridge.embedImage.mock.calls[0][0]).toMatchInlineSnapshot(`
          {
            "STYLE": "display:block; margin-left:auto; margin-right:auto;",
            "alt_text": "one blue pine",
            "data-download-url": "https://uploaded.url/?icon_maker_icon=1",
            "data-inst-icon-maker-icon": true,
            "display_name": "untitled.svg",
            "height": "134",
            "isDecorativeImage": false,
            "src": "https://uploaded.url",
            "width": "156",
          }
        `)
      })
    })

    describe('when loading the tray', () => {
      let isLoading

      beforeAll(() => {
        isLoading = IconMakerTray.isLoading
        IconMakerTray.isLoading = jest.fn()
      })

      afterAll(() => {
        IconMakerTray.isLoading = isLoading
      })

      it('renders a spinner', async () => {
        IconMakerTray.isLoading.mockReturnValueOnce(true)
        const {getByText} = subject()
        await waitFor(() => expect(getByText('Loading...')).toBeInTheDocument())
      })
    })
  })

  describe('color inputs', () => {
    const getNoneColorOptionFor = async popoverTestId => {
      const {getByTestId} = renderComponent()
      const dropdownArrow = getByTestId(`${popoverTestId}-trigger`)
      await fireEvent.click(dropdownArrow)
      const popover = getByTestId(popoverTestId)
      return within(popover).queryByText('None')
    }

    describe('have no none option when', () => {
      it('they represent outline color', async () => {
        const noneColorOption = await getNoneColorOptionFor('icon-outline-popover')
        expect(noneColorOption).not.toBeInTheDocument()
      })

      it('they represent text color', async () => {
        const noneColorOption = await getNoneColorOptionFor('icon-text-color-popover')
        expect(noneColorOption).not.toBeInTheDocument()
      })

      it('they represent single color image', async () => {
        const {getByText, getByTestId} = renderComponent()
        const addImageButton = getByText('Add Image')
        await fireEvent.click(addImageButton)
        const singleColorOption = getByText('Single Color Image')
        await fireEvent.click(singleColorOption)
        const artIcon = await waitFor(() => getByTestId('icon-maker-art'))
        await fireEvent.click(artIcon)
        const noneColorOption = await getNoneColorOptionFor('single-color-image-fill-popover')
        expect(noneColorOption).not.toBeInTheDocument()
      })
    })

    describe('have a none option when', () => {
      it('they represent icon color', async () => {
        const noneColorOption = await getNoneColorOptionFor('icon-color-popover')
        expect(noneColorOption).toBeInTheDocument()
      })

      it('they represent text background color', async () => {
        const noneColorOption = await getNoneColorOptionFor('icon-text-background-color-popover')
        expect(noneColorOption).toBeInTheDocument()
      })
    })
  })
})
