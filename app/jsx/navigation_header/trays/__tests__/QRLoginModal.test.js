/* Copyright (C) 2020 - present Instructure, Inc.
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
import fetchMock from 'fetch-mock'
import {showQRLoginModal, QRLoginModal, killQRLoginModal} from '../QRLoginModal'
import {render, fireEvent} from '@testing-library/react'
import {getByText as domGetByText} from '@testing-library/dom'

const loginImageJson = {
  png: 'R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='
}

const QRModalStub = () => <span>hi there</span>

describe('Navigation Header > Trays', () => {
  describe('showQRLoginModal function', () => {
    it('renders the modal component inside the div', () => {
      showQRLoginModal({QRModal: QRModalStub})
      const container = document.querySelector('div#qr_login_modal_container')
      expect(domGetByText(container, 'hi there')).toBeInTheDocument()
    })

    it('removes the div when the modal is closed', () => {
      showQRLoginModal({QRModal: QRModalStub})
      killQRLoginModal()
      const container = document.querySelector('div#qr_login_modal_container')
      expect(container).toBeNull()
    })

    it('does not render multiple divs if called more than once', () => {
      showQRLoginModal({QRModal: QRModalStub})
      showQRLoginModal({QRModal: QRModalStub})
      showQRLoginModal({QRModal: QRModalStub})
      const containers = document.querySelectorAll('div#qr_login_modal_container')
      expect(containers.length).toBe(1)
    })
  })

  describe('QRLoginModal component', () => {
    const handleDismiss = jest.fn()

    beforeEach(handleDismiss.mockClear)

    afterEach(fetchMock.restore)

    it('renders the dialog', () => {
      const {getByText} = render(<QRLoginModal onDismiss={handleDismiss} />)
      expect(getByText(/Scan this QR code/)).toBeInTheDocument()
    })

    it('renders a spinner before the API call has completed', () => {
      const {getByTestId} = render(<QRLoginModal onDismiss={handleDismiss} />)
      expect(getByTestId('qr-code-spinner')).toBeInTheDocument()
    })

    it('renders the image returned by the API call', async () => {
      fetchMock.post('/canvas/login.png', loginImageJson)
      const {findByTestId} = render(<QRLoginModal onDismiss={handleDismiss} />)
      const image = await findByTestId('qr-code-image')
      expect(image.src).toBe(`data:image/png;base64, ${loginImageJson.png}`)
    })

    it('kills the modal off when "Done" button is clicked', () => {
      const {getByTestId} = render(<QRLoginModal onDismiss={handleDismiss} />)
      const closeButton = getByTestId('qr-close-button')
      fireEvent.click(closeButton)
      expect(handleDismiss).toHaveBeenCalled()
    })

    it('kills the modal off when the modal dismiss X is clicked', () => {
      const {getByTestId} = render(<QRLoginModal onDismiss={handleDismiss} />)
      const closeButton = getByTestId('instui-modal-close').querySelector('button')
      fireEvent.click(closeButton)
      expect(handleDismiss).toHaveBeenCalled()
    })
  })
})
