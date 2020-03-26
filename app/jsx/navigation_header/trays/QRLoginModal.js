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
import React, {useState, useEffect} from 'react'
import ReactDOM from 'react-dom'
import {showFlashAlert} from 'jsx/shared/FlashAlert'
import doFetchApi from 'jsx/shared/effects/doFetchApi'

import Modal from '../../shared/components/InstuiModal'
import {Img} from '@instructure/ui-img'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import moment from 'moment'
import {func, object} from 'prop-types'

const REFRESH_INTERVAL = moment.duration(9.75, 'minutes') // 9 min 45 sec
const POLL_INTERVAL = moment.duration(5, 'seconds')
const QR_CODE_LIFETIME = moment.duration(10, 'minutes')

let modalContainer

// exported for tests only
export function killQRLoginModal() {
  if (modalContainer) ReactDOM.unmountComponentAtNode(modalContainer)
  modalContainer.remove()
  modalContainer = undefined
}

// exported for tests only
export function QRLoginModal({onDismiss, refreshInterval, pollInterval}) {
  const [imagePng, setImagePng] = useState(null)
  const [validFor, setValidFor] = useState(null)

  function renderQRCode() {
    const body = imagePng ? (
      <Img data-testid="qr-code-image" src={`data:image/png;base64, ${imagePng}`} />
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

  function startTimedEvents() {
    let timerId = null
    let isFetching = false
    let validUntil = null
    let refetchAt = null

    function displayValidFor(expireTime) {
      if (expireTime) validUntil = expireTime
      if (validUntil) {
        const newValidFor = moment().isBefore(validUntil)
          ? I18n.t('This code expires in %{timeFromNow}.', {timeFromNow: validUntil.fromNow(true)})
          : I18n.t('This code has expired.')
        setValidFor(newValidFor)
      }
    }

    async function getQRCode() {
      isFetching = true
      try {
        const {json} = await doFetchApi({path: '/canvas/login.png', method: 'POST'})
        displayValidFor(moment().add(QR_CODE_LIFETIME))
        refetchAt = moment().add(refreshInterval)
        setImagePng(json.png)
      } catch (err) {
        showFlashAlert({
          message: I18n.t('An error occurred while retrieving your QR Code'),
          err
        })
        onDismiss()
      } finally {
        isFetching = false
      }
    }

    function poll() {
      displayValidFor()
      if (!isFetching && (!refetchAt || moment().isAfter(refetchAt))) getQRCode()
      timerId = setTimeout(poll, pollInterval.asMilliseconds())
    }

    poll()

    return () => {
      if (timerId) clearTimeout(timerId)
    }
  }

  useEffect(startTimedEvents, [])

  return (
    <Modal onDismiss={onDismiss} open label={I18n.t('QR for Mobile Login')} size="small">
      <Modal.Body>
        <View display="block">
          {I18n.t(
            'To log in to your Canvas account when you’re on the go, scan this QR code from any Canvas mobile app.'
          )}
        </View>
        {renderQRCode()}

        {validFor && (
          <Text weight="light" size="small">
            {validFor}
          </Text>
        )}
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
  onDismiss: func,
  refreshInterval: object,
  pollInterval: object
}

QRLoginModal.defaultProps = {
  onDismiss: killQRLoginModal,
  refreshInterval: REFRESH_INTERVAL,
  pollInterval: POLL_INTERVAL
}

export function showQRLoginModal(props = {}) {
  if (modalContainer) return // Modal is already up
  const {QRModal, ...modalProps} = props
  modalContainer = document.createElement('div')
  modalContainer.setAttribute('id', 'qr_login_modal_container')
  document.body.appendChild(modalContainer)

  const Component = QRModal || QRLoginModal
  ReactDOM.render(<Component {...modalProps} />, modalContainer)
}
