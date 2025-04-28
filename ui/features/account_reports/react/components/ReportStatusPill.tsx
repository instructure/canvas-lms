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

import {Pill} from '@instructure/ui-pill'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('account_reports')

type Props = {
  status: 'created' | 'running' | 'compiling' | 'complete' | 'error' | 'aborted'
}

export default function ReportStatusPill({status}: Props) {
  const statusPillText = {
    created: I18n.t('Pending'),
    running: I18n.t('Running'),
    compiling: I18n.t('Compiling'),
    complete: I18n.t('Completed'),
    error: I18n.t('Failed'),
    aborted: I18n.t('Canceled'),
  }

  const statusPillColor: Record<
    Props['status'],
    'alert' | 'info' | 'success' | 'danger' | 'warning' | 'primary' | undefined
  > = {
    created: undefined,
    running: 'info',
    compiling: 'info',
    complete: 'success',
    error: 'danger',
    aborted: 'warning',
  }

  const color = statusPillColor[status]
  return <Pill color={color}>{statusPillText[status]}</Pill>
}
