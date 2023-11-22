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
import {Modal} from '@instructure/ui-modal'
import {TextInput} from '@instructure/ui-text-input'
import * as React from 'react'
import {useDynamicRegistrationState} from './DynamicRegistrationState'
import {IconArrowLeftLine} from '@instructure/ui-icons'
import storeCreator from '../store/store'
import actions from '../actions/developerKeysActions'
import {AnyAction} from 'redux'

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

type DynamicRegistrationModalBodyProps = {}

const DynamicRegistrationModalBody = (_props: DynamicRegistrationModalBodyProps) => {
  const state = useDynamicRegistrationState(s => s.state)
  const setUrl = useDynamicRegistrationState(s => s.setUrl)
  switch (state.tag) {
    case 'closed':
      return null
    case 'opened':
      return (
        <Modal.Body>
          <TextInput
            value={state.dynamicRegistrationUrl}
            renderLabel={I18n.t('Dynamic Registration Url')}
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
          title={I18n.t('Register App')}
          data-testid="dynamic-reg-modal-iframe"
          src={`/api/lti/register?registration_url=${state.dynamicRegistrationUrl}`}
          style={{width: '100%', height: '600px', border: '0', display: 'block'}}
        />
      )
  }
}

type DynamicRegistrationModalFooterProps = {
  store: ReturnType<typeof storeCreator>
  contextId: string
}

const DynamicRegistrationModalFooter = (props: DynamicRegistrationModalFooterProps) => {
  const {state, register, close, open} = useDynamicRegistrationState(s => s)

  switch (state.tag) {
    case 'closed':
      return null
    case 'opened':
      return (
        <>
          <Button color="secondary" margin="small" onClick={close}>
            Cancel
          </Button>
          <Button
            color="primary"
            margin="small"
            disabled={!isValidUrl(state.dynamicRegistrationUrl)}
            onClick={() => {
              register(state.dynamicRegistrationUrl, () => {
                props.store.dispatch(
                  // Redux types are really bad, hence the cast here...
                  actions.getDeveloperKeys(
                    `/api/v1/accounts/${props.contextId}/developer_keys`,
                    true
                  ) as unknown as AnyAction
                )
              })
            }}
            data-testid="dynamic-reg-modal-continue-button"
          >
            Continue
          </Button>
        </>
      )
    case 'registering':
      return (
        <>
          <Button
            color="secondary"
            margin="small"
            onClick={() => open(state.dynamicRegistrationUrl)}
            renderIcon={IconArrowLeftLine}
          >
            Back
          </Button>
          <Button color="secondary" margin="small" onClick={close}>
            Cancel
          </Button>
        </>
      )
  }
}
