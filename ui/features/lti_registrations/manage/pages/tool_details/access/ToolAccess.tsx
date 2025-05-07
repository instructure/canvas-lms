/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import * as React from 'react'
import {useOutletContext} from 'react-router-dom'
import {ToolDetailsOutletContext} from '../ToolDetails'
import {Button} from '@instructure/ui-buttons'
import {useApiResult} from '../../../../common/lib/apiResult/useApiResult'
import {createDeployment, deleteDeployment, fetchDeployments} from '../../../api/deployments'
import {confirm} from '@canvas/instui-bindings/react/Confirm'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('lti_registrations')

export const ToolAccess = () => {
  const {registration} = useOutletContext<ToolDetailsOutletContext>()

  const deployments = useApiResult(
    React.useCallback(
      () =>
        fetchDeployments({
          registrationId: registration.id,
          accountId: registration.account_id,
        }),
      [registration],
    ),
  )
  return (
    <div>
      Access page
      {(() => {
        switch (deployments.state._type) {
          case 'not_requested':
            return <div>Loading...</div>
          case 'error':
            return <div>{deployments.state.message}</div>
          case 'loaded':
          case 'reloading':
          case 'stale': {
            const data = deployments.state.data
            return (
              <ul>
                {data &&
                  data.map(dep => (
                    <li key={dep.id}>
                      {dep.context_name} - {dep.deployment_id}{' '}
                      <Button
                        onClick={() => {
                          confirm({
                            title: 'Delete Deployment',
                            message: 'Are you sure you want to delete this deployment?',
                            confirmButtonLabel: 'Delete',
                            cancelButtonLabel: 'Cancel',
                          }).then(confirmed => {
                            if (confirmed) {
                              // Call the API to delete the deployment
                              deleteDeployment({
                                registrationId: registration.id,
                                accountId: registration.account_id,
                                deploymentId: dep.id,
                              }).then(result => {
                                if (result._type === 'Success') {
                                  // Handle success (e.g., show a success message or refresh the deployments)
                                  deployments.refresh()
                                } else {
                                  console.log(result)
                                  showFlashAlert({
                                    type: 'error',
                                    message: I18n.t(
                                      'There was an error when deleting the deployment.',
                                    ),
                                  })
                                }
                              })
                            }
                          })
                        }}
                      >
                        Delete
                      </Button>
                    </li>
                  ))}
              </ul>
            )
          }
        }
      })()}
      <Button
        onClick={() => {
          confirm({
            title: 'Create Deployment',
            message: 'Are you sure you want to create a deployment?',
            confirmButtonLabel: 'Create',
            cancelButtonLabel: 'Cancel',
          }).then(confirmed => {
            if (confirmed) {
              // Call the API to create a deployment
              createDeployment({
                registrationId: registration.id,
                accountId: registration.account_id,
              }).then(result => {
                if (result._type === 'Success') {
                  // Handle success (e.g., show a success message or refresh the deployments)
                  deployments.refresh()
                } else {
                  console.log(result)
                  showFlashAlert({
                    type: 'error',
                    message: I18n.t('There was an error when creating the deployment.'),
                  })
                }
              })
            }
          })
        }}
      >
        Create Deployment
      </Button>
      {/* <pre>{JSON.stringify(deployments.state, null, 2)}</pre> */}
      {/* <pre>{JSON.stringify(registration, null, 2)}</pre> */}
    </div>
  )
}
