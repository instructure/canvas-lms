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

import {BorderWidth} from '@instructure/emotion/types/styleUtils'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'

import {IssueCountBadge} from '../IssueCountBadge/IssueCountBadge'

interface IssueTypeSummaryRowProps {
  icon: React.ComponentType
  label: string
  count: number
  borderWidth: BorderWidth
}

const IssueTypeSummaryRow = ({icon, label, count, borderWidth}: IssueTypeSummaryRowProps) => {
  return (
    <View
      as="div"
      width="100%"
      borderWidth={borderWidth}
      padding="small"
      data-testid={`issue-summary-group-${label.toLowerCase().replace(/\s+/g, '-')}`}
    >
      <Flex justifyItems="space-between" alignItems="center">
        <Flex.Item>
          <Flex alignItems="center" gap="small">
            <Flex.Item>{React.createElement(icon)}</Flex.Item>
            <Flex.Item>
              <Text>{label}</Text>
            </Flex.Item>
          </Flex>
        </Flex.Item>

        {count && (
          <Flex.Item>
            <IssueCountBadge issueCount={count} />
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}

export default IssueTypeSummaryRow
