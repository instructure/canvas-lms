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
  id,
  children,
  isLoading,
  skeletonsCount = 1,
  screenReaderLabel = 'Loading',
  display = 'block',
  width = '100%',
  height = '10em',
  margin = 'small',
  renderCustomSkeleton,
  renderSkeletonsContainer,
  renderLoadedContainer
}) {
  const generateKey = index => `skeleton-${id}-${index}`
  const skeletons = []

  for (let i = 0; i < skeletonsCount; i++) {
    skeletons.push(
      // if renderCustomSkeleton prop is passed, it will be called 'skeletonsCount' times,
      // delegating the job of rendering the skeletons to that callback
      renderCustomSkeleton?.({key: generateKey(i)}) || (
        // if no renderCustomSkeleton is provided, the default skeleton will be generated
        <View
          key={generateKey(i)}
          display={display}
          width={width}
          height={height}
          margin={margin}
          data-testid="skeleton-wrapper"
        >
          <LoadingSkeleton width="100%" height="100%" screenReaderLabel={screenReaderLabel} />
        </View>
      )
    )
  }

  if (isLoading) {
    // if renderSkeletonsContainer prop is passed, the skeletons will be passed to that callback to allow
    // custom rendering while loading
    return renderSkeletonsContainer?.(skeletons) || skeletons
  } else {
    // if renderLoadedContainer prop is passed, the children will be passed to that callback to allow
    // custom rendering when finish loading
    return renderLoadedContainer?.(children) || children
  }
}

const requiredIfNotCustom = (props, _propName, _componentName) => {
  const propType = {
    [_propName]: props.renderCustomSkeleton ? PropTypes.string : PropTypes.string.isRequired
  }
  return PropTypes.checkPropTypes(propType, props, 'prop', 'LoadingWrapper')
}

LoadingWrapper.propTypes = {
  id: PropTypes.string.isRequired,
  isLoading: PropTypes.bool.isRequired,
  children: PropTypes.node,
  skeletonsCount: PropTypes.number,
  screenReaderLabel: requiredIfNotCustom,
  width: requiredIfNotCustom,
  height: requiredIfNotCustom,
  display: PropTypes.string,
  margin: PropTypes.string,
  renderCustomSkeleton: PropTypes.func,
  renderSkeletonsContainer: PropTypes.func,
  renderLoadedContainer: PropTypes.func
}
