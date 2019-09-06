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
import {string} from 'prop-types'
import { StyleSheet, css } from "aphrodite";

import {Text} from '@instructure/ui-elements'
import {View} from '@instructure/ui-layout'
import {IconArrowOpenDownLine, IconArrowOpenEndLine} from '@instructure/ui-icons'

export default function ExpandoText(props) {
  const [descExpanded, setDescExpanded] = useState(false)
  const [focused, setFocused] = useState(false)

  const {text} = props
  return (
    <View
      as="button"
      className={css(styles.toggleButton)}
      type="button"
      position="relative"
      aria-expanded={descExpanded}
      focused={focused}
      onClick={(event) => {
        if(event.target.tagName !== 'A' || event.target.tagName !== 'BUTTON') {
          // let the user click on links and buttons
          setDescExpanded(!descExpanded)
        }
      }}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
    >
      <span style={{display: 'flex', alignItems: 'start'}}>
        <span style={{marginRight: '.25rem', display: 'inline-block'}}>
          <Text color="secondary">
            {descExpanded ? <IconArrowOpenDownLine/> : <IconArrowOpenEndLine/>}
          </Text>
        </span>
        <span style={{flexGrow: '1', minWidth: '10rem'}}>
          <Text as="span" color="secondary">
            <div
              className={css(styles.descriptionText, descExpanded ? null : styles.overflow)}
              dangerouslySetInnerHTML={{__html: text}}
            />
          </Text>
        </span>
      </span>
    </View>
  )
}

ExpandoText.propTypes = {
  text: string.isRequired
}

export const styles = StyleSheet.create({
  toggleButton: {
    background: 'transparent',
    borderStyle: 'none',
    display: 'block',
    padding: '.25rem',
    textAlign: 'start',
    maxWidth: '100%'
  },
  descriptionText: {
    overflow: 'hidden',
    lineHeight: '1.2rem',
    p: {
      margin: '1rem 0'
    },
    ':nth-child(1n)> :first-child': {
      marginTop: '0',
      display: 'inline-block'
    },
    ':nth-child(1n)> :last-child': {
      marginBottom: '0'
    }
  },
  overflow: {
    overflow: 'hidden',
    whiteSpace: 'nowrap',
    height: '1.2rem',
    textOverflow: 'ellipsis'
  }
});