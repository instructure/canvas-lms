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

import {LtiAssetReportWithAsset} from '@canvas/lti/model/AssetReport'
import {colors} from '@instructure/canvas-theme'
import {IconCompleteSolid, IconWarningSolid} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ViewOwnProps} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('submissions_show_preview_asset_report_status')

interface Props {
  reports: LtiAssetReportWithAsset[]
  openModal?: (event: React.MouseEvent<ViewOwnProps, MouseEvent>) => void
}

export default function AssetReportStatus({reports, openModal}: Props) {
  if (reports.length === 0) {
    return <Text>{I18n.t('No result')}</Text>
  }
  const hasHighPriority = reports.some(report => report.priority > 0)
  if (hasHighPriority) {
    return renderStatus('high', openModal)
  } else {
    return renderStatus('ok', openModal)
  }
}

function renderStatus(
  status: 'high' | 'ok',
  openModal?: (event: React.MouseEvent<ViewOwnProps, MouseEvent>) => void,
) {
  if (openModal) {
    return (
      <Link
        href="#"
        onClick={openModal}
        renderIcon={status === 'ok' ? <IconCompleteSolid /> : <IconWarningSolid color="error" />}
        variant="inline"
        themeOverride={
          status === 'ok' ? {} : {color: colors.ui.textError, hoverColor: colors.ui.textError}
        }
        data-pendo={`asset-processors-student-view-${status === 'high' ? 'needs-attention' : 'all-good'}-button`}
      >
        {status === 'ok' ? I18n.t('All good') : I18n.t('Needs attention')}
      </Link>
    )
  } else {
    return (
      <Text
        size="descriptionPage"
        weight="weightImportant"
        color={status === 'ok' ? 'brand' : 'danger'}
      >
        <Flex display="flex" gap="xx-small">
          {status === 'ok' ? (
            <IconCompleteSolid color="brand" />
          ) : (
            <IconWarningSolid color="error" />
          )}
          {status === 'ok' ? I18n.t('All good') : I18n.t('Needs attention')}
        </Flex>
      </Text>
    )
  }
}
