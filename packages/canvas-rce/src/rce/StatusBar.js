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

import React, {useEffect, useRef, useState} from 'react'
import ReactDOM from 'react-dom'
import {arrayOf, bool, func, number, oneOf, string} from 'prop-types'
import {StyleSheet, css} from 'aphrodite'
import keycode from 'keycode'
import {CondensedButton, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Badge} from '@instructure/ui-badge'
import {ApplyTheme} from '@instructure/ui-themeable'

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

export const WYSIWYG_VIEW = 'WYSIWYG'
export const PRETTY_HTML_EDITOR_VIEW = 'PRETTY'
export const RAW_HTML_EDITOR_VIEW = 'RAW'

// I don't know why eslint is reporting this, the props are all used
/* eslint-disable react/no-unused-prop-types */
StatusBar.propTypes = {
  onChangeView: func.isRequired,
  path: arrayOf(string),
  wordCount: number,
  editorView: oneOf([WYSIWYG_VIEW, PRETTY_HTML_EDITOR_VIEW, RAW_HTML_EDITOR_VIEW]),
  onResize: func, // react-draggable onDrag handler.
  onKBShortcutModalOpen: func.isRequired,
  onA11yChecker: func.isRequired,
  onFullscreen: func.isRequired,
  use_rce_pretty_html_editor: bool,
  use_rce_a11y_checker_notifications: bool,
  preferredHtmlEditor: oneOf([PRETTY_HTML_EDITOR_VIEW, RAW_HTML_EDITOR_VIEW]),
  readOnly: bool,
  a11yBadgeColor: string,
  a11yErrorsCount: number
}

