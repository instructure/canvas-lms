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
import {View} from '@instructure/ui-view'
import PropTypes from 'prop-types'
import LoadingSkeleton from './LoadingSkeleton'

export default function LoadingWrapper({
  children,
  isLoading,
  skeletonsCount = 1,
  screenReaderLabel = 'Loading',
  width = '100%',
  height = '10em',
  margin = 'small',
  borderWidth
}) {
  const skeletons = []
  for (let i = 0; i < skeletonsCount; i++) {
    skeletons.push(
      <View
        key={`skeleton-${i}`}
        display="inline-block"
        width={width}
        height={height}
        margin={margin}
        borderWidth={borderWidth}
        data-testid="skeleton-wrapper"
      >
        <LoadingSkeleton width="100%" height="100%" screenReaderLabel={screenReaderLabel} />
      </View>
    )
  }
  return isLoading ? skeletons : children
}

LoadingWrapper.propTypes = {
  isLoading: PropTypes.bool.isRequired,
  children: PropTypes.node,
  skeletonsCount: PropTypes.number,
  screenReaderLabel: PropTypes.string.isRequired,
  width: PropTypes.string.isRequired,
  height: PropTypes.string.isRequired,
  margin: PropTypes.string,
  borderWidth: PropTypes.string
}
