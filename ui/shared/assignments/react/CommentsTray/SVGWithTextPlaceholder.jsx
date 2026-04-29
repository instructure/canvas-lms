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
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {bool, string} from 'prop-types'

function TextPlaceholder(props) {
  const text = (
    <Text weight="bold" as="div">
      {props.text}
    </Text>
  )

  if (props.addMargin) {
    return (
      <View as="div" margin="0 medium">
        {text}
      </View>
    )
  }

  return text
}

TextPlaceholder.propTypes = {
  addMargin: bool.isRequired,
  text: string.isRequired,
}

export default function SVGWithTextPlaceholder(props) {
  return (
    <div data-testid="svg-placeholder-container" className="svg-placeholder-container">
      <img alt="" src={props.url} style={{width: '200px'}} />
      <TextPlaceholder addMargin={props.addMargin} text={props.text} />
    </div>
  )
}

SVGWithTextPlaceholder.propTypes = {
  addMargin: bool,
  text: string.isRequired,
  url: string.isRequired,
}

SVGWithTextPlaceholder.defaultProps = {
  addMargin: false,
}
