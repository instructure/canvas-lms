/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {IconArrowOpenStartLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {TextInput} from '@instructure/ui-text-input'
import * as React from 'react'
import {RegistrationOverlayForm} from '../RegistrationSettings/RegistrationOverlayForm'
import storeCreator from '../store/store'
import {useDynamicRegistrationState} from './DynamicRegistrationState'
import {getRegistrationToken} from './registrationApi'
import actions from '../actions/developerKeysActions'
import type {AnyAction} from 'redux'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import GenericErrorPage from '@canvas/generic-error-page/react'
import errorShipUrl from '@canvas/images/ErrorShip.svg'

const I18n = useI18nScope('react_developer_keys')
type DynamicRegistrationModalProps = {
  contextId: string
  store: ReturnType<typeof storeCreator>
}
export const DynamicRegistrationModal = (props: DynamicRegistrationModalProps) => {
  const dr = useDynamicRegistrationState(s => s)
  switch (dr.state.tag) {
    case 'closed':
      return null
    default:
      return (
        <Modal
          open={true}
          onDismiss={() => dr.close()}
          size="large"
          label="Modal Dialog: Hello World"
          shouldCloseOnDocumentClick={true}
          data-testid="dynamic-reg-modal"
        >
          <Modal.Header>
            <CloseButton
              onClick={() => dr.close()}
              offset="medium"
              placement="end"
              screenReaderLabel={I18n.t('Close')}
            />
            <Heading>{I18n.t('Register App')}</Heading>
          </Modal.Header>
          <DynamicRegistrationModalBody />
          <Modal.Footer>
            <DynamicRegistrationModalFooter {...props} />
          </Modal.Footer>
        </Modal>
      )
  }
}

const isValidUrl = (str: string) => {
  try {
    new URL(str)
    return true
  } catch (_) {
    return false
  }
}

const addParams = (url: string, params: Record<string, string>) => {
  const u = new URL(url)
  Object.entries(params).forEach(([key, value]) => {
    u.searchParams.set(key, value)
  })
  return u.toString()
}

type DynamicRegistrationModalBodyProps = {}

const DynamicRegistrationModalBody = (_props: DynamicRegistrationModalBodyProps) => {
  const state = useDynamicRegistrationState(s => s.state)
  const setUrl = useDynamicRegistrationState(s => s.setUrl)
  switch (state.tag) {
    case 'closed':
      return null
    case 'opened':
    case 'loading_registration_token':
      return (
        <Modal.Body>
          <TextInput
            value={state.dynamicRegistrationUrl}
            renderLabel={I18n.t('Dynamic Registration Url')}
            disabled={state.tag === 'loading_registration_token'}
            onChange={(_event, value) => {
              setUrl(value)
            }}
            data-testid="dynamic-reg-modal-url-input"
          />
        </Modal.Body>
      )
    case 'registering':
      return (
        <iframe
          src={addParams(state.dynamicRegistrationUrl, {
            openid_configuration: state.registrationToken.oidc_configuration_url,
            registration_token: state.registrationToken.token,
          })}
          style={{width: '100%', height: '600px', border: '0', display: 'block'}}
          title={I18n.t('Register App')}
          data-testid="dynamic-reg-modal-iframe"
        />
      )
    case 'loading_registration':
      return (
        <Modal.Body>
          <View as="div" height="20rem" data-testid="dynamic-reg-modal-loading-registration">
            <Flex justifyItems="center" alignItems="center" height="100%">
              <Flex.Item>
                <Spinner renderTitle={I18n.t('Loading')} />
              </Flex.Item>
            </Flex>
          </View>
        </Modal.Body>
      )
    case 'confirming':
    case 'closing_and_saving':
    case 'enabling_and_closing':
    case 'deleting':
      return (
        <Modal.Body>
          <div data-testid="dynamic-reg-modal-confirmation">
            <RegistrationOverlayForm
              store={state.overlayStore}
              ltiRegistration={state.registration}
            />
          </div>
        </Modal.Body>
      )
    case 'error':
      return (
        <Modal.Body>
          <GenericErrorPage
            imageUrl={errorShipUrl}
            error={state.error}
            errorCategory="Dynamic Registration"
          />
        </Modal.Body>
      )
  }
}

type DynamicRegistrationModalFooterProps = {
  store: ReturnType<typeof storeCreator>
  contextId: string
}

const DynamicRegistrationModalFooter = (props: DynamicRegistrationModalFooterProps) => {
  const {
    state,
    register,
    close,
    open,
    loadingRegistrationToken,
    enableAndClose,
    closeAndSaveOverlay,
    deleteKey,
    error,
  } = useDynamicRegistrationState(s => s)

  switch (state.tag) {
    case 'closed':
      return null
    case 'opened':
    case 'loading_registration_token':
      return (
        <>
          <Button color="secondary" margin="small" onClick={close}>
            Cancel
          </Button>
          <Button
            color="primary"
            margin="small"
            disabled={
              !isValidUrl(state.dynamicRegistrationUrl) ||
              state.tag === 'loading_registration_token'
            }
            onClick={() => {
              loadingRegistrationToken()
              getRegistrationToken(props.contextId)
                .then(token => {
                  register(props.contextId, token)
                })
                .catch(err => {
                  error(err instanceof Error ? err : undefined)
                })
            }}
            data-testid="dynamic-reg-modal-continue-button"
          >
            Continue
          </Button>
        </>
      )
    case 'registering':
    case 'loading_registration':
      return (
        <>
          <Button
            color="secondary"
            margin="small"
            onClick={() => open(state.dynamicRegistrationUrl)}
            renderIcon={IconArrowOpenStartLine}
          >
            Back
          </Button>
          <Button color="secondary" margin="small" onClick={close}>
            Cancel
          </Button>
        </>
      )
    case 'confirming':
    case 'closing_and_saving':
    case 'enabling_and_closing':
    case 'deleting': {
      const onFinish = () => {
        props.store.dispatch(
          // Redux types are really bad, hence the cast here...
          actions.getDeveloperKeys(
            `/api/v1/accounts/${props.contextId}/developer_keys`,
            true
          ) as unknown as AnyAction
        )
        close()
      }
      const buttonsDisabled = state.tag !== 'confirming'
      return (
        <>
          <Button
            color="secondary"
            margin="0 x-small"
            disabled={buttonsDisabled}
            onClick={() => {
              // eslint-disable-next-line promise/catch-or-return
              deleteKey(state.registration).then(onFinish)
            }}
          >
            {I18n.t('Delete')}
          </Button>
          <Button
            color="secondary"
            margin="0 x-small"
            disabled={buttonsDisabled}
            onClick={() => {
              // eslint-disable-next-line promise/catch-or-return
              closeAndSaveOverlay(
                props.contextId,
                state.registration,
                state.overlayStore.getState().state.registration
              ).then(onFinish)
            }}
          >
            {I18n.t('Save')}
          </Button>
          <Button
            color="primary"
            margin="0 x-small"
            disabled={buttonsDisabled}
            data-testid="dynamic-reg-modal-enable-and-close-button"
            onClick={() => {
              // eslint-disable-next-line promise/catch-or-return
              enableAndClose(
                props.contextId,
                state.registration,
                state.overlayStore.getState().state.registration
              ).then(onFinish)
            }}
          >
            {I18n.t('Enable & Close')}
          </Button>
        </>
      )
    }
    case 'error':
      return (
        <Button color="secondary" margin="small" onClick={close}>
          {I18n.t('Close')}
        </Button>
      )
  }
}
