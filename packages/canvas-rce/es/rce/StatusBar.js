import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";

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
import React, { useEffect, useRef, useState } from 'react';
import ReactDOM from 'react-dom';
import { arrayOf, bool, func, number, oneOf, string } from 'prop-types';
import { StyleSheet, css } from 'aphrodite';
import keycode from 'keycode';
import { CondensedButton, IconButton } from '@instructure/ui-buttons';
import { Flex } from '@instructure/ui-flex';
import { View } from '@instructure/ui-view';
import { Badge } from '@instructure/ui-badge';
import { ApplyTheme } from '@instructure/ui-themeable';
import { Text } from '@instructure/ui-text';
import { SVGIcon } from '@instructure/ui-svg-images';
import { IconA11yLine, IconKeyboardShortcutsLine, IconMiniArrowEndLine, IconFullScreenLine } from '@instructure/ui-icons';
import formatMessage from "../format-message.js";
import ResizeHandle from "./ResizeHandle.js";
export const WYSIWYG_VIEW = 'WYSIWYG';
export const PRETTY_HTML_EDITOR_VIEW = 'PRETTY';
export const RAW_HTML_EDITOR_VIEW = 'RAW'; // I don't know why eslint is reporting this, the props are all used

/* eslint-disable react/no-unused-prop-types */

StatusBar.propTypes = {
  onChangeView: func.isRequired,
  path: arrayOf(string),
  wordCount: number,
  editorView: oneOf(["WYSIWYG", "PRETTY", "RAW"]),
  onResize: func,
  // react-draggable onDrag handler.
  onKBShortcutModalOpen: func.isRequired,
  onA11yChecker: func.isRequired,
  onFullscreen: func.isRequired,
  use_rce_a11y_checker_notifications: bool,
  preferredHtmlEditor: oneOf(["PRETTY", "RAW"]),
  readOnly: bool,
  a11yBadgeColor: string,
  a11yErrorsCount: number
};
StatusBar.defaultProps = {
  a11yBadgeColor: '#FC5E13',
  a11yErrorsCount: 0
};
/* eslint-enable react/no-unused-prop-types */
// we use the array index because pathname may not be unique

/* eslint-disable react/no-array-index-key */

function renderPathString({
  path
}) {
  return path.reduce((result, pathName, index) => {
    return result.concat( /*#__PURE__*/React.createElement("span", {
      key: `${pathName}-${index}`
    }, /*#__PURE__*/React.createElement(Text, null, index > 0 ? /*#__PURE__*/React.createElement(IconMiniArrowEndLine, null) : null, pathName)));
  }, []);
}
/* eslint-enable react/no-array-index-key */


function emptyTagIcon() {
  return /*#__PURE__*/React.createElement(SVGIcon, {
    viewBox: "0 0 24 24",
    fontSize: "24px"
  }, /*#__PURE__*/React.createElement("g", {
    role: "presentation"
  }, /*#__PURE__*/React.createElement("text", {
    textAnchor: "middle",
    x: "12px",
    y: "18px",
    fontSize: "16"
  }, "</>")));
}

function findFocusable(el) {
  // eslint-disable-next-line react/no-find-dom-node
  const element = ReactDOM.findDOMNode(el);
  return element ? Array.from(element.querySelectorAll('[tabindex]')) : [];
}

