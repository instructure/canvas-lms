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
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import ExpandoText from './ExpandoText'
import formatMessage from '../../../../../format-message'
import {StyleSheet, css} from 'aphrodite'

export default function LtiTool(props) {
  const [focused, setFocused] = useState(false)
  const {title, image, description, onAction} = props

  return (
    <>
      <View
        as="span"
        focused={focused}
        className={css(styles.appButton)}
        padding="xxx-small xxx-small xx-small"
        borderRadius="medium"
        role="button"
        position="relative"
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
        <span>
          <img src={image} width="28" height="28" alt="" />
        </span>
        <View as="span" className={css(styles.appTitle)} margin="none none none small">
          <Text aria-label={formatMessage('Open {title} application', {title})} weight="bold">
            {title}
          </Text>
        </View>
      </View>
      {description && renderDescription(description)}
    </>
  )

  function renderDescription(desc) {
    return (
      <View as="span" margin="none none none large" display="block">
        <ExpandoText text={desc} title={title} />
      </View>
    )
  }
}

LtiTool.propTypes = {
  title: string.isRequired,
  image: string.isRequired,
  onAction: func.isRequired,
  description: string
}

export const styles = StyleSheet.create({
  appTitle: {
    verticalAlign: 'middle'
  }
})
