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

import React, {useState} from 'react'
import {func, string} from 'prop-types'
import {Text} from '@instructure/ui-elements'
import {View} from '@instructure/ui-layout'
import ExpandoText from './ExpandoText'

export default function LtiTool(props) {
  const [focused, setFocused] = useState(false)
  const {title, image, description, onAction} = props

  return (
    <>
      <View
        as="div"
        focused={focused}
        role="button"
        position="relative"
        margin="none none small"
        onClick={() => {
          onAction()
        }}
        onKeyDown={e => {
          if (e.keyCode === 13 || e.keyCode === 32) {
            onAction()
          }
        }}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        tabIndex="0"
      >
        <span style={{marginRight: '.5rem'}}>
          <img src={image} alt="" />
        </span>
        <Text weight="bold">{title}</Text>
      </View>
      {description && renderDescription(description)}
    </>
  )

  function renderDescription(desc) {
    return (
      <div style={{margin: '0 1.5rem', position: 'relative', boxSizing: 'content-box'}}>
        <ExpandoText text={desc} />
      </div>
    )
  }
}

LtiTool.propTypes = {
  title: String.isRequired,
  image: string.isRequired,
  onAction: func.isRequired,
  description: string
}
