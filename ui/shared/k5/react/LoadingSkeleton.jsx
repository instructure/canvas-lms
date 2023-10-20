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
import {string} from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'

export default function LoadingSkeleton({screenReaderLabel, width, height, margin}) {
  return (
    <View as="div" maxWidth={width} height={height} margin={margin}>
      <div
        style={{
          display: 'inline-block',
          width: '100%',
          height: '100%',
          borderRadius: '0.25rem',
          background: 'linear-gradient(-90deg, #F5F5F5 5%, #E6E6E6 25%, #F5F5F5 40%)',
          backgroundSize: '500% 100%',
          animation: 'shimmer 2s ease-in infinite', // shimmer defined in k5_dashboard.scss
        }}
        data-testid="skeletonShimmerBox"
      />
      <ScreenReaderContent>{screenReaderLabel}</ScreenReaderContent>
    </View>
  )
}

LoadingSkeleton.propTypes = {
  screenReaderLabel: string.isRequired,
  width: string.isRequired,
  height: string.isRequired,
  margin: string,
}
