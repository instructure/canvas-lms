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
import React, {useEffect, useState} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {Heading} from '@instructure/ui-heading'
import ReportsTable from './ReportsTable'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {AccountReportInfo} from '@canvas/account_reports/types'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('account_reports')

type Props = {
  accountId: string
}
export default function AccountReportView({accountId}: Props) {
  const [reports, setReports] = useState<AccountReportInfo[]>([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    async function fetchAccountReports() {
      setIsLoading(true)
      try {
        const {json} = await doFetchApi<AccountReportInfo[]>({
          path: `/api/v1/accounts/${accountId}/reports`,
          params: {include: ['description_html', 'parameters_html']},
        })
        setReports(json!)
      } catch (error) {
        showFlashError(I18n.t('Failed to load available reports'))(error as Error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchAccountReports()
  }, [accountId])

  return (
    <>
      <Heading variant="titlePageDesktop">{I18n.t('Reports')}</Heading>

      {isLoading ? (
        <Spinner renderTitle={I18n.t('Loading reports...')} />
      ) : (
        <ReportsTable reports={reports} accountId={accountId} />
      )}
    </>
  )
}
