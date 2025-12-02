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

import React from 'react'
import {useQuery} from '@tanstack/react-query'
import {Modal} from '@instructure/ui-modal'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'
import ReportRun from './ReportRun'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {AccountReport} from '@canvas/account_reports/types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'

const I18n = createI18nScope('account_reports')

type Props = {
  accountId: string
  report: string
  updatedReport?: AccountReport
  closeModal: () => void
}

export default function ReportHistoryModal({accountId, report, updatedReport, closeModal}: Props) {
  const renderCloseButton = () => {
    return (
      <CloseButton
        placement="end"
        offset="small"
        onClick={closeModal}
        screenReaderLabel={I18n.t('Close')}
      />
    )
  }

  const {
    error,
    isLoading,
    data: reportHistory,
  } = useQuery<AccountReport[]>({
    queryKey: ['report', accountId, report],
    queryFn: async ({queryKey}) => {
      const [_key, accountId, report] = queryKey
      const {json} = await doFetchApi<AccountReport[]>({
        path: `/api/v1/accounts/${accountId}/reports/${report}`,
      })
      return json!
    },
  })

  const renderModalBody = () => {
    if (error) {
      return <Alert variant="error">{I18n.t('Failed loading report history')}</Alert>
    } else if (isLoading) {
      return <Spinner renderTitle={I18n.t('Loading report history...')} />
    } else if (reportHistory) {
      return (
        <Flex direction="column">
          {reportHistory.map(historyItem => (
            <Flex.Item key={historyItem.id}>
              <ReportRun
                reportRun={updatedReport?.id === historyItem.id ? updatedReport : historyItem}
              />
            </Flex.Item>
          ))}
        </Flex>
      )
    }
  }

  return (
    <Modal label={I18n.t('Report History')} open={true} size="large" onDismiss={closeModal}>
      <Modal.Header>
        {renderCloseButton()}
        <Heading>{I18n.t('Report History')}</Heading>
      </Modal.Header>
      <Modal.Body>{renderModalBody()}</Modal.Body>
    </Modal>
  )
}
