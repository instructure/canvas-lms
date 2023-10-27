/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import HistoryList from '../lists/HistoryList'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'

const I18n = useI18nScope('new_nav')

export default function HistoryTray() {
  return (
    <View as="div" padding="medium">
      <Heading level="h3" as="h2">
        {I18n.t('Recent History')}
      </Heading>
      <hr role="presentation" />
      <HistoryList />
    </View>
  )
}
