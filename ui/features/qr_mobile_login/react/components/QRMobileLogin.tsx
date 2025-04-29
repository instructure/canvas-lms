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

import {useScope as createI18nScope} from '@canvas/i18n'
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

const I18n = createI18nScope('QRMobileLogin')

const POLL_INTERVAL = 1000 // 1 second
const QR_CODE_LIFETIME = 1000 * 10 * 60 // 10 minutes

// UI state
enum State {
  warning, // waiting for the user to confirm the display of the QR code
  canceled, // the user canceled the display of the QR code
  displayed, // the QR code is being displayed
}

type LoginPngApiResponse = {
  png: string
}

const modalLabel = () => I18n.t('Confirm QR code display')

export interface QRMobileLoginProps {
  refreshInterval?: number
  pollInterval?: number
  withWarning?: boolean
}

const defaultProps: Required<QRMobileLoginProps> = {
  refreshInterval: QR_CODE_LIFETIME,
  pollInterval: POLL_INTERVAL,
  withWarning: false,
}

export function QRMobileLogin(props: QRMobileLoginProps): JSX.Element {
  const {refreshInterval, pollInterval, withWarning} = {...defaultProps, ...props}

  const [imagePng, setImagePng] = useState<string | null>(null)
  const [validFor, setValidFor] = useState('')
  const [display, setDisplay] = useState<State>(withWarning ? State.warning : State.displayed)

  function renderQRCode() {
    let body

    switch (display) {
      case State.canceled:
        body = <Text size="large">{I18n.t('QR code display was canceled')}</Text>
        break

      case State.warning:
        body = (
          <Spinner
            data-testid="qr-code-spinner"
            renderTitle={I18n.t('Waiting for confirmation to display QR code')}
          />
        )
        break

      case State.displayed:
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
        {display !== State.canceled && (
          <View display="block">
            {I18n.t(
              'To log in to your Canvas account when you’re on the go, scan this QR code from any Canvas mobile app.',
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
    setDisplay(State.displayed)
  }

  function onModalCancel() {
    setDisplay(State.canceled)
  }

  function startTimedEvents() {
    let timerId: NodeJS.Timeout | null = null
    let isFetching = false
    let refetchAt: number | null = null
    let expireAt: number | null = null

    function displayValidFor(): void {
      if (expireAt === null) return
      const newValidFor =
        Date.now() < expireAt
          ? I18n.t('This code will expire %{inThisAmountOfTime}.', {
              inThisAmountOfTime: fromNow(expireAt),
            })
          : I18n.t('This code has expired. Wait a few seconds for a new one...')
      setValidFor(newValidFor)
    }

    async function getQRCode() {
      isFetching = true
      try {
        refetchAt = null
        const {json} = await doFetchApi<LoginPngApiResponse>({
          path: '/canvas/login.png',
          method: 'POST',
        })
        refetchAt = Date.now() + refreshInterval
        if (json) {
          expireAt = Date.now() + QR_CODE_LIFETIME
          displayValidFor()
          setImagePng(json.png)
        } else throw new RangeError('No QR code was made available')
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
      if (!isFetching && (!refetchAt || Date.now() > refetchAt)) getQRCode()
      else displayValidFor()
      timerId = setTimeout(poll, pollInterval)
    }

    if (display === State.displayed) poll()

    return () => {
      if (timerId !== null) clearTimeout(timerId)
    }
  }

  useEffect(startTimedEvents, [display, pollInterval, refreshInterval])

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
            {validFor && display === State.displayed && (
              <Text weight="light" size="small">
                {validFor}
              </Text>
            )}
          </View>
        </Flex.Item>
      </Flex>
      <Modal
        size="small"
        open={display === State.warning}
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
                  {canvas: 'Canvas'},
                )}
              </p>
              <p>
                {I18n.t(
                  'Please make sure no one is able to capture the image on your screen from your surroundings or from a screen sharing service.',
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
