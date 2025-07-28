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
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {IconDownloadSolid} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'

import ReportStatusPill from './ReportStatusPill'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('account_reports')

import {AccountReport} from '@canvas/account_reports/types'

type Props = {
  reportRun: AccountReport
}

export default function ReportRun({reportRun}: Props) {
  const messageText = reportRun.message || reportRun.parameters?.extra_text

  const formatDate = useDateTimeFormat('time.formats.medium')

  return (
    <View
      data-testid={`report_history_${reportRun.id}`}
      as="div"
      margin="none none small none"
      padding="small"
      borderWidth="none none small none"
    >
      <Flex alignItems="start" justifyItems="space-between">
        <Flex.Item>
          <Text>{formatDate(reportRun.created_at)}</Text>
        </Flex.Item>
        <Flex.Item>
          {reportRun.file_url && (
            <Link href={`${reportRun.file_url}?download_frd=1`} renderIcon={IconDownloadSolid}>
              <ScreenReaderContent>{I18n.t('Download report')}</ScreenReaderContent>
            </Link>
          )}
          <ReportStatusPill status={reportRun.status} />
        </Flex.Item>
      </Flex>
      {messageText && (
        <Text as="div" wrap="break-word">
          {messageText}
        </Text>
      )}
    </View>
  )
}
