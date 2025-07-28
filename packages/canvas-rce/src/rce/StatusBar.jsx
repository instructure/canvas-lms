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
import {Button, IconButton, CondensedButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Badge} from '@instructure/ui-badge'
import {InstUISettingsProvider} from '@instructure/emotion'

import {Text} from '@instructure/ui-text'
import {SVGIcon} from '@instructure/ui-svg-images'
import {
  IconA11yLine,
  IconKeyboardShortcutsLine,
  IconMiniArrowEndLine,
  IconFullScreenLine,
  IconExitFullScreenLine,
  IconAddLine,
  IconCheckMarkIndeterminateLine,
} from '@instructure/ui-icons'
import formatMessage from '../format-message'
import ResizeHandle from './ResizeHandle'
import {FS_ENABLED} from '../util/fullscreenHelpers'
import {AIWandSVG} from './plugins/shared/ai_tools'

export const WYSIWYG_VIEW = 'WYSIWYG'
export const PRETTY_HTML_EDITOR_VIEW = 'PRETTY'
export const RAW_HTML_EDITOR_VIEW = 'RAW'

// I don't know why eslint is reporting this, the props are all used

StatusBar.propTypes = {
  id: string.isRequired,
  rceIsFullscreen: bool,
  onChangeView: func.isRequired,
  path: arrayOf(string),
  wordCount: number,
  editorView: oneOf([WYSIWYG_VIEW, PRETTY_HTML_EDITOR_VIEW, RAW_HTML_EDITOR_VIEW]),
  onResize: func, // react-draggable onDrag handler.
  onKBShortcutModalOpen: func.isRequired,
  onA11yChecker: func.isRequired,
  onFullscreen: func.isRequired,
  preferredHtmlEditor: oneOf([PRETTY_HTML_EDITOR_VIEW, RAW_HTML_EDITOR_VIEW]),
  readOnly: bool,
  a11yBadgeColor: string,
  a11yErrorsCount: number,
  onWordcountModalOpen: func.isRequired,
  disabledPlugins: arrayOf(string),
  features: arrayOf(string), // StatusBarFeature[]
  onAI: func,
}

StatusBar.defaultProps = {
  a11yBadgeColor: '#2B7ABC',
  a11yErrorsCount: 0,
  disabledPlugins: [],
}

// we use the array index because pathname may not be unique

function renderPathString({path}) {
  return path.reduce((result, pathName, index) => {
    return result.concat(
      <span key={`${pathName}-${index}`}>
        <Text>
          {index > 0 ? <IconMiniArrowEndLine /> : null}
          {pathName}
        </Text>
      </span>,
    )
  }, [])
}

