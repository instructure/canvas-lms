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
import {Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {List} from '@instructure/ui-list'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useInfiniteQuery} from '@tanstack/react-query'
import * as React from 'react'
import {useOutletContext} from 'react-router-dom'
import {RenderInfiniteApiResult} from '../../../../common/lib/apiResult/RenderInfiniteApiResult'
import {fetchControlsByDeployment} from '../../../api/contextControls'
import {createDeployment} from '../../../api/deployments'
import {AccountId} from '../../../model/AccountId'
import {LtiRegistrationId} from '../../../model/LtiRegistrationId'
import {ToolDetailsOutletContext} from '../ToolDetails'
import {DeploymentAvailability} from './DeploymentAvailability'
import {mergeDeployments} from './mergeDeployments'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('lti_registrations')

export type ToolAvailabilityProps = {
  fetchControlsByDeployment: typeof fetchControlsByDeployment
  accountId: AccountId
}

const ControlPageSize = 20

/**
 * Renders the availability of a tool across different deployments.
 * @param props
 * @returns
 */
export const ToolAvailability = (props: ToolAvailabilityProps) => {
  const {registration} = useOutletContext<ToolDetailsOutletContext>()

  const [debug, setDebug] = React.useState(false)

  // TODO: Remove this when debug mode is no longer needed
  // Add keyboard shortcut for CMD+d to toggle debug mode
  React.useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      // CMD+d (Mac) or CTRL+d (Windows/Linux)
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'd') {
        e.preventDefault()
        setDebug(d => !d)
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [])

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
                      "Control %{app_name}'s availability and exceptions in Canvas, including setting exceptions for specific sub-accounts or courses. You can *view all of your sub-accounts* or **consult the documentation** for more information.",
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
                      debug={debug}
                    />
                  </List.Item>
                ))}
              </List>
            ) : (
              <Text fontStyle="italic">
                {I18n.t('This tool has not been deployed to any sub-accounts or courses.')}
              </Text>
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
            {debug && (
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
                          controlsQuery.refetch()
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
            )}
          </>
        )
      }}
    />
  )
}
