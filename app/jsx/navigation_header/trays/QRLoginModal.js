/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import I18n from 'i18n!QRLoginModal'
import React, {useCallback, useState} from 'react'
import ReactDOM from 'react-dom'
import useFetchApi from 'jsx/shared/effects/useFetchApi'
import {showFlashAlert} from 'jsx/shared/FlashAlert'

import Modal from '../../shared/components/InstuiModal'
import {Img} from '@instructure/ui-img'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {func} from 'prop-types'

let modalContainer

// exported for tests only
export function killQRLoginModal() {
  if (modalContainer) ReactDOM.unmountComponentAtNode(modalContainer)
  modalContainer.remove()
  modalContainer = undefined
}

// exported for tests only
export function QRLoginModal({onDismiss}) {
  const [image, setImage] = useState(null)

  function fetchError(e) {
    showFlashAlert({
      message: I18n.t('An error occurred while retrieving your QR Code'),
      err: e
    })
    killQRLoginModal()
  }

  useFetchApi({
    path: 'canvas/login.png',
    fetchOpts: {method: 'POST'},
    success: useCallback(r => setImage(r), []),
    error: useCallback(fetchError, [])
  })

  function renderQRCode() {
    const body = image ? (
      <Img data-testid="qr-code-image" src={`data:image/png;base64, ${image.png}`} />
    ) : (
      <Spinner
        data-testid="qr-code-spinner"
        renderTitle={I18n.t('Waiting for your QR Code to load')}
      />
    )
    return (
      <View display="block" textAlign="center" padding="small 0 0">
        {body}
      </View>
    )
  }

  return (
    <Modal onDismiss={onDismiss} open label={I18n.t('QR for Mobile Login')} size="small">
      <Modal.Body>
        <View display="block">
          {I18n.t(
            "Scan this QR code from any Canvas mobile app to access your Canvas account when you're on the go."
          )}
        </View>
        {renderQRCode()}
      </Modal.Body>
      <Modal.Footer>
        <Button data-testid="qr-close-button" variant="primary" onClick={onDismiss}>
          {I18n.t('Done')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

QRLoginModal.propTypes = {
  onDismiss: func.isRequired
}

export function showQRLoginModal(props = {}) {
  if (modalContainer) return // Modal is already up
  const {QRModal, ...modalProps} = props
  modalContainer = document.createElement('div')
  modalContainer.setAttribute('id', 'qr_login_modal_container')
  document.body.appendChild(modalContainer)

  const Component = QRModal || QRLoginModal
  ReactDOM.render(<Component onDismiss={killQRLoginModal} {...modalProps} />, modalContainer)
}
