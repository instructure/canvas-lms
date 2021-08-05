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
import {act, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import sidebarHandlers from '../../../../../../sidebar/containers/sidebarHandlers'
import {buildSvg} from '../../../svg'
import {DEFAULT_SETTINGS} from '../../../svg/constants'
import {Footer} from '../Footer'
import {StoreProvider} from '../../../../shared/StoreContext'

jest.mock('../../../../../../sidebar/containers/sidebarHandlers')

const renderComponent = () => {
  return render(<StoreProvider>{props => <Footer {...props} />}</StoreProvider>)
}

describe('<Footer />', () => {
  describe('clicking the "Apply" button', () => {
    const getApplyButton = () => {
      return screen.getByRole('button', {name: 'Apply'})
    }

    let promise, uploadStub

    beforeEach(() => {
      promise = Promise.resolve()
      uploadStub = jest.fn(() => promise)

      sidebarHandlers.mockReturnValue(() => ({
        startButtonsAndIconsUpload: uploadStub
      }))

      renderComponent({settings: DEFAULT_SETTINGS})
    })

    it('calls the startButtonsAndIconsUpload prop', async () => {
      userEvent.click(getApplyButton())
      await act(() => promise)
      expect(uploadStub.mock.calls.length).toBe(1)
    })

    it('calls the startButtonsAndIconsUpload prop with the svg name and dom element', async () => {
      const svg = buildSvg(DEFAULT_SETTINGS)
      userEvent.click(getApplyButton())
      await act(() => promise)
      expect(uploadStub.mock.calls[0][0]).toEqual({name: 'placeholder_name.svg', domElement: svg})
    })

    it('is disabled while the upload is in progress', async () => {
      const applyButton = getApplyButton()
      userEvent.click(applyButton)
      expect(applyButton.hasAttribute('disabled')).toBe(true)
      await act(() => promise)
    })

    it('is not disabled after an upload has finished', async () => {
      const applyButton = getApplyButton()
      userEvent.click(applyButton)
      await act(() => promise)
      expect(applyButton.hasAttribute('disabled')).toBe(false)
    })
  })
})
