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
import React from 'react'
import {oneOf, string} from 'prop-types'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-layout'

export default function LoadingIndicator({translatedTitle, size}) {
  return (
    <View as="div" height="100%" width="100%" textAlign="center">
      <Spinner renderTitle={() => translatedTitle} size={size} margin="0 0 0 medium" />
    </View>
  )
}

LoadingIndicator.propTypes = {
  translatedTitle: string.isRequired,
  size: oneOf(['x-small', 'small', 'medium', 'large'])
}
LoadingIndicator.defaultProps = {
  size: 'large'
}
