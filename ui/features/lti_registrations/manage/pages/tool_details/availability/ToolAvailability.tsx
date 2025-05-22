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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {List} from '@instructure/ui-list'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import * as React from 'react'
import {Link as RouterLink, useOutletContext} from 'react-router-dom'
import {useApiResult} from '../../../../common/lib/apiResult/useApiResult'
import {fetchControlsByDeployment} from '../../../api/contextControls'
import {AccountId} from '../../../model/AccountId'
import {ToolDetailsOutletContext} from '../ToolDetails'
import {ApiResultErrorPage} from '../../../../common/lib/apiResult/ApiResultErrorPage'
import {matchApiResultState} from '../../../../common/lib/apiResult/matchApiResultState'

const I18n = createI18nScope('lti_registrations')

export type ToolAvailabilityProps = {
  fetchControlsByDeployment: typeof fetchControlsByDeployment
  accountId: AccountId
}

export const ToolAvailability = (props: ToolAvailabilityProps) => {
  const {registration} = useOutletContext<ToolDetailsOutletContext>()

  const {state} = useApiResult(
    React.useCallback(
      () =>
        props.fetchControlsByDeployment({
          registrationId: registration.id,
        }),
      [registration, props.fetchControlsByDeployment, registration.id],
    ),
  )
  return (
    <div>
      {matchApiResultState(state)({
        loading: () => (
          <Flex direction="column" alignItems="center" padding="large 0">
            <Spinner renderTitle="Loading" />
          </Flex>
        ),
        error: error => (
          <ApiResultErrorPage error={error} errorSubject={I18n.t('Error loading deployments')} />
        ),
        data: deployments => (
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
                    <View
                      borderRadius="medium"
                      borderColor="secondary"
                      borderWidth="small"
                      padding="medium"
                      as="div"
                    >
                      <Heading level="h3">
                        {I18n.t('Installed in %{context_name}', {
                          context_name: dep.context_name,
                        })}
                      </Heading>
                      <div>
                        <Text>
                          {I18n.t('Deployment ID: %{deployment_id}', {
                            deployment_id: dep.deployment_id,
                          })}
                        </Text>
                      </div>
                      <div>
                        <Text>
                          <Link
                            to={`/manage/${registration.id}/configuration#placements`}
                            as={RouterLink}
                          >
                            {I18n.t('%{number_of_placements} placements', {
                              number_of_placements: registration.configuration.placements.length,
                            })}
                          </Link>
                        </Text>
                      </div>
                    </View>
                  </List.Item>
                ))}
              </List>
            ) : (
              <Text fontStyle="italic">
                {I18n.t('This tool has not been deployed to any sub-accounts or courses.')}
              </Text>
            )}
          </>
        ),
      })}
    </div>
  )
}
