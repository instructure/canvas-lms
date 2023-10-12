/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {Pill} from '@instructure/ui-pill'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('content_migrations_redesign')
export type Color = 'primary' | 'success' | 'danger' | 'info' | 'warning' | 'alert'

export const StatusPill = ({
  hasIssues,
  workflowState,
}: {
  hasIssues: boolean
  workflowState: string
}) => {
  let color: Color = 'primary'
  if (workflowState === 'completed') {
    if (hasIssues) {
      color = 'warning'
    } else {
      color = 'success'
    }
  } else if (workflowState === 'failed') {
    color = 'danger'
  } else if (workflowState === 'running' || workflowState === 'pre_processed') {
    color = 'info'
  }
  let text = ''
  if (workflowState === 'queued') {
    text = I18n.t('Queued')
  } else if (workflowState === 'pre_processing') {
    text = I18n.t('Created')
  } else if (workflowState === 'waiting_for_select') {
    text = I18n.t('Waiting for selection')
  } else if (workflowState === 'running' || workflowState === 'pre_processed') {
    text = I18n.t('Running')
  } else if (workflowState === 'failed') {
    text = I18n.t('Failed')
  } else if (workflowState === 'completed') {
    text = I18n.t('Completed')
  }

  return (
    <Pill margin="x-small" color={color} data-testid="migrationStatus">
      {text}
    </Pill>
  )
}

export default StatusPill
