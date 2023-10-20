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

import React, {useState, useEffect, useRef} from 'react'
import {View} from '@instructure/ui-view'
import PropTypes from 'prop-types'
import LoadingSkeleton from './LoadingSkeleton'

const SKELETONS_IF_ZERO = 1

export default function LoadingWrapper({
  id,
  children,
  isLoading,
  skeletonsNum = 1, // this is the value we want to cache
  // initial number of skeletons to show the first time
  // when nothing is in the cache
  defaultSkeletonsNum = 1,
  screenReaderLabel = 'Loading',
  display = 'block',
  width = '100%',
  height = '10em',
  margin = 'small',
  renderCustomSkeleton,
  renderSkeletonsContainer,
  renderLoadedContainer,
  // by default 0 skeletons can be rendered if the previous result was empty
  // to present at least 1 skeleton in that case
  // set allowZeroSkeletons prop to false.
  allowZeroSkeletons = true,
  persistInCache = true,
}) {
  const generateKey = index => `skeleton-${id}-${index}`
  const wasLoading = useRef(false)
  const skeletons = []
  const [skeletonsToRender, setSkeletonsToRender] = useState()

  useEffect(() => {
    if (isLoading !== wasLoading.current) {
      const cacheKey = `loading-skeletons-${id}-num`
      if (isLoading) {
        // if the wrapper has cache disable, skeletonsNum will be used always
        let skeletonsNumtoRender = skeletonsNum
        if (persistInCache) {
          // if the wrapper has the cache enable, it will look for the cached value from the previous run
          const cachedSkeletonsNum = parseInt(localStorage.getItem(cacheKey), 10)
          // if there is no a valid cached value, defaultSkeletonsNum will be used by default
          skeletonsNumtoRender = !Number.isNaN(cachedSkeletonsNum)
            ? cachedSkeletonsNum
            : defaultSkeletonsNum
        }
        // setting the number of skeletons to render, if zero skeletons is not allowed and the calculated number
        // is zero, SKELETONS_IF_ZERO will be used
        setSkeletonsToRender(
          !allowZeroSkeletons && skeletonsNumtoRender === 0
            ? SKELETONS_IF_ZERO
            : skeletonsNumtoRender
        )
      } else if (persistInCache && !Number.isNaN(skeletonsNum)) {
        try {
          localStorage.setItem(cacheKey, skeletonsNum)
        } catch (e) {
          // eslint-disable-next-line no-console
          console.warn("Unable to save to localStorage, likely because it's out of space.")
        }
      }
    }
    wasLoading.current = isLoading
  }, [skeletonsNum, isLoading]) // eslint-disable-line react-hooks/exhaustive-deps

  for (let i = 0; i < skeletonsToRender; i++) {
    skeletons.push(
      // if renderCustomSkeleton prop is passed, it will be called 'skeletonsNum' times,
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
    [_propName]: props.renderCustomSkeleton ? PropTypes.string : PropTypes.string.isRequired,
  }
  return PropTypes.checkPropTypes(propType, props, 'prop', 'LoadingWrapper')
}

LoadingWrapper.propTypes = {
  id: PropTypes.string.isRequired,
  isLoading: PropTypes.bool.isRequired,
  children: PropTypes.node,
  skeletonsNum: PropTypes.number,
  defaultSkeletonsNum: PropTypes.number,
  screenReaderLabel: requiredIfNotCustom,
  width: requiredIfNotCustom,
  height: requiredIfNotCustom,
  display: PropTypes.string,
  margin: PropTypes.string,
  renderCustomSkeleton: PropTypes.func,
  renderSkeletonsContainer: PropTypes.func,
  renderLoadedContainer: PropTypes.func,
  allowZeroSkeletons: PropTypes.bool,
  persistInCache: PropTypes.bool,
}
