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

import React, {type ComponentType} from 'react'
import PropTypes from 'prop-types'
import {Responsive} from '@instructure/ui-responsive'

// from _breakpoints.scss
export const BREAKPOINTS = {
  miniTablet: {minWidth: '500px'},
  tablet: {minWidth: '768px'},
  desktop: {minWidth: '992px'},
  desktopNavOpen: {minWidth: '1140px'},
  desktopOnly: {minWidth: '768px'},
  mobileOnly: {maxWidth: '767px'},
}

const convertMatchesToProp = (matches: string[] | undefined) => {
  const breakpoints: Breakpoints = {}
  // @ts-expect-error
  ;(matches || []).forEach(match => (breakpoints[match] = true))
  return breakpoints
}

// could be class or functional component
export default function WithBreakpoints<T>(WrappedComponent: ComponentType<T>) {
  const EnhancedComponent: ComponentType<T & {breakpoints: Breakpoints}> = props => {
    // TODO: remove since our supported browsers support matchMedia
    // @ts-expect-error
    if (window.matchMedia) {
      return (
        <Responsive
          match="media"
          query={BREAKPOINTS}
          render={(_addedProps, matches) => (
            <WrappedComponent breakpoints={convertMatchesToProp(matches)} {...(props as T)} />
          )}
        />
      )
    } else {
      return <WrappedComponent breakpoints={{}} {...(props as T)} />
    }
  }

  // Return the new component
  return EnhancedComponent
}

export const breakpointsShape = PropTypes.shape({
  miniTablet: PropTypes.bool,
  tablet: PropTypes.bool,
  desktop: PropTypes.bool,
  desktopNavOpen: PropTypes.bool,
  desktopOnly: PropTypes.bool,
  mobileOnly: PropTypes.bool,
})

export type Breakpoints = {
  miniTablet?: boolean
  tablet?: boolean
  desktop?: boolean
  desktopNavOpen?: boolean
  desktopOnly?: boolean
  mobileOnly?: boolean
}
