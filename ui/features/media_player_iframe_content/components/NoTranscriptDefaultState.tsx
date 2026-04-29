/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import ConfusedPanda from '@instructure/platform-images/assets/ConfusedPanda.svg'

const I18n = createI18nScope('CanvasMediaPlayer')

export function NoTranscriptDefaultState({canManageTranscripts}: {canManageTranscripts: boolean}) {
  return (
    <Flex
      gap="space16"
      alignItems="center"
      justifyItems="center"
      direction="column"
      height="100%"
      padding="space16"
    >
      <View maxWidth="102px">
        <img src={ConfusedPanda} alt="" style={{width: '100%'}} />
      </View>
      <Text size="descriptionPage" weight="weightImportant" lineHeight="lineHeight100">
        {I18n.t('There is no transcript yet.')}
      </Text>

      {canManageTranscripts && (
        <Text variant="contentSmall">{I18n.t('Request or upload to show transcript.')}</Text>
      )}
    </Flex>
  )
}