export default function StatusBar(props) {
  const _useState = useState(null),
        _useState2 = _slicedToArray(_useState, 2),
        focusedBtnId = _useState2[0],
        setFocusedBtnId = _useState2[1];

  const _useState3 = useState(false),
        _useState4 = _slicedToArray(_useState3, 2),
        includeEdtrDesc = _useState4[0],
        setIncludeEdtrDesc = _useState4[1];

  const statusBarRef = useRef(null);
  useEffect(() => {
    const buttons = findFocusable(statusBarRef.current);
    setFocusedBtnId(buttons[0].getAttribute('data-btn-id'));
    buttons[0].setAttribute('tabIndex', '0');
  }, []);
  useEffect(() => {
    // the kbshortcut and a11y checker buttons are hidden when in html view
    // move focus to the next button over.
    if (isHtmlView() && /rce-kbshortcut-btn|rce-a11y-btn/.test(focusedBtnId)) {
      setFocusedBtnId('rce-edit-btn');
    } // adding a delay before including the HTML Editor description to wait the focus moves to the RCE
    // and prevent JAWS from reading the aria-describedby element when switching back to RCE view


    const timerid = setTimeout(() => {
      setIncludeEdtrDesc(!isHtmlView());
    }, 100);
    return () => clearTimeout(timerid);
  }, [props.editorView]); // eslint-disable-line react-hooks/exhaustive-deps

  function preferredHtmlEditor() {
    if (props.preferredHtmlEditor) return props.preferredHtmlEditor;
    return PRETTY_HTML_EDITOR_VIEW;
  }

  function getHtmlEditorView(event) {
    if (!event.shiftKey) return preferredHtmlEditor();
    return preferredHtmlEditor() === RAW_HTML_EDITOR_VIEW ? PRETTY_HTML_EDITOR_VIEW : RAW_HTML_EDITOR_VIEW;
  }

  function isHtmlView() {
    return props.editorView !== WYSIWYG_VIEW;
  }

  function tabIndexForBtn(itemId) {
    const tabindex = focusedBtnId === itemId ? '0' : '-1';
    return tabindex;
  }

  function renderA11yButton() {
    const a11y = formatMessage('Accessibility Checker');
    const button = /*#__PURE__*/React.createElement(IconButton, {
      "data-btn-id": "rce-a11y-btn",
      color: "primary",
      title: a11y,
      tabIndex: tabIndexForBtn('rce-a11y-btn'),
      onClick: event => {
        event.target.focus();
        props.onA11yChecker();
      },
      onFocus: () => setFocusedBtnId('rce-a11y-btn'),
      screenReaderLabel: a11y,
      withBackground: false,
      withBorder: false
    }, /*#__PURE__*/React.createElement(IconA11yLine, null));

    if (!props.use_rce_a11y_checker_notifications || props.a11yErrorsCount <= 0) {
      return button;
    }

    return /*#__PURE__*/React.createElement(ApplyTheme, {
      theme: {
        [Badge.theme]: {
          colorPrimary: props.a11yBadgeColor
        }
      }
    }, /*#__PURE__*/React.createElement(Badge, {
      count: props.a11yErrorsCount,
      countUntil: 100
    }, button));
  }

  function descMsg() {
    return preferredHtmlEditor() === RAW_HTML_EDITOR_VIEW ? formatMessage('Shift-O to open the pretty html editor.') : formatMessage('The pretty html editor is not keyboard accessible. Press Shift O to open the raw html editor.');
  }

  function renderFullscreen() {
    if (props.readOnly) return null;

    if (props.editorView === RAW_HTML_EDITOR_VIEW && !('requestFullscreen' in document.body)) {
      // this is safari, which refuses to fullscreen a textarea
      return null;
    }

    const fullscreen = formatMessage('Fullscreen');
    return /*#__PURE__*/React.createElement(IconButton, {
      "data-btn-id": "rce-fullscreen-btn",
      color: "primary",
      title: fullscreen,
      tabIndex: tabIndexForBtn('rce-fullscreen-btn'),
      onClick: event => {
        event.target.focus();
        props.onFullscreen();
      },
      onFocus: () => setFocusedBtnId('rce-fullscreen-btn'),
      screenReaderLabel: fullscreen,
      withBackground: false,
      withBorder: false
    }, /*#__PURE__*/React.createElement(IconFullScreenLine, null));
  }

  const flexJustify = isHtmlView() ? 'end' : 'start';
  return /*#__PURE__*/React.createElement(Flex, {
    margin: "x-small 0 x-small x-small",
    "data-testid": "RCEStatusBar",
    justifyItems: flexJustify,
    ref: statusBarRef,
    onKeyDown: function (event) {
      const buttons = findFocusable(statusBarRef.current).filter(b => !b.disabled);
      const focusedIndex = buttons.findIndex(b => b.getAttribute('data-btn-id') === focusedBtnId);
      let newFocusedIndex;

      if (event.keyCode === keycode.codes.right) {
        newFocusedIndex = (focusedIndex + 1) % buttons.length;
      } else if (event.keyCode === keycode.codes.left) {
        newFocusedIndex = (focusedIndex + buttons.length - 1) % buttons.length;
      } else {
        return;
      }

      buttons[newFocusedIndex].focus();
      setFocusedBtnId(buttons[newFocusedIndex].getAttribute('data-btn-id'));
    }
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    shouldGrow: true
  }, isHtmlView() ? function () {
    const message = props.editorView === PRETTY_HTML_EDITOR_VIEW ? formatMessage('Sadly, the pretty HTML editor is not keyboard accessible. Access the raw HTML editor here.') : formatMessage('Access the pretty HTML editor');
    const label = props.editorView === PRETTY_HTML_EDITOR_VIEW ? formatMessage('Raw HTML Editor') : formatMessage('Pretty HTML Editor');
    return /*#__PURE__*/React.createElement(View, {
      "data-testid": "html-editor-message"
    }, /*#__PURE__*/React.createElement(CondensedButton, {
      "data-btn-id": "rce-editormessage-btn",
      margin: "0 small",
      title: message,
      tabIndex: tabIndexForBtn('rce-editormessage-btn'),
      onClick: event => {
        event.target.focus();
        props.onChangeView(props.editorView === PRETTY_HTML_EDITOR_VIEW ? RAW_HTML_EDITOR_VIEW : PRETTY_HTML_EDITOR_VIEW);
      },
      onFocus: () => setFocusedBtnId('rce-editormessage-btn')
    }, label));
  }() : function () {
    return /*#__PURE__*/React.createElement(View, {
      "data-testid": "whole-status-bar-path"
    }, renderPathString(props));
  }()), /*#__PURE__*/React.createElement(Flex.Item, {
    role: "toolbar",
    title: formatMessage('Editor Statusbar')
  }, function () {
    if (isHtmlView()) return null;
    const kbshortcut = formatMessage('View keyboard shortcuts');
    return /*#__PURE__*/React.createElement(View, {
      display: "inline-block",
      padding: "0 x-small"
    }, /*#__PURE__*/React.createElement(IconButton, {
      "data-btn-id": "rce-kbshortcut-btn",
      color: "primary",
      "aria-haspopup": "dialog",
      title: kbshortcut,
      tabIndex: tabIndexForBtn('rce-kbshortcut-btn'),
      onClick: event => {
        event.target.focus(); // FF doesn't focus buttons on click

        props.onKBShortcutModalOpen();
      },
      onFocus: () => setFocusedBtnId('rce-kbshortcut-btn'),
      screenReaderLabel: kbshortcut,
      withBackground: false,
      withBorder: false
    }, /*#__PURE__*/React.createElement(IconKeyboardShortcutsLine, null)), props.readOnly || renderA11yButton());
  }(), /*#__PURE__*/React.createElement("div", {
    className: css(styles.separator)
  }), function () {
    if (isHtmlView()) return null;
    const wordCount = formatMessage(`{count, plural,
         =0 {0 words}
        one {1 word}
      other {# words}
    }`, {
      count: props.wordCount
    });
    return /*#__PURE__*/React.createElement(View, {
      display: "inline-block",
      padding: "0 small",
      "data-testid": "status-bar-word-count"
    }, /*#__PURE__*/React.createElement(Text, null, wordCount));
  }(), /*#__PURE__*/React.createElement("div", {
    className: css(styles.separator)
  }), function () {
    const toggleToHtml = formatMessage('Switch to the html editor');
    const toggleToRich = formatMessage('Switch to the rich text editor');
    const toggleToHtmlTip = formatMessage('Click or shift-click for the html editor.');
    const descText = isHtmlView() ? toggleToRich : toggleToHtml;
    const titleText = isHtmlView() ? toggleToRich : toggleToHtmlTip;
    return /*#__PURE__*/React.createElement(View, {
      display: "inline-block",
      padding: "0 0 0 x-small"
    }, props.readOnly || /*#__PURE__*/React.createElement(IconButton, {
      "data-btn-id": "rce-edit-btn",
      color: "primary",
      onClick: event => {
        props.onChangeView(isHtmlView() ? WYSIWYG_VIEW : getHtmlEditorView(event));
      },
      onKeyUp: event => {
        if (props.editorView === WYSIWYG_VIEW && event.shiftKey && event.keyCode === 79) {
          const html_view = preferredHtmlEditor() === RAW_HTML_EDITOR_VIEW ? PRETTY_HTML_EDITOR_VIEW : RAW_HTML_EDITOR_VIEW;
          props.onChangeView(html_view);
        }
      },
      onFocus: () => setFocusedBtnId('rce-edit-btn'),
      title: titleText,
      tabIndex: tabIndexForBtn('rce-edit-btn'),
      "aria-describedby": includeEdtrDesc ? 'edit-button-desc' : void 0,
      screenReaderLabel: descText,
      withBackground: false,
      withBorder: false
    }, emptyTagIcon()), includeEdtrDesc && /*#__PURE__*/React.createElement("span", {
      style: {
        display: 'none'
      },
      id: "edit-button-desc"
    }, descMsg()));
  }(), renderFullscreen(), function () {
    return /*#__PURE__*/React.createElement(ResizeHandle, {
      "data-btn-id": "rce-resize-handle",
      onDrag: props.onResize,
      tabIndex: tabIndexForBtn('rce-resize-handle'),
      onFocus: () => {
        setFocusedBtnId('rce-resize-handle');
      }
    });
  }()));
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