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

import I18n from 'i18n!QRMobileLogin'
import React, {useState, useEffect} from 'react'
import {showFlashAlert} from 'jsx/shared/FlashAlert'
import doFetchApi from 'jsx/shared/effects/doFetchApi'

import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Img} from '@instructure/ui-img'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import moment from 'moment'
import {object} from 'prop-types'

const REFRESH_INTERVAL = moment.duration(9.75, 'minutes') // 9 min 45 sec
const POLL_INTERVAL = moment.duration(5, 'seconds')
const QR_CODE_LIFETIME = moment.duration(10, 'minutes')

export function QRMobileLogin({refreshInterval, pollInterval}) {
  const [imagePng, setImagePng] = useState(null)
  const [validFor, setValidFor] = useState(null)

  function renderQRCode() {
    const body = imagePng ? (
      <span className="fs-exclude">
        <Img
          alt={I18n.t('QR Code Image')}
          constrain="contain"
          data-testid="qr-code-image"
          src={`data:image/png;base64, ${imagePng}`}
        />
      </span>
    ) : (
      <Spinner
        data-testid="qr-code-spinner"
        renderTitle={I18n.t('Waiting for your QR Code to load')}
      />
    )
    return (
      <View display="block" textAlign="center" padding="small xx-large">
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
    <Flex direction="column" justifyItems="center" margin="none medium">
      <Flex.Item margin="xx-small" padding="xx-small">
        <Heading level="h1">{I18n.t('QR for Mobile Login')}</Heading>
      </Flex.Item>
      <Flex.Item>
        <View {...flexViewProps}>
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
        </View>
      </Flex.Item>
    </Flex>
  )
}

const flexViewProps = {
  borderColor: 'primary',
  borderWidth: 'small',
  borderRadius: 'medium',
  padding: 'medium',
  margin: 'medium small',
  maxWidth: '30rem',
  as: 'div'
}

QRMobileLogin.propTypes = {
  refreshInterval: object,
  pollInterval: object
}

QRMobileLogin.defaultProps = {
  refreshInterval: REFRESH_INTERVAL,
  pollInterval: POLL_INTERVAL
}
