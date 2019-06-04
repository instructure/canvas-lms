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
import {arrayOf, bool, func, number, string} from 'prop-types'
import {StyleSheet, css} from 'aphrodite'
import { Button } from '@instructure/ui-buttons'
import { Flex, View } from '@instructure/ui-layout'
import { ScreenReaderContent } from '@instructure/ui-a11y'
import { Text } from '@instructure/ui-elements'
import {SVGIcon} from '@instructure/ui-svg-images'
import { IconA11yLine, IconKeyboardShortcutsLine, IconMiniArrowEndLine } from '@instructure/ui-icons'
import formatMessage from '../format-message'

StatusBar.propTypes = {
  onToggleHtml: func,
  path: arrayOf(string),
  wordCount: number,
  isHtmlView: bool
}

function renderPath({path}) {
  return path.reduce((result, pathName, index) => {
    return result.concat(
      <span key={`${pathName}-${index}`}>
        <Text>
          {index > 0 ? <IconMiniArrowEndLine /> : null}
          {pathName}
        </Text>
      </span>
    )
  }, [])
}

function emptyTagIcon() {
  return (
    <SVGIcon viewBox="0 0 24 24" fontSize="24px">
      <g role="presentation">
        <text textAnchor="start" x="0" y="18px" fontSize="16">
          &lt;/&gt;
        </text>
      </g>
    </SVGIcon>
  )
}
export default function StatusBar(props) {
  if (props.isHtmlView) {
    const toggleToRich = formatMessage('Switch to rich text editor')
    return (
      <View display="block" margin="x-small" textAlign="end" data-testid="RCEStatusBar">
        <Button variant="link" icon={emptyTagIcon()} onClick={props.onToggleHtml} title={toggleToRich}>
          <ScreenReaderContent>{toggleToRich}</ScreenReaderContent>
        </Button>
      </View>
    )
  } else {
    const kbshortcut = formatMessage('View keyboard shortcuts')
    const a11y = formatMessage('Accessibility Checker')
    const wordCount = formatMessage(`{count, plural,
         =0 {0 words}
        one {1 word}
      other {# words}
    }`, {count: props.wordCount})
    const toggleToHtml = formatMessage('Switch to raw html editor')

    return (
      <Flex margin="x-small" data-testid="RCEStatusBar">
        <Flex.Item grow>
          <View>{renderPath(props)}</View>
        </Flex.Item>

        <Flex.Item>
          <View display="inline-block" padding="0 x-small">
            <Button variant="link" icon={IconKeyboardShortcutsLine} title={kbshortcut}>
              <ScreenReaderContent>{kbshortcut}</ScreenReaderContent>
            </Button>
            <Button variant="link" icon={IconA11yLine} title={a11y}>
              <ScreenReaderContent>{a11y}</ScreenReaderContent>
            </Button>
          </View>
          <div className={css(styles.separator)}/>
        </Flex.Item>

        <Flex.Item>
          <View display="inline-block" padding="0 small xx-small small">
            <Text>{wordCount}</Text>
          </View>
          <div className={css(styles.separator)}/>
        </Flex.Item>

        <Flex.Item>
          <View display="inline-block" padding="0 0 0 small">
            <Button variant="link" icon={emptyTagIcon()} onClick={props.onToggleHtml} title={toggleToHtml}>
              <ScreenReaderContent>{toggleToHtml}</ScreenReaderContent>
            </Button>
          </View>
        </Flex.Item>
      </Flex>
    )
  }
}

const styles = StyleSheet.create({
  separator: {
    display: 'inline-block',
    'box-sizing': 'border-box',
    'border-right': '1px solid #ccc',
    width: '1px',
    height: '1.5rem',
    position: 'relative',
    top: '.5rem'
  }
});
