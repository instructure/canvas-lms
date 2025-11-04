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

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {confirm} from '@canvas/instui-bindings/react/Confirm'
import {LinkInfo} from '@canvas/parse-link-header/parseLinkHeader'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {List} from '@instructure/ui-list'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useInfiniteQuery} from '@tanstack/react-query'
import * as React from 'react'
import {useOutletContext} from 'react-router-dom'
import {RenderInfiniteApiResult} from '../../../../common/lib/apiResult/RenderInfiniteApiResult'
import {
  DeleteContextControl,
  FetchControlsByDeployment,
  UpdateContextControl,
} from '../../../api/contextControls'
import {createDeployment, type DeleteDeployment} from '../../../api/deployments'
import {AccountId} from '../../../model/AccountId'
import {LtiRegistrationId} from '../../../model/LtiRegistrationId'
import {ToolDetailsOutletContext} from '../ToolDetails'
import {DeploymentAvailability} from './DeploymentAvailability'
import {mergeDeployments} from './mergeDeployments'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('lti_registrations')

export type ToolAvailabilityProps = {
  fetchControlsByDeployment: FetchControlsByDeployment
  deleteContextControl: DeleteContextControl
  editContextControl: UpdateContextControl
  accountId: AccountId
  deleteDeployment: DeleteDeployment
}

const ControlPageSize = 20

/**
 * Renders the availability of a tool across different deployments.
 * @param props
 * @returns
 */
export const ToolAvailability = (props: ToolAvailabilityProps) => {
  const {registration} = useOutletContext<ToolDetailsOutletContext>()

  const [creatingDeployment, setCreatingDeployment] = React.useState(false)

  const controlsQuery = useInfiniteQuery({
    queryKey: ['fetchControlsByDeployment', registration.id] as [string, LtiRegistrationId],
    queryFn: ({queryKey: [, registrationId], pageParam}) =>
      props.fetchControlsByDeployment(
        pageParam
          ? {url: pageParam.url}
          : {
              registrationId: registrationId,
              pageSize: ControlPageSize,
            },
      ),
    getNextPageParam: lastPage => {
      if ('links' in lastPage && lastPage.links !== undefined && 'next' in lastPage.links) {
        return lastPage.links.next
      } else {
        return null
      }
    },
    initialPageParam: null as LinkInfo | null,
  })

  return (
    <RenderInfiniteApiResult
      query={controlsQuery}
      onSuccess={({pages, fetchingMore, hasNextPage}) => {
        const deployments = pages.reduce((acc, ds) => ds.reduce(mergeDeployments, acc), [])
        return (
          <>
            <View margin="0 0 medium 0" as="div">
              <Heading level="h4">
                <Text
                  dangerouslySetInnerHTML={{
                    __html: I18n.t(
                      "Control %{app_name}'s availability and exceptions in Canvas, including setting exceptions for specific sub-accounts or courses. You can *view all of your sub-accounts* or consult the documentation for more information.",
                      {
                        app_name: registration.name,
                        wrappers: [
                          `<a id='view-subaccount-link' href='/accounts/${registration.account_id}/sub_accounts' style='text-decoration: underline'>$1</a>`,
                        ],
                      },
                    ),
                  }}
                />
              </Heading>
            </View>
            {deployments.length > 0 ? (
              <List isUnstyled margin="0" itemSpacing="small">
                {deployments.map(dep => (
                  <List.Item key={dep.id}>
                    <DeploymentAvailability
                      accountId={props.accountId}
                      key={dep.id}
                      deployment={dep}
                      registration={registration}
                      refetchControls={controlsQuery.refetch}
                      deleteControl={props.deleteContextControl}
                      editControl={props.editContextControl}
                      deleteDeployment={props.deleteDeployment}
                    />
                  </List.Item>
                ))}
              </List>
            ) : (
              <Alert variant="info" margin="0" renderCloseButtonLabel="">
                <Text>
                  {I18n.t(
                    "This tool hasn't been deployed to any sub-accounts or courses. To add availability and exceptions, first create a root account–level deployment. By default, the root account level deployment won’t be available to users, but you can adjust this after creation if needed.",
                  )}
                </Text>
                <Button
                  color="primary"
                  size="small"
                  margin="small 0 0 0"
                  interaction={creatingDeployment ? 'disabled' : 'enabled'}
                  onClick={async () => {
                    setCreatingDeployment(true)
                    try {
                      const result = await createDeployment({
                        registrationId: registration.id,
                        accountId: props.accountId,
                        available: false,
                      })
                      if (result._type === 'Success') {
                        controlsQuery.refetch()
                        showFlashAlert({
                          type: 'success',
                          message: I18n.t('Root-level deployment created'),
                        })
                      } else {
                        showFlashAlert({
                          type: 'error',
                          message: I18n.t('There was an error when creating the deployment'),
                        })
                      }
                    } finally {
                      setCreatingDeployment(false)
                    }
                  }}
                >
                  {I18n.t('Create Deployment')}
                </Button>
              </Alert>
            )}
            {hasNextPage && (
              <Flex as="div" margin="medium 0 0 0" alignItems="center" justifyItems="center">
                <Button
                  disabled={fetchingMore}
                  onClick={() => {
                    controlsQuery.fetchNextPage()
                  }}
                >
                  {I18n.t('Show More')}
                </Button>
              </Flex>
            )}
          </>
        )
      }}
    />
  )
}
