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
import {css, StyleSheet} from 'aphrodite'

import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import formatMessage from '../../../../../format-message'

export default function ExpandoText(props: {text: string; title: string}): JSX.Element {
  const [descExpanded, setDescExpanded] = useState(false)
  const [focused, setFocused] = useState(false)
  const {text, title} = props

  const label = descExpanded
    ? formatMessage('Hide {title} description', {title})
    : formatMessage('View {title} description', {title})

  return (
    <>
      <View
        as="button"
        background="transparent"
        display="block"
        borderWidth="none"
        textAlign="start"
        type="button"
        position="relative"
        padding="none none none xx-small"
        aria-expanded={descExpanded}
        borderRadius="medium"
        withFocusOutline={focused}
        onClick={() => {
          setDescExpanded(!descExpanded)
        }}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
      >
        <View as="span" aria-live="assertive" aria-relevant="text">
          <Text color="brand" size="x-small" aria-label={label}>
            {descExpanded ? formatMessage('Hide description') : formatMessage('View description')}
          </Text>
        </View>
      </View>
      {descExpanded && (
        <View
          as="span"
          margin="small none none xx-small"
          display="block"
          minWidth="10rem"
          role="presentation"
        >
          <Text as="span" color="secondary">
            <div className={css(styles.descriptionText)} dangerouslySetInnerHTML={{__html: text}} />
          </Text>
        </View>
      )}
    </>
  )
}

export const styles = StyleSheet.create({
  descriptionText: {
    lineHeight: '1.2rem',
    p: {
      margin: '1rem 0',
    },
    ':nth-child(1n)> :first-child': {
      marginTop: '0',
      display: 'inline-block',
    },
    ':nth-child(1n)> :last-child': {
      marginBottom: '0',
    },
  },
})
