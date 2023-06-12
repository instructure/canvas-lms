// @ts-nocheck
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

import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import React from 'react'
import {useQuery} from 'react-apollo'
import {INTERNAL_SETTINGS_QUERY} from './graphql/Queries'
import {InternalSettingsData} from './types'
import {InternalSettingsManager} from './InternalSettingsManager'

const I18n = useI18nScope('internal-settings')

export const InternalSettingsQuery = () => {
  const {loading, error, data} = useQuery<InternalSettingsData>(INTERNAL_SETTINGS_QUERY)

  if (loading) return <LoadingIndicator />
  if (error)
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Internal Settings initial query error')}
        errorCategory={I18n.t('Internal Settings Error Page')}
      />
    )

  return (
    <>
      {data?.internalSettings && (
        <InternalSettingsManager internalSettings={data.internalSettings} />
      )}
    </>
  )
}
