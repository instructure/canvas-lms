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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState, useEffect} from 'react'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'

import TopNavPortal from '@canvas/top-navigation/react/TopNavPortal'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Img} from '@instructure/ui-img'
import {Spinner} from '@instructure/ui-spinner'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {fromNow} from '@canvas/fuzzy-relative-time'

const I18n = useI18nScope('QRMobileLogin')

const REFRESH_INTERVAL = 1000 * (9 * 60 + 45) // 9 min 45 sec
const POLL_INTERVAL = 1000 * 5 // 5 sec
const QR_CODE_LIFETIME = 1000 * 10 * 60 // 10 minutes

const DISPLAY_STATE = {
  canceled: 0,
  warning: 1,
  displayed: 2,
}

const modalLabel = () => I18n.t('Confirm QR code display')

export function QRMobileLogin({
  refreshInterval,
  pollInterval,
  withWarning,
}: {
  refreshInterval: number
  pollInterval: number
  withWarning: boolean
}) {
  const [imagePng, setImagePng] = useState(null)
  const [validFor, setValidFor] = useState(null)
  const [display, setDisplay] = useState(
    withWarning ? DISPLAY_STATE.warning : DISPLAY_STATE.displayed
  )

  function renderQRCode() {
    let body

    switch (display) {
      case DISPLAY_STATE.canceled:
        body = <Text size="large">{I18n.t('QR code display was canceled')}</Text>
        break

      case DISPLAY_STATE.warning:
        body = (
          <Spinner
            data-testid="qr-code-spinner"
            renderTitle={I18n.t('Waiting for confirmation to display QR code')}
          />
        )
        break

      case DISPLAY_STATE.displayed:
        if (imagePng) {
          body = (
            <span className="fs-exclude">
              <Img
                alt={I18n.t('QR Code Image')}
                constrain="contain"
                data-testid="qr-code-image"
                src={`data:image/png;base64, ${imagePng}`}
              />
            </span>
          )
        } else {
          body = (
            <Spinner
              data-testid="qr-code-spinner"
              renderTitle={I18n.t('Waiting for your QR Code to load')}
            />
          )
        }
    }

    return (
      <>
        {display !== DISPLAY_STATE.canceled && (
          <View display="block">
            {I18n.t(
              'To log in to your Canvas account when you’re on the go, scan this QR code from any Canvas mobile app.'
            )}
          </View>
        )}
        <View display="block" textAlign="center" padding="small xx-large">
          {body}
        </View>
      </>
    )
  }

  function onModalProceed() {
    setDisplay(DISPLAY_STATE.displayed)
  }

  function onModalCancel() {
    setDisplay(DISPLAY_STATE.canceled)
  }

  function startTimedEvents() {
    let timerId: number
    let isFetching = false
    let validUntil: number | undefined
    let refetchAt: number | undefined

    function displayValidFor(expireTime?: number) {
      if (expireTime) validUntil = expireTime
      if (validUntil) {
        const newValidFor =
          Date.now() < validUntil
            ? I18n.t('This code expires %{timeFromNow}.', {
                timeFromNow: fromNow(validUntil),
              })
            : I18n.t('This code has expired.')
        setValidFor(newValidFor)
      }
    }

    async function getQRCode() {
      isFetching = true
      try {
        const {json} = await doFetchApi({path: '/canvas/login.png', method: 'POST'})
        displayValidFor(Date.now() + QR_CODE_LIFETIME)
        refetchAt = Date.now() + refreshInterval
        setImagePng(json.png)
      } catch (err) {
        showFlashAlert({
          message: I18n.t('An error occurred while retrieving your QR Code'),
          err: err instanceof Error ? err : null,
        })
      } finally {
        isFetching = false
      }
    }

    function poll() {
      displayValidFor()
      if (!isFetching && (!refetchAt || Date.now() > refetchAt)) getQRCode()
      timerId = setTimeout(poll, pollInterval) as unknown as number
    }

    if (display === DISPLAY_STATE.displayed) poll()

    return () => {
      if (timerId) clearTimeout(timerId)
    }
  }

  useEffect(startTimedEvents, [display])

  return (
    <>
      <TopNavPortal />
      <Flex direction="column" justifyItems="center" margin="none medium">
        <Flex.Item margin="xx-small" padding="xx-small">
          <Heading level="h1">{I18n.t('QR for Mobile Login')}</Heading>
        </Flex.Item>
        <Flex.Item>
          <View
            borderColor="primary"
            borderWidth="small"
            borderRadius="medium"
            padding="medium"
            margin="medium small"
            maxWidth="30rem"
            as="div"
          >
            {renderQRCode()}
            {validFor && display === DISPLAY_STATE.displayed && (
              <Text weight="light" size="small">
                {validFor}
              </Text>
            )}
          </View>
        </Flex.Item>
      </Flex>
      <Modal
        size="small"
        open={display === DISPLAY_STATE.warning}
        onDismiss={onModalCancel}
        shouldCloseOnDocumentClick={false}
        label={modalLabel()}
      >
        <Modal.Header>
          <CloseButton
            data-testid="qr-header-close-button"
            placement="end"
            offset="medium"
            onClick={onModalCancel}
            screenReaderLabel={I18n.t('Cancel')}
          />
          <Heading>{modalLabel()}</Heading>
        </Modal.Header>
        <Modal.Body>
          <View as="div" margin="medium large">
            <Text as="div">
              <p>
                {I18n.t(
                  'Sharing a QR code can give others immediate access to your account through the %{canvas} mobile applications.',
                  {canvas: 'Canvas'}
                )}
              </p>
              <p>
                {I18n.t(
                  'Please make sure no one is able to capture the image on your screen from your surroundings or from a screen sharing service.'
                )}
              </p>
              <p>{I18n.t('Click "Proceed" to continue.')}</p>
              <p>{I18n.t('Click "Cancel" if you donʼt want the code displayed.')}</p>
            </Text>
          </View>
        </Modal.Body>
        <Modal.Footer>
          <Button data-testid="qr-cancel-button" margin="none x-small" onClick={onModalCancel}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            data-testid="qr-proceed-button"
            color="primary"
            margin="none x-small"
            onClick={onModalProceed}
          >
            {I18n.t('Proceed')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}

QRMobileLogin.defaultProps = {
  refreshInterval: REFRESH_INTERVAL,
  pollInterval: POLL_INTERVAL,
  withWarning: false,
}
