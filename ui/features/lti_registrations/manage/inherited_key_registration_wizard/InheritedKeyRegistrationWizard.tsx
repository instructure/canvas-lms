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

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {useScope as useI18nScope} from '@canvas/i18n'
import * as React from 'react'
import {
  useInheritedKeyWizardState,
  type InheritedKeyWizardState,
} from './InheritedKeyRegistrationWizardState'
import type {InheritedKeyService} from './InheritedKeyService'
import type {AccountId} from '../model/AccountId'
import {InheritedKeyRegistrationReview} from './InheritedKeyRegistrationReview'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {formatApiResultError} from '../../common/lib/apiResult/ApiResult'
import {flashError} from 'jquery'

const I18n = useI18nScope('lti_registrations')

export type InheritedKeyRegistrationWizardProps = {
  service: InheritedKeyService
  accountId: AccountId
}

export const InheritedKeyRegistrationWizard = (props: InheritedKeyRegistrationWizardProps) => {
  const {fetchRegistrationByClientId} = props.service
  const {state, install, close, loaded} = useInheritedKeyWizardState()
  const label = I18n.t('Install App')

  React.useEffect(() => {
    if (state._type === 'RequestingRegistration') {
      // eslint-disable-next-line promise/catch-or-return
      fetchRegistrationByClientId(props.accountId, state.developerKeyId).then(result => {
        loaded(result)
      })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps -- we can't add state.developerKeyId here
  }, [fetchRegistrationByClientId, loaded, props.accountId, state._type])

  return (
    <Modal label={label} open={state.open} size="medium">
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={close}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{label}</Heading>
      </Modal.Header>

      <Modal.Body padding="medium">{renderBody(state)}</Modal.Body>
      <Modal.Footer>
        <Button
          data-testid="registration-wizard-next-button"
          color="secondary"
          type="submit"
          margin="small"
          onClick={close}
        >
          {I18n.t('Cancel')}
        </Button>
        <Button
          data-testid="registration-wizard-next-button"
          color="primary"
          type="submit"
          margin="small"
          disabled={state._type !== 'RegistrationLoaded'}
          onClick={() => {
            // set to installing,
            // then install the app???
            if (state._type === 'RegistrationLoaded' && state.result._type === 'Success') {
              install()
              // eslint-disable-next-line promise/catch-or-return
              props.service
                .bindGlobalLtiRegistration(props.accountId, state.result.data.id)
                .then(result => {
                  // redirect to the app list
                  // or show an error
                  if (result._type === 'Success') {
                    // show error
                    close()
                    setTimeout(() => {
                      state.onSuccessfulInstallation?.()
                    })
                  } else {
                    // eslint-disable-next-line no-console
                    console.error('Failed to install app', formatApiResultError(result))
                    close()
                    flashError(I18n.t('Failed to install app'))
                  }
                })
            }
          }}
        >
          {I18n.t('Install App')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

const renderBody = (state: InheritedKeyWizardState) => {
  if (state._type === 'RequestingRegistration' || state._type === 'Initial') {
    return (
      <Flex
        justifyItems="center"
        alignItems="center"
        height="200px"
        data-testid="dynamic-reg-modal-loading-registration"
      >
        <Flex.Item>
          <Spinner renderTitle={I18n.t('Loading')} />
        </Flex.Item>
        <Flex.Item>{I18n.t('Loading')}</Flex.Item>
      </Flex>
    )
  } else {
    return <InheritedKeyRegistrationReview result={state.result} />
  }
}
