/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import I18n from 'i18n!courses'
import React from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

export default function LoadingIndicator() {
  return (
    <View as="div" height="100%" width="100%" textAlign="center">
      <Spinner renderTitle={I18n.t('Loading')} size="large" margin="0 0 0 medium" />
    </View>
  )
}
