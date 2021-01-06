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

import React, {useRef, useState} from 'react'
import ReactDOM from 'react-dom'
import {arrayOf, bool, func, number, string} from 'prop-types'
import {StyleSheet, css} from 'aphrodite'
import keycode from 'keycode'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {Text} from '@instructure/ui-text'
import {SVGIcon} from '@instructure/ui-svg-images'
import {
  IconA11yLine,
  IconKeyboardShortcutsLine,
  IconMiniArrowEndLine,
  IconFullScreenLine
} from '@instructure/ui-icons'
import formatMessage from '../format-message'
import ResizeHandle from './ResizeHandle'

// I don't know why eslint is reporting this, the props are all used
/* eslint-disable react/no-unused-prop-types */
StatusBar.propTypes = {
  onToggleHtml: func.isRequired,
  path: arrayOf(string),
  wordCount: number,
  isHtmlView: bool,
  onResize: func, // react-draggable onDrag handler.
  onKBShortcutModalOpen: func.isRequired,
  onA11yChecker: func.isRequired,
  onFullscreen: func.isRequired
}

/* eslint-enable react/no-unused-prop-types */

// we use the array index because pathname may not be unique
/* eslint-disable react/no-array-index-key */
function renderPathString({path}) {
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
/* eslint-enable react/no-array-index-key */

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

function findFocusable(el) {
  // eslint-disable-next-line react/no-find-dom-node
  const element = ReactDOM.findDOMNode(el)
  return element ? Array.from(element.querySelectorAll('[tabindex]')) : []
}

export default function StatusBar(props) {
  const [focusedIndex, setFocusedIndex] = useState(0)
  const statusBarRef = useRef(null)

  function handleKey(event) {
    const buttons = findFocusable(statusBarRef.current)
    if (event.keyCode === keycode.codes.right) {
      buttons[(focusedIndex + 1) % buttons.length].focus()
    } else if (event.keyCode === keycode.codes.left) {
      buttons[(focusedIndex + buttons.length - 1) % buttons.length].focus()
    }
  }

  function handleFocus(event) {
    // we hide a the 2 icon buttons
    let offset = props.isHtmlView ? 2 : 0
    const buttons = findFocusable(statusBarRef.current)
    const fidx = buttons.findIndex(b => b === event.target)
    if (props.isHtmlView && fidx === 4) {
      // we hide the fullscreen button
      --offset
    }
    setFocusedIndex(fidx + offset)
  }

  function tabIndexForPosition(itemIndex) {
    const tabindex = focusedIndex === itemIndex ? '0' : '-1'
    return tabindex
  }

  function renderPath() {
    if (props.isHtmlView) return null
    return <View data-testid="whole-status-bar-path">{renderPathString(props)}</View>
  }

  function renderIconButtons() {
    if (props.isHtmlView) return null
    const kbshortcut = formatMessage('View keyboard shortcuts')
    const a11y = formatMessage('Accessibility Checker')
    return (
      <View display="inline-block" padding="0 x-small">
        <Button
          variant="link"
          icon={IconKeyboardShortcutsLine}
          title={kbshortcut}
          tabIndex={tabIndexForPosition(0)}
          onClick={event => {
            event.target.focus() // FF doesn't focus buttons on click
            props.onKBShortcutModalOpen()
          }}
        >
          <ScreenReaderContent>{kbshortcut}</ScreenReaderContent>
        </Button>
        <Button
          variant="link"
          icon={IconA11yLine}
          title={a11y}
          tabIndex={tabIndexForPosition(1)}
          onClick={event => {
            event.target.focus()
            props.onA11yChecker()
          }}
        >
          <ScreenReaderContent>{a11y}</ScreenReaderContent>
        </Button>
      </View>
    )
  }

  function renderWordCount() {
    if (props.isHtmlView) return null
    const wordCount = formatMessage(
      `{count, plural,
         =0 {0 words}
        one {1 word}
      other {# words}
    }`,
      {count: props.wordCount}
    )
    return (
      <View display="inline-block" padding="0 small" data-testid="status-bar-word-count">
        <Text>{wordCount}</Text>
      </View>
    )
  }

  function renderToggleHtml() {
    const toggleToHtml = formatMessage('Switch to raw html editor')
    const toggleToRich = formatMessage('Switch to rich text editor')
    const toggleText = props.isHtmlView ? toggleToRich : toggleToHtml
    return (
      <View display="inline-block" padding="0 0 0 x-small">
        <Button
          variant="link"
          icon={emptyTagIcon()}
          onClick={event => {
            event.target.focus()
            props.onToggleHtml()
          }}
          title={toggleText}
          tabIndex={tabIndexForPosition(2)}
        >
          <ScreenReaderContent>{toggleText}</ScreenReaderContent>
        </Button>
      </View>
    )
  }

  function renderFullscreen() {
    if (props.isHtmlView) return null
    const fullscreen = formatMessage('Fullscreen')
    return (
      <Button
        variant="link"
        icon={IconFullScreenLine}
        title={fullscreen}
        tabIndex={tabIndexForPosition(3)}
        onClick={event => {
          event.target.focus()
          props.onFullscreen()
        }}
      >
        <ScreenReaderContent>{fullscreen}</ScreenReaderContent>
      </Button>
    )
  }

  function renderResizeHandle() {
    return <ResizeHandle onDrag={props.onResize} tabIndex={tabIndexForPosition(4)} />
  }

  const flexJustify = props.isHtmlView ? 'end' : 'start'
  return (
    <Flex
      margin="x-small 0 x-small x-small"
      data-testid="RCEStatusBar"
      justifyItems={flexJustify}
      ref={statusBarRef}
      onKeyDown={handleKey}
      onFocus={handleFocus}
    >
      <Flex.Item grow>{renderPath()}</Flex.Item>

      <Flex.Item role="toolbar" title={formatMessage('Editor Statusbar')}>
        {renderIconButtons()}
        <div className={css(styles.separator)} />
        {renderWordCount()}
        <div className={css(styles.separator)} />
        {renderToggleHtml()}
        {renderFullscreen()}
        {renderResizeHandle()}
      </Flex.Item>
    </Flex>
  )
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
})
