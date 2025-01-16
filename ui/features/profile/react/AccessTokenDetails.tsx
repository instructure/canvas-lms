/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useState, type FormEventHandler, type ReactNode} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {raw} from '@instructure/html-escape'
import {Flex} from '@instructure/ui-flex'
import {datetimeString} from '@canvas/datetime/date-functions'
import './AccessTokenDetails.css'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {Spinner} from '@instructure/ui-spinner'
import type {Token} from './types'

const I18n = createI18nScope('profile')

type NetworkState = 'loaded' | 'loading' | 'error' | 'submitting'

export interface AccessTokenDetailsProps {
  url: string
  loadedToken?: Token
  userCanUpdateTokens: boolean
  onTokenLoad?: (token: Token) => void
  onClose: () => void
}

const AccessTokenDetails = ({
  url,
  loadedToken,
  userCanUpdateTokens,
  onTokenLoad,
  onClose,
}: AccessTokenDetailsProps) => {
  const [token, setToken] = useState(loadedToken)
  const [networkState, setNetworkState] = useState<NetworkState>(token ? 'loaded' : 'loading')
  const shouldShowTokenWarning = (token?.visible_token?.length ?? 0) > 10
  const title = I18n.t('Access Token Details')
  const buttonText =
    networkState === 'submitting' ? I18n.t('Regenerating token...') : I18n.t('Regenerate Token')

  const requestToken = useCallback(
    async ({
      method,
      body,
      handleError,
    }: {
      method: 'GET' | 'PUT'
      body?: object
      handleError: () => void
    }) => {
      try {
        const {json} = await doFetchApi<Token>({
          path: url,
          method,
          body,
        })

        setToken(json!)
        setNetworkState('loaded')
        onTokenLoad?.(json!)
      } catch {
        handleError()
      }
    },
    [onTokenLoad, url],
  )

  const handleSubmit: FormEventHandler = async event => {
    event.preventDefault()

    const isConfirmed = window.confirm(
      I18n.t(
        'Are you sure you want to regenerate this token?  Anything using this token will have to be updated.',
      ),
    )
    if (!isConfirmed) {
      return
    }

    setNetworkState('submitting')

    requestToken({
      method: 'PUT',
      body: {token: {regenerate: 1}},
      handleError: () => showFlashError(I18n.t('Failed to regenerate access token.'))(),
    })
  }

  useEffect(() => {
    if (!token) {
      requestToken({method: 'GET', handleError: () => setNetworkState('error')})
    }
  }, [requestToken, token])

  let details: ReactNode

  if (networkState === 'loading') {
    details = <Spinner renderTitle="Loading" size="large" margin="small auto" />
  }

  if (networkState === 'error') {
    details = <Text>{I18n.t('Failed to load access token details. Please try again later.')}</Text>
  }

  if (['loaded', 'submitting'].includes(networkState) && token) {
    details = (
      <div>
        <div className="access-token-details__list-item">
          <Text weight="bold">{I18n.t('Token')}</Text>
          <div>
            <Text wrap="break-word" data-testid="visible_token">
              {token.visible_token}
            </Text>
            <br />
            {shouldShowTokenWarning && (
              <Text
                size="small"
                wrap="break-word"
                dangerouslySetInnerHTML={{
                  __html: raw(
                    I18n.t(
                      "*Copy this token down now*. Once you leave this page you won't be able to retrieve the full token anymore, you'll have to regenerate it to get a new value.",
                      {wrapper: '<b>$1</b>'},
                    ),
                  ),
                }}
              />
            )}
          </div>
        </div>
        <div className="access-token-details__list-item">
          <Text weight="bold">{I18n.t('App')}</Text>
          <Text>{token.app_name}</Text>
        </div>
        <div className="access-token-details__list-item">
          <Text weight="bold">{I18n.t('Purpose')}</Text>
          <Text>{token.purpose}</Text>
        </div>
        <div className="access-token-details__list-item">
          <Text weight="bold">{I18n.t('Created')}</Text>
          <Text>{datetimeString(token.created_at) || '--'}</Text>
        </div>
        <div className="access-token-details__list-item">
          <Text weight="bold">{I18n.t('Last Used')}</Text>
          <Text>{datetimeString(token.last_used_at) || '--'}</Text>
        </div>
        <div className="access-token-details__list-item">
          <Text weight="bold">{I18n.t('Expires')}</Text>
          <Text>{datetimeString(token.expires_at) || I18n.t('never')}</Text>
        </div>
      </div>
    )
  }

  return (
    <Modal
      as="form"
      open={true}
      onDismiss={onClose}
      size="medium"
      label={title}
      shouldCloseOnDocumentClick={false}
      onSubmit={handleSubmit}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{title}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Flex direction="column" gap="medium">
          <Text
            dangerouslySetInnerHTML={{
              __html: raw(
                I18n.t(
                  'Access tokens can be used to allow other applications to make API calls on your behalf. You can also generate access tokens and *use the Canvas Open API* to come up with your own integrations.',
                  {
                    wrapper:
                      '<a href="https://canvas.instructure.com/doc/api/index.html" class="external" target="_blank" rel="noreferrer noopener">$1</a>',
                  },
                ),
              ),
            }}
          />
          {details}
        </Flex>
      </Modal.Body>
      {userCanUpdateTokens && (
        <Modal.Footer>
          <Tooltip
            renderTip={I18n.t('An expired token cannot be regenerated')}
            on={token && !token.can_manually_regenerate ? ['hover', 'focus'] : []}
          >
            <Button
              type="submit"
              color="primary"
              aria-label={buttonText}
              disabled={networkState === 'submitting' || !token?.can_manually_regenerate}
            >
              {buttonText}
            </Button>
          </Tooltip>
        </Modal.Footer>
      )}
    </Modal>
  )
}

export default AccessTokenDetails
