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
import {Text} from '@instructure/ui-elements'
import {string} from 'prop-types'

SVGWithTextPlaceholder.propTypes = {
  text: string.isRequired,
  url: string.isRequired
}

function SVGWithTextPlaceholder(props) {
  return (
    <div className="svg-placeholder-container">
      <img alt="" src={props.url} style={{width: '200px'}} />
      <Text weight="bold" as="div" margin="x-small auto">
        {props.text}
      </Text>
    </div>
  )
}

export default React.memo(SVGWithTextPlaceholder)
