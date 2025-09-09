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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Img} from '@instructure/ui-img'
import {useScope as createI18nScope} from '@canvas/i18n'
import celebratePandaUrl from '@canvas/images/CelebratePanda.svg'

const I18n = createI18nScope('block_content_editor')

export const NoIssuesContent = () => {
  return (
    <View padding="medium">
      <Flex direction="column" alignItems="center" gap="medium">
        <Flex.Item>
          <Text size="large" weight="bold">
            {I18n.t('No accessibility issues were detected.')}
          </Text>
        </Flex.Item>
        <Flex.Item>
          <Img src={celebratePandaUrl} alt={I18n.t('No accessibility issues were detected.')} />
        </Flex.Item>
      </Flex>
    </View>
  )
}
