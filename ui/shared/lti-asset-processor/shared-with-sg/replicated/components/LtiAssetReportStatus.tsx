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

import {Flex} from '@instructure/ui-flex'
import {IconCompleteSolid, IconWarningSolid} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {canvas} from '@instructure/ui-themes'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {LtiAssetReport} from '../types/LtiAssetReports'

const I18n = createI18nScope('lti_asset_processor')

interface Props {
  reports: LtiAssetReport[]
  textSize?: Text['props']['size']
  textWeight?: Text['props']['weight']
  openModal?: () => void
}

/**
 * Stateless/presentational component to render the status of LTI Asset Reports for a student.
 */
export default function LtiAssetReportStatus({
  reports,
  ...propsForRenderStatus
}: Props): JSX.Element {
  if (reports.length === 0) {
    return <Text>{I18n.t('No result')}</Text>
  }
  const hasHighPriority = reports.some(report => report.priority > 0)
  if (hasHighPriority) {
    return renderStatus('high', propsForRenderStatus)
  }
  return renderStatus('ok', propsForRenderStatus)
}

function renderStatus(
  status: 'high' | 'ok',
  {textSize, textWeight, openModal}: Omit<Props, 'reports'>,
) {
  if (openModal) {
    return (
      <Link
        onClick={event => {
          event.preventDefault()
          openModal()
        }}
        renderIcon={status === 'ok' ? <IconCompleteSolid /> : <IconWarningSolid color="error" />}
        variant="inline"
        themeOverride={
          status === 'ok'
            ? {}
            : {
                color: canvas.colors.ui.textError,
                hoverColor: canvas.colors.ui.textError,
              }
        }
        data-pendo={`asset-reports-${status === 'high' ? 'needs-attention' : 'all-good'}-button`}
      >
        {status === 'ok' ? I18n.t('All good') : I18n.t('Needs attention')}
      </Link>
    )
  }
  return (
    <Text
      size={textSize ?? 'descriptionPage'}
      weight={textWeight ?? 'weightImportant'}
      color={status === 'ok' ? 'brand' : 'danger'}
    >
      <Flex display="flex" gap="xx-small">
        {status === 'ok' ? <IconCompleteSolid color="brand" /> : <IconWarningSolid color="error" />}
        {status === 'ok' ? I18n.t('All good') : I18n.t('Needs attention')}
      </Flex>
    </Text>
  )
}
