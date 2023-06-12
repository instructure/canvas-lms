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

import React from 'react'
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

const convertMatchesToProp = matches => {
  const breakpoints = {}
  matches.forEach(match => (breakpoints[match] = true))
  return breakpoints
}

const WithBreakpoints = Component => props => {
  if (window.matchMedia) {
    return (
      <Responsive
        match="media"
        query={BREAKPOINTS}
        render={(_addedProps, matches) => (
          <Component breakpoints={convertMatchesToProp(matches)} {...props} />
        )}
      />
    )
  } else {
    return <Component breakpoints={{}} {...props} />
  }
}

export const breakpointsShape = PropTypes.shape({
  miniTablet: PropTypes.bool,
  tablet: PropTypes.bool,
  desktop: PropTypes.bool,
  desktopNavOpen: PropTypes.bool,
  desktopOnly: PropTypes.bool,
  mobileOnly: PropTypes.bool,
})

export default WithBreakpoints
