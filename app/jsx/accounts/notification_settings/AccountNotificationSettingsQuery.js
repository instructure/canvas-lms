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

import {ACCOUNT_NOTIFICATIONS_QUERY} from './graphqlData/Queries'
import AccountNotificationSettingsManager from './AccountNotificationSettingsManager'
import errorShipUrl from 'jsx/shared/svg/ErrorShip.svg'
import GenericErrorPage from 'jsx/shared/components/GenericErrorPage'
import I18n from 'i18n!courses'
import LoadingIndicator from 'jsx/shared/LoadingIndicator'
import React from 'react'
import {string} from 'prop-types'
import {useQuery} from 'react-apollo'

export default function AccountNotificationSettingsQuery(props) {
  const {loading, error, data} = useQuery(ACCOUNT_NOTIFICATIONS_QUERY, {
    variables: {
      accountId: props.accountId,
      userId: props.userId
    }
  })

  if (loading) return <LoadingIndicator />
  if (error)
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Account Notification Settings initial query error')}
        errorCategory={I18n.t('Account Notification Settings Error Page')}
      />
    )

  return (
    <AccountNotificationSettingsManager
      accountId={props.accountId}
      notificationPreferences={data?.legacyNode?.notificationPreferences}
    />
  )
}

AccountNotificationSettingsQuery.propTypes = {
  accountId: string.isRequired,
  userId: string.isRequired
}
