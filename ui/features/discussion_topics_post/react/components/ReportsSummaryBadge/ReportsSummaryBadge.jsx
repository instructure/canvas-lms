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

import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {REPORT_TYPES} from '../ReportReply/ReportReply'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'

const I18n = useI18nScope('discussion_posts')

export const ReportsSummaryBadge = props => {
  return (
    <Flex.Item overflowY="hidden" padding="xx-small" data-testid="reports-summary-badge">
      <Tooltip
        renderTip={
          <View>
            <Heading level="h4">{I18n.t('Summary of Report Types')}</Heading>
            {REPORT_TYPES.map(reportType => {
              return (
                <li key={reportType.value}>
                  {reportType.getLabel()}: {props.reportTypeCounts[reportType.value + 'Count']}
                </li>
              )
            })}
          </View>
        }
      >
        <View borderRadius="pill" borderWidth="0" background="danger" display="inline-block">
          <Text color="primary-inverse" size="small" data-testid="reports-total">
            {props.reportTypeCounts.total}
          </Text>
        </View>
      </Tooltip>
    </Flex.Item>
  )
}

ReportsSummaryBadge.propTypes = {
  reportTypeCounts: PropTypes.object,
}
