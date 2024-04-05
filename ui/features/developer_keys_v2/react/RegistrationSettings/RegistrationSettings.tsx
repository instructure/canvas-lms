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

import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import GenericErrorPage from '@canvas/generic-error-page/react'
import {useScope as useI18nScope} from '@canvas/i18n'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import page from 'page'
import * as React from 'react'
import type {LtiRegistration} from '../../model/LtiRegistration'
import type {DeveloperKey} from '../../model/api/DeveloperKey'
import {updateRegistrationOverlay} from '../dynamic_registration/registrationApi'
import {RegistrationOverlayForm} from './RegistrationOverlayForm'
import {createRegistrationOverlayStore} from './RegistrationOverlayState'

const I18n = useI18nScope('react_developer_keys')

export type RegistrationSettingsProps = {
  ctx: {
    params: {
      contextId: string
      developerKeyId: string
    }
  }
}

export type WithRequired<T, K extends keyof T> = T & {[P in K]-?: T[P]}
export type LtiRegistrationDevKey = WithRequired<DeveloperKey, 'lti_registration'>

const fetchDeveloperKey = (params: {
  queryKey: readonly [key: 'developerKey', accountId: string, developerKeyId: string]
}) => {
  return fetch(`/api/v1/accounts/${params.queryKey[1]}/developer_keys?id=${params.queryKey[2]}`)
    .then(resp => resp.json())
    .then(devKeys => devKeys[0] as DeveloperKey)
}

const useRequest = <A,>(fn: () => Promise<A>, deps: Array<unknown>) => {
  const state = React.useState<{
    status: 'loading' | 'error' | 'success' | 'error'
    data: A
    error: unknown
  }>({
    status: 'loading',
    data: null as any,
    error: null,
  })

  React.useEffect(() => {
    fn()
      .then(data => {
        state[1](() => ({
          status: 'success',
          data,
          error: null,
        }))
      })
      .catch(error => {
        state[1](() => ({
          status: 'error',
          error,
          data: null as any,
        }))
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps)

  return state[0]
}

export const RegistrationSettings = React.memo((props: RegistrationSettingsProps) => {
  const {contextId, developerKeyId} = props.ctx.params

  const devKeyData = useRequest(() => {
    return fetchDeveloperKey({queryKey: ['developerKey', contextId, developerKeyId] as const})
  }, [contextId, developerKeyId])

  return (
    <div>
      {(() => {
        switch (devKeyData.status) {
          case 'loading':
            return (
              <View as="div" height="20rem">
                <Flex justifyItems="center" alignItems="center" height="100%">
                  <Flex.Item>
                    <Spinner renderTitle={I18n.t('Loading')} />
                  </Flex.Item>
                </Flex>
              </View>
            )
          case 'error':
            return (
              <GenericErrorPage
                imageUrl={errorShipUrl}
                errorSubject="LTI Registration Error"
                error={devKeyData.error}
              />
            )
          case 'success': {
            const devKey = devKeyData.data
            const ltiRegistration = devKey.lti_registration
            if (typeof ltiRegistration !== 'undefined') {
              return (
                <RegistrationOverlayFormWrapper
                  contextId={contextId}
                  developerKeyName={devKey.name}
                  ltiRegistration={ltiRegistration}
                />
              )
            } else {
              return (
                <GenericErrorPage
                  imageUrl={errorShipUrl}
                  errorSubject="No LTI Registration"
                  error={devKeyData.error}
                />
              )
            }
          }
        }
      })()}
    </div>
  )
})

type RegistrationOverlayFormWrapperProps = {
  developerKeyName: string | null
  ltiRegistration: LtiRegistration
  contextId: string
}

const RegistrationOverlayFormWrapper = (props: RegistrationOverlayFormWrapperProps) => {
  const store = React.useRef(
    createRegistrationOverlayStore(props.developerKeyName, props.ltiRegistration)
  ).current
  const [saving, setSaving] = React.useState(false)
  return (
    <div>
      <RegistrationOverlayForm store={store} ltiRegistration={props.ltiRegistration} />

      <View margin="medium 0" as="div">
        <Flex justifyItems="end">
          <Button
            color="secondary"
            onClick={() => page(`/accounts/${props.contextId}/developer_keys`)}
            disabled={saving}
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            margin="0 0 0 small"
            disabled={saving}
            onClick={() => {
              setSaving(true)
              updateRegistrationOverlay(
                props.contextId,
                props.ltiRegistration.id,
                store.getState().state.registration
              )
                .then(() => {
                  page(`/accounts/${props.contextId}/developer_keys`)
                })
                .catch(err => {
                  showFlashError(I18n.t('An error ocurred.'))(err)
                  setSaving(false)
                })
            }}
          >
            {I18n.t('Save')}
          </Button>
        </Flex>
      </View>
    </div>
  )
}