StatusBar.defaultProps = {
  a11yBadgeColor: '#FC5E13',
  a11yErrorsCount: 0
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
        <text textAnchor="middle" x="12px" y="18px" fontSize="16">
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
  const [focusedBtnId, setFocusedBtnId] = useState(null)
  const [includeEdtrDesc, setIncludeEdtrDesc] = useState(false)
  const statusBarRef = useRef(null)

  useEffect(() => {
    const buttons = findFocusable(statusBarRef.current)
    setFocusedBtnId(buttons[0].getAttribute('data-btn-id'))
    buttons[0].setAttribute('tabIndex', '0')
  }, [])

  useEffect(() => {
    // the kbshortcut and a11y checker buttons are hidden when in html view
    // move focus to the next button over.
    if (isHtmlView() && /rce-kbshortcut-btn|rce-a11y-btn/.test(focusedBtnId)) {
      setFocusedBtnId('rce-edit-btn')
    }
    // adding a delay before including the HTML Editor description to wait the focus moves to the RCE
    // and prevent JAWS from reading the aria-describedby element when switching back to RCE view
    const timerid = setTimeout(() => {
      setIncludeEdtrDesc(props.use_rce_pretty_html_editor && !isHtmlView())
    }, 100)

    return () => clearTimeout(timerid)
  }, [props.editorView]) // eslint-disable-line react-hooks/exhaustive-deps

  function preferredHtmlEditor() {
    if (props.preferredHtmlEditor) return props.preferredHtmlEditor
    return props.use_rce_pretty_html_editor ? PRETTY_HTML_EDITOR_VIEW : RAW_HTML_EDITOR_VIEW
  }

  function getHtmlEditorView(event) {
    if (!props.use_rce_pretty_html_editor) return RAW_HTML_EDITOR_VIEW
    if (!event.shiftKey) return preferredHtmlEditor()
    return preferredHtmlEditor() === RAW_HTML_EDITOR_VIEW
      ? PRETTY_HTML_EDITOR_VIEW
      : RAW_HTML_EDITOR_VIEW
  }

  function handleKey(event) {
    const buttons = findFocusable(statusBarRef.current).filter(b => !b.disabled)
    const focusedIndex = buttons.findIndex(b => b.getAttribute('data-btn-id') === focusedBtnId)
    let newFocusedIndex
    if (event.keyCode === keycode.codes.right) {
      newFocusedIndex = (focusedIndex + 1) % buttons.length
    } else if (event.keyCode === keycode.codes.left) {
      newFocusedIndex = (focusedIndex + buttons.length - 1) % buttons.length
    } else {
      return
    }

    buttons[newFocusedIndex].focus()
    setFocusedBtnId(buttons[newFocusedIndex].getAttribute('data-btn-id'))
  }

  function isHtmlView() {
    return props.editorView !== WYSIWYG_VIEW
  }

  function tabIndexForBtn(itemId) {
    const tabindex = focusedBtnId === itemId ? '0' : '-1'
    return tabindex
  }

  function renderPath() {
    return <View data-testid="whole-status-bar-path">{renderPathString(props)}</View>
  }

  function renderA11yButton() {
    const a11y = formatMessage('Accessibility Checker')
    const button = (
      <IconButton
        data-btn-id="rce-a11y-btn"
        color="primary"
        title={a11y}
        tabIndex={tabIndexForBtn('rce-a11y-btn')}
        onClick={event => {
          event.target.focus()
          props.onA11yChecker()
        }}
        onFocus={() => setFocusedBtnId('rce-a11y-btn')}
        screenReaderLabel={a11y}
        withBackground={false}
        withBorder={false}
      >
        <IconA11yLine />
      </IconButton>
    )
    if (!props.use_rce_a11y_checker_notifications || props.a11yErrorsCount <= 0) {
      return button
    }
    return (
      <ApplyTheme
        theme={{
          [Badge.theme]: {colorPrimary: props.a11yBadgeColor}
        }}
      >
        <Badge count={props.a11yErrorsCount} countUntil={100}>
          {button}
        </Badge>
      </ApplyTheme>
    )
  }

  function renderHtmlEditorMessage() {
    if (!props.use_rce_pretty_html_editor) return null

    const message =
      props.editorView === PRETTY_HTML_EDITOR_VIEW
        ? formatMessage(
            'Sadly, the pretty HTML editor is not keyboard accessible. Access the raw HTML editor here.'
          )
        : formatMessage('Access the pretty HTML editor')
    const label =
      props.editorView === PRETTY_HTML_EDITOR_VIEW
        ? formatMessage('Raw HTML Editor')
        : formatMessage('Pretty HTML Editor')
    return (
      <View data-testid="html-editor-message">
        <CondensedButton
          data-btn-id="rce-editormessage-btn"
          margin="0 small"
          title={message}
          tabIndex={tabIndexForBtn('rce-editormessage-btn')}
          onClick={event => {
            event.target.focus()
            props.onChangeView(
              props.editorView === PRETTY_HTML_EDITOR_VIEW
                ? RAW_HTML_EDITOR_VIEW
                : PRETTY_HTML_EDITOR_VIEW
            )
          }}
          onFocus={() => setFocusedBtnId('rce-editormessage-btn')}
        >
          {label}
        </CondensedButton>
      </View>
    )
  }

  function renderIconButtons() {
    if (isHtmlView()) return null
    const kbshortcut = formatMessage('View keyboard shortcuts')
    return (
      <View display="inline-block" padding="0 x-small">
        <IconButton
          data-btn-id="rce-kbshortcut-btn"
          color="primary"
          aria-haspopup="dialog"
          title={kbshortcut}
          tabIndex={tabIndexForBtn('rce-kbshortcut-btn')}
          onClick={event => {
            event.target.focus() // FF doesn't focus buttons on click
            props.onKBShortcutModalOpen()
          }}
          onFocus={() => setFocusedBtnId('rce-kbshortcut-btn')}
          screenReaderLabel={kbshortcut}
          withBackground={false}
          withBorder={false}
        >
          <IconKeyboardShortcutsLine />
        </IconButton>
        {props.readOnly || renderA11yButton()}
      </View>
    )
  }

  function renderWordCount() {
    if (isHtmlView()) return null
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

  function descMsg() {
    return preferredHtmlEditor() === RAW_HTML_EDITOR_VIEW
      ? formatMessage('Shift-O to open the pretty html editor.')
      : formatMessage(
          'The pretty html editor is not keyboard accessible. Press Shift O to open the raw html editor.'
        )
  }

  function renderToggleHtml() {
    const toggleToHtml = formatMessage('Switch to the html editor')
    const toggleToRich = formatMessage('Switch to the rich text editor')
    const toggleToHtmlTip = props.use_rce_pretty_html_editor
      ? formatMessage('Click or shift-click for the html editor.')
      : toggleToHtml
    const descText = isHtmlView() ? toggleToRich : toggleToHtml
    const titleText = isHtmlView() ? toggleToRich : toggleToHtmlTip

    return (
      <View display="inline-block" padding="0 0 0 x-small">
        {props.readOnly || (
          <IconButton
            data-btn-id="rce-edit-btn"
            color="primary"
            onClick={event => {
              props.onChangeView(isHtmlView() ? WYSIWYG_VIEW : getHtmlEditorView(event))
            }}
            onKeyUp={event => {
              if (
                props.use_rce_pretty_html_editor &&
                props.editorView === WYSIWYG_VIEW &&
                event.shiftKey &&
                event.keyCode === 79
              ) {
                const html_view =
                  preferredHtmlEditor() === RAW_HTML_EDITOR_VIEW
                    ? PRETTY_HTML_EDITOR_VIEW
                    : RAW_HTML_EDITOR_VIEW
                props.onChangeView(html_view)
              }
            }}
            onFocus={() => setFocusedBtnId('rce-edit-btn')}
            title={titleText}
            tabIndex={tabIndexForBtn('rce-edit-btn')}
            aria-describedby={includeEdtrDesc ? 'edit-button-desc' : undefined}
            screenReaderLabel={descText}
            withBackground={false}
            withBorder={false}
          >
            {emptyTagIcon()}
          </IconButton>
        )}
        {includeEdtrDesc && (
          <span style={{display: 'none'}} id="edit-button-desc">
            {descMsg()}
          </span>
        )}
      </View>
    )
  }

  function renderFullscreen() {
    if (props.readOnly) return null
    if (props.editorView === RAW_HTML_EDITOR_VIEW && !('requestFullscreen' in document.body)) {
      // this is safari, which refuses to fullscreen a textarea
      return null
    }
    const fullscreen = formatMessage('Fullscreen')
    return (
      <IconButton
        data-btn-id="rce-fullscreen-btn"
        color="primary"
        title={fullscreen}
        tabIndex={tabIndexForBtn('rce-fullscreen-btn')}
        onClick={event => {
          event.target.focus()
          props.onFullscreen()
        }}
        onFocus={() => setFocusedBtnId('rce-fullscreen-btn')}
        screenReaderLabel={fullscreen}
        withBackground={false}
        withBorder={false}
      >
        <IconFullScreenLine />
      </IconButton>
    )
  }

  function renderResizeHandle() {
    return (
      <ResizeHandle
        data-btn-id="rce-resize-handle"
        onDrag={props.onResize}
        tabIndex={tabIndexForBtn('rce-resize-handle')}
        onFocus={() => {
          setFocusedBtnId('rce-resize-handle')
        }}
      />
    )
  }

  const flexJustify = isHtmlView() ? 'end' : 'start'
  return (
    <Flex
      margin="x-small 0 x-small x-small"
      data-testid="RCEStatusBar"
      justifyItems={flexJustify}
      ref={statusBarRef}
      onKeyDown={handleKey}
    >
      <Flex.Item shouldGrow>{isHtmlView() ? renderHtmlEditorMessage() : renderPath()}</Flex.Item>

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
