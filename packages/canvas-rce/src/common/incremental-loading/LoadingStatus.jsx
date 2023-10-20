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
import {number, shape} from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import formatMessage from '../../format-message'

export default function LoadingStatus({loader}) {
  let itemsLoadedText = null

  if (loader.lastRecordsLoaded > 0) {
    itemsLoadedText = formatMessage(
      `{
         count, plural,
           one {# item loaded}
         other {# items loaded}
       }`,
      {count: loader.lastRecordsLoaded}
    )
  }

  return (
    <ScreenReaderContent aria-live="polite" aria-relevant="text additions">
      {itemsLoadedText}
    </ScreenReaderContent>
  )
}

LoadingStatus.propTypes = {
  loader: shape({
    lastRecordsLoaded: number.isRequired,
  }).isRequired,
}
