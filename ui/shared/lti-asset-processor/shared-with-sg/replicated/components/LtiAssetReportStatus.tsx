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
import {
  IconCompleteSolid,
  IconHourGlassSolid,
  IconInfoSolid,
  IconWarningSolid,
} from '@instructure/ui-icons'
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

type StatusDisplayProps = {
  title: string
  icon: JSX.Element

  linkThemeOverride?: React.ComponentProps<typeof Link>['themeOverride']
  linkDataPendo: string

  textColor: React.ComponentProps<typeof Text>['color']
}

const PROCESSING_PROGRESSES = ['Processing', 'Pending', 'PendingManual']

function summarizeReports(reports: LtiAssetReport[]): StatusDisplayProps {
  if (reports.some(report => report.priority > 0)) {
    return {
      title: I18n.t('Please review'),
      icon: <IconWarningSolid color="error" />,
      linkThemeOverride: {
        color: canvas.colors.ui.textError,
        hoverColor: canvas.colors.ui.textError,
      },
      linkDataPendo: 'asset-reports-needs-attention-button',
      textColor: 'danger',
    }
  }
  if (reports.some(report => PROCESSING_PROGRESSES.includes(report.processingProgress))) {
    return {
      title: I18n.t('Processing'),
      icon: <IconHourGlassSolid color="brand" />,
      linkDataPendo: 'asset-reports-processing-button',
      textColor: 'brand',
    }
  }
  if (reports.some(report => report.processingProgress === 'Processed')) {
    return {
      title: I18n.t('All good'),
      icon: <IconCompleteSolid color="brand" />,
      linkDataPendo: 'asset-reports-all-good-button',
      textColor: 'brand',
    }
  }
  return {
    title: I18n.t('No result'),
    icon: <IconInfoSolid color="brand" />,
    linkDataPendo: 'asset-reports-no-results-info-button',
    textColor: 'brand',
  }
}

/**
 * Stateless/presentational component to render the status of LTI Asset Reports for a student.
 */
export default function LtiAssetReportStatus({
  reports,
  textSize,
  textWeight,
  openModal,
}: Props): JSX.Element {
  if (reports.length === 0) {
    return <Text>{I18n.t('No result')}</Text>
  }

  const statusDisplayProps: StatusDisplayProps = summarizeReports(reports)

  if (openModal) {
    return (
      <Link
        onClick={event => {
          event.preventDefault()
          openModal()
        }}
        renderIcon={statusDisplayProps.icon}
        variant="inline"
        themeOverride={statusDisplayProps.linkThemeOverride}
        data-pendo={statusDisplayProps.linkDataPendo}
        aria-haspopup="dialog"
      >
        {statusDisplayProps.title}
      </Link>
    )
  }
  return (
    <Text
      size={textSize ?? 'descriptionPage'}
      weight={textWeight ?? 'weightImportant'}
      color={statusDisplayProps.textColor}
    >
      <Flex display="flex" gap="xx-small">
        {statusDisplayProps.icon}
        {statusDisplayProps.title}
      </Flex>
    </Text>
  )
}
