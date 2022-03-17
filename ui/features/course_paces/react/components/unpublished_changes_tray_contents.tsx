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

import {View} from '@instructure/ui-view'
import {CloseButton} from '@instructure/ui-buttons'
import {List} from '@instructure/ui-list'
import {Text} from '@instructure/ui-text'
import React from 'react'
// @ts-ignore: TS doesn't understand i18n scoped imports
import {useScope as useI18nScope} from '@canvas/i18n'
import {SummarizedChange} from '../utils/change_tracking'

const I18n = useI18nScope('unpublished_changes_tray_contents')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item} = List as any

export type UnpublishedChangesTrayProps = {
  changes?: SummarizedChange[]
  handleTrayDismiss: () => void
}

const UnpublishedChangesTrayContents = ({
  changes = [],
  handleTrayDismiss
}: UnpublishedChangesTrayProps) => {
  return (
    <View as="div" width="20rem" margin="0 auto large" padding="small">
      <CloseButton
        placement="end"
        offset="small"
        onClick={handleTrayDismiss}
        screenReaderLabel={I18n.t('Close')}
      />
      <View as="header" margin="0 0 medium">
        <h4>
          <Text weight="bold">{I18n.t('Unpublished Changes')}</Text>
        </h4>
      </View>
      <List margin="none" isUnstyled itemSpacing="small">
        {changes.map(c => c.summary && <Item key={c.id}>{c.summary}</Item>)}
      </List>
    </View>
  )
}

export default UnpublishedChangesTrayContents
