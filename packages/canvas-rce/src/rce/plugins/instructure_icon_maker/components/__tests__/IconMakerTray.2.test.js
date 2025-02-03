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

  describe('the "replace all instances" checkbox', () => {
    it('disables the name field when checked', async () => {
      const {getByTestId} = render(<IconMakerTray {...defaults} editing={true} />)

      act(() => getByTestId('cb-replace-all').click())

      await waitFor(() => expect(getByTestId('icon-name')).toBeDisabled())
    })

    it('does not disable the name field when not checked', async () => {
      const {getByTestId} = render(<IconMakerTray {...defaults} editing={true} />)

      await waitFor(() => expect(getByTestId('icon-name')).not.toBeDisabled())
    })

    it('does not disable the name field on new icons', async () => {
      const {getByTestId} = render(<IconMakerTray {...defaults} />)

      await waitFor(() => expect(getByTestId('icon-name')).not.toBeDisabled())
    })
  })

  describe('when submitting', () => {
    it('disables the footer', async () => {
      render(<IconMakerTray {...defaults} />)

      setIconColor('#000000')
      const button = screen.getByTestId('create-icon-button')
      await fireEvent.click(button)

      await waitFor(() => expect(button).toBeDisabled())
      await waitFor(() => expect(defaults.onUnmount).toHaveBeenCalled(), {
        timeout: 3000,
      })
    })

    it('shows a spinner', async () => {
      const {getByText, getByTestId} = render(<IconMakerTray {...defaults} />)

      setIconColor('#000000')
      const button = getByTestId('create-icon-button')
      await fireEvent.click(button)

      const spinner = getByText('Loading...')
      await waitFor(() => expect(spinner).toBeInTheDocument())
    })
  })

  describe('when an icon is being created', () => {
    let ed

    beforeEach(() => {
      ed = new FakeEditor()
    })

    const subject = () =>
      render(
        <IconMakerTray
          onClose={jest.fn()}
          editor={ed}
          canvasOrigin="https://canvas.instructor.com"
        />,
      )

    it('loads the standard SVG metadata', async () => {
      const {getByLabelText, getAllByTestId} = subject()

      await waitFor(() => {
        expect(getByLabelText('Name').value).toEqual('')
        expect(getByLabelText('Icon Shape').value).toEqual('Square')
        expect(getByLabelText('Icon Size').value).toEqual('Small')
        expect(getAllByTestId('colorPreview-none').length).toBeGreaterThan(0)
        expect(getByLabelText('Outline Size').value).toEqual('None')
      })
    })
  })
})