function emptyTagIcon() {
  return (
    <SVGIcon viewBox="0 0 1920 1920" width="1em" height="1em">
      <g role="presentation" transform="scale(28.7) translate(0, 8)">
        <path d="M0 29.61L0 25.51L23.71 15.50L23.71 19.87L4.91 27.59L23.71 35.38L23.71 39.75L0 29.61ZM26.46 45.87L36.84 8.86L40.36 8.86L30.00 45.87L26.46 45.87ZM66.80 29.61L43.09 39.75L43.09 35.38L61.87 27.59L43.09 19.87L43.09 15.50L66.80 25.51L66.80 29.61Z"></path>
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
      setIncludeEdtrDesc(!isHtmlView())
    }, 100)

    return () => clearTimeout(timerid)
  }, [props.editorView]) // eslint-disable-line react-hooks/exhaustive-deps

  function isAvailable(plugin) {
    return !props.disabledPlugins.includes(plugin)
  }

  function isFeature(feature_name) {
    return props.features.includes(feature_name)
  }

  function preferredHtmlEditor() {
    if (props.preferredHtmlEditor) return props.preferredHtmlEditor
    return PRETTY_HTML_EDITOR_VIEW
  }

  function getHtmlEditorView(event) {
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
    const tabindex = focusedBtnId === itemId ? 0 : -1
    return tabindex
  }

  function renderPath() {
    return (
      <View data-testid="whole-status-bar-path" style={{display: 'flex'}}>
        {renderPathString(props)}
      </View>
    )
  }

  function renderA11yButton() {
    const a11y = formatMessage('Accessibility Checker')
    const a11yButtonId = 'rce-a11y-btn'
    const button = (
      <IconButton
        data-btn-id={a11yButtonId}
        color="secondary"
        title={a11y}
        tabIndex={tabIndexForBtn(a11yButtonId)}
        onClick={event => {
          event.target.focus()
          props.onA11yChecker(a11yButtonId)
        }}
        onFocus={() => setFocusedBtnId(a11yButtonId)}
        screenReaderLabel={a11y}
        withBackground={false}
        withBorder={false}
      >
        <IconA11yLine />
      </IconButton>
    )
    if (props.a11yErrorsCount <= 0) {
      return button
    }
    return (
      <InstUISettingsProvider
        theme={{
          componentOverrides: {
            Badge: {colorPrimary: props.a11yBadgeColor},
          },
        }}
      >
        <Badge count={props.a11yErrorsCount} countUntil={100}>
          {button}
        </Badge>
      </InstUISettingsProvider>
    )
  }

  function renderHtmlEditorMessage() {
    const message =
      props.editorView === PRETTY_HTML_EDITOR_VIEW
        ? formatMessage(
            'Sadly, the pretty HTML editor is not keyboard accessible. Access the raw HTML editor here.',
          )
        : formatMessage('Access the pretty HTML editor')
    const label =
      props.editorView === PRETTY_HTML_EDITOR_VIEW
        ? formatMessage('Switch to raw HTML Editor')
        : formatMessage('Switch to pretty HTML Editor')
    return (
      <View data-testid="html-editor-message" style={{display: 'flex'}}>
        <Button
          data-btn-id="rce-editormessage-btn"
          margin="0 small"
          title={message}
          color="secondary"
          size="small"
          tabIndex={tabIndexForBtn('rce-editormessage-btn')}
          onClick={event => {
            event.target.focus()
            props.onChangeView(
              props.editorView === PRETTY_HTML_EDITOR_VIEW
                ? RAW_HTML_EDITOR_VIEW
                : PRETTY_HTML_EDITOR_VIEW,
            )
          }}
          onFocus={() => setFocusedBtnId('rce-editormessage-btn')}
        >
          {label}
        </Button>
      </View>
    )
  }

  function renderIconButtons() {
    if (isHtmlView()) return null
    const ai_tools = isFeature('ai_tools')
    const kb_shortcuts = isFeature('keyboard_shortcuts')
    const a11y_checker = isFeature('a11y_checker')
    if (!(ai_tools || kb_shortcuts || a11y_checker)) return null

    const kbshortcut = formatMessage('View keyboard shortcuts')
    return (
      <View display="inline-block" padding="0 x-small">
        {ai_tools && props.onAI && (
          <IconButton
            data-btn-id="rce-ai-btn"
            color="secondary"
            aria-haspopup="dialog"
            title={formatMessage('AI Tools')}
            tabIndex={tabIndexForBtn('rce-ai-btn')}
            onClick={event => {
              event.target.focus() // FF doesn't focus buttons on click
              props.onAI()
            }}
            onFocus={() => setFocusedBtnId('rce-ai-btn')}
            screenReaderLabel={formatMessage('AI Tools')}
            withBackground={false}
            withBorder={false}
          >
            <span style={{color: 'dodgerBlue'}}>
              <SVGIcon src={AIWandSVG} size="x-small" />
            </span>
          </IconButton>
        )}
        {kb_shortcuts && (
          <IconButton
            data-btn-id="rce-kbshortcut-btn"
            color="secondary"
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
        )}
        {a11y_checker && !props.readOnly && isAvailable('ally_checker') && renderA11yButton()}
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
      {count: props.wordCount},
    )
    return (
      <>
        <div className={css(styles.separator)} />
        <View display="inline-block" padding="0 small" data-testid="status-bar-word-count">
          <CondensedButton
            data-btn-id="rce-wordcount-btn"
            color="secondary"
            onClick={props.onWordcountModalOpen}
            tabIndex={tabIndexForBtn('rce-wordcount-btn')}
            title={formatMessage('View word and character counts')}
          >
            {wordCount}
          </CondensedButton>
        </View>
      </>
    )
  }

  function renderSection3({html_view, fullscreen, resize_handle, a11y_resize_handlers}) {
    return (
      <>
        <div className={css(styles.separator)} />
        {html_view && renderToggleHtml()}
        {a11y_resize_handlers && renderAccessibleResizeHandle()}
        {fullscreen && renderFullscreen()}
        {resize_handle && renderResizeHandle()}
      </>
    )
  }

  function descMsg() {
    return preferredHtmlEditor() === RAW_HTML_EDITOR_VIEW
      ? formatMessage('Shift-O to open the pretty html editor.')
      : formatMessage(
          'The pretty html editor is not keyboard accessible. Press Shift O to open the raw html editor.',
        )
  }

  function renderToggleHtml() {
    const toggleToHtml = formatMessage('Switch to the html editor')
    const toggleToRich = formatMessage('Switch to the rich text editor')
    const toggleToHtmlTip = formatMessage('Click or shift-click for the html editor.')
    const descText = isHtmlView() ? toggleToRich : toggleToHtml
    const titleText = isHtmlView() ? toggleToRich : toggleToHtmlTip

    return (
      <View display="inline-block" padding="0 0 0 x-small">
        {!props.readOnly && (
          <IconButton
            data-btn-id="rce-edit-btn"
            color="secondary"
            onClick={event => {
              props.onChangeView(isHtmlView() ? WYSIWYG_VIEW : getHtmlEditorView(event))
            }}
            onKeyUp={event => {
              if (props.editorView === WYSIWYG_VIEW && event.shiftKey && event.keyCode === 79) {
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
    if (!document[FS_ENABLED]) return null
    if (props.editorView === RAW_HTML_EDITOR_VIEW && !('requestFullscreen' in document.body)) {
      // this is safari, which refuses to fullscreen a textarea
      return null
    }
    const fullscreen = props.rceIsFullscreen
      ? formatMessage('Exit Fullscreen')
      : formatMessage('Fullscreen')
    return (
      <IconButton
        data-btn-id="rce-fullscreen-btn"
        color="secondary"
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
        <div style={{fontSize: '0.9rem'}}>
          {props.rceIsFullscreen ? <IconExitFullScreenLine /> : <IconFullScreenLine />}
        </div>
      </IconButton>
    )
  }

  function renderResizeHandle() {
    if (props.rceIsFullscreen) return null
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

  function renderAccessibleResizeHandle() {
    if (props.rceIsFullscreen) return null

    const increaseBtnId = 'rce-resize-increase-btn'
    const decreaseBtnId = 'rce-resize-decrease-btn'

    const handleResize = deltaY => {
      props.onResize(null, {deltaY, deltaX: 0})
    }

    return (
      <>
        <IconButton
          data-btn-id={increaseBtnId}
          data-testid={increaseBtnId}
          color="secondary"
          title={formatMessage('Increase Rich Content Area')}
          tabIndex={tabIndexForBtn(increaseBtnId)}
          onFocus={() => setFocusedBtnId(increaseBtnId)}
          withBackground={false}
          withBorder={false}
          onClick={() => handleResize(5)}
        >
          <IconAddLine />
        </IconButton>
        <IconButton
          data-btn-id={decreaseBtnId}
          data-testid={decreaseBtnId}
          color="secondary"
          title={formatMessage('Decrease Rich Content Area')}
          tabIndex={tabIndexForBtn(decreaseBtnId)}
          onFocus={() => setFocusedBtnId(decreaseBtnId)}
          withBackground={false}
          withBorder={false}
          onClick={() => handleResize(-5)}
        >
          <IconCheckMarkIndeterminateLine />
        </IconButton>
      </>
    )
  }

  const flexJustify = isHtmlView() ? 'end' : 'start'
  const html_view = isFeature('html_view') && isAvailable('instructure_html_view')
  const fullscreen = isFeature('fullscreen') && isAvailable('instructure_fullscreen')
  const resize_handle = isFeature('resize_handle')
  const a11y_resize_handlers = isFeature('a11y_resize_handlers')

  return (
    <InstUISettingsProvider
      theme={{
        componentOverrides: {
          IconButton: {
            secondaryGhostColor: 'rgb(34, 47, 62)', // to match tinymce's button color
          },
        },
      }}
    >
      <Flex
        id={props.id}
        padding="x-small 0 x-small x-small"
        data-testid="RCEStatusBar"
        justifyItems={flexJustify}
        ref={statusBarRef}
        onKeyDown={handleKey}
      >
        <Flex.Item shouldGrow={true}>
          {isHtmlView() ? renderHtmlEditorMessage() : renderPath()}
        </Flex.Item>

        <Flex.Item role="toolbar" title={formatMessage('Editor Status Bar')}>
          {renderIconButtons()}

          {isFeature('word_count') && isAvailable('instructure_wordcount') && renderWordCount()}
          {(html_view || fullscreen || resize_handle) &&
            renderSection3({html_view, fullscreen, resize_handle, a11y_resize_handlers})}
        </Flex.Item>
      </Flex>
    </InstUISettingsProvider>
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
    top: '.5rem',
  },
})
