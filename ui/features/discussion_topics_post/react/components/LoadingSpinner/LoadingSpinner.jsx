/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('discussion_topics_post')

const LoadingSpinnerBase = props => {
  let size = 'medium'
  if (props.breakpoints.mobileOnly) {
    size = 'small'
  } else if (props.breakpoints.desktop) {
    size = 'large'
  }
  return (
    <View
      as="div"
      width="100%"
      textAlign="center"
      position="absolute"
      style={{top: 'calc(50% - 80px)'}}
    >
      <Spinner renderTitle={I18n.t('Loading')} size={size} margin="0" />
    </View>
  )
}

LoadingSpinnerBase.propTypes = {
  breakpoints: breakpointsShape,
}

export const LoadingSpinner = WithBreakpoints(LoadingSpinnerBase)
