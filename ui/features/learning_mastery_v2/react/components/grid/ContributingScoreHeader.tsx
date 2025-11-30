/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {TruncateText} from '@instructure/ui-truncate-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {CELL_HEIGHT, COLUMN_WIDTH, SortBy, SortOrder} from '../../utils/constants'

const I18n = createI18nScope('learning_mastery_gradebook')

export interface ContributingScoreHeaderProps {
  label: string
}

export const ContributingScoreHeader: React.FC<ContributingScoreHeaderProps> = ({label}) => (
  <View
    background="secondary"
    as="div"
    width={COLUMN_WIDTH}
    borderWidth="large 0 medium 0"
    data-testid="outcome-header"
  >
    <Flex alignItems="center" justifyItems="space-between" height={CELL_HEIGHT}>
      <Flex.Item size="80%" padding="0 0 0 small">
        <TruncateText>
          <Text weight="bold">{label}</Text>
        </TruncateText>
      </Flex.Item>
    </Flex>
  </View>
)
