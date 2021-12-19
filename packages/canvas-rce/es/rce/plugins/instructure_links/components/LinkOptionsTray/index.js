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
import React, { useEffect, useState } from 'react';
import { checkPropTypes, bool, func, object, oneOf, shape, string } from 'prop-types';
import { Button, CloseButton } from '@instructure/ui-buttons';
import { Alert } from '@instructure/ui-alerts';
import { Heading } from '@instructure/ui-heading';
import { FormFieldGroup } from '@instructure/ui-form-field';
import { Checkbox } from '@instructure/ui-checkbox';
import { RadioInputGroup, RadioInput } from '@instructure/ui-radio-input';
import { TextInput } from '@instructure/ui-text-input';
import { Flex } from '@instructure/ui-flex';
import { Tray } from '@instructure/ui-tray';
import { View } from '@instructure/ui-view';
import validateURL from "../../validateURL.js";
import formatMessage from "../../../../../format-message.js";
import { DISPLAY_AS_LINK, DISPLAY_AS_EMBED, DISPLAY_AS_EMBED_DISABLED } from "../../../shared/ContentSelection.js";
import { getTrayHeight } from "../../../shared/trayUtils.js";
export default function LinkOptionsTray(props) {
  const content = props.content || {};
  const textToLink = content.text || '';
  const showText = content.onlyTextSelected;

  const _useState = useState(textToLink || ''),
        _useState2 = _slicedToArray(_useState, 2),
        text = _useState2[0],
        setText = _useState2[1];

  const _useState3 = useState(content.url || ''),
        _useState4 = _slicedToArray(_useState3, 2),
        url = _useState4[0],
        setUrl = _useState4[1];

  const _useState5 = useState(null),
        _useState6 = _slicedToArray(_useState5, 2),
        err = _useState6[0],
        setErr = _useState6[1];

  const _useState7 = useState(false),
        _useState8 = _slicedToArray(_useState7, 2),
        isValidURL = _useState8[0],
        setIsValidURL = _useState8[1];

  const _useState9 = useState(content.displayAs === DISPLAY_AS_EMBED),
        _useState10 = _slicedToArray(_useState9, 2),
        autoOpenPreview = _useState10[0],
        setAutoOpenPreview = _useState10[1];

  const _useState11 = useState(content.displayAs === DISPLAY_AS_EMBED_DISABLED),
        _useState12 = _slicedToArray(_useState11, 2),
        disablePreview = _useState12[0],
        setDisablePreview = _useState12[1];

  useEffect(() => {
    try {
      const v = validateURL(url);
      setIsValidURL(v);
      setErr(null);
    } catch (ex) {
      setIsValidURL(false);
      setErr(ex.message);
    }
  }, [url]);

  function handleSave(event) {
    event.preventDefault();
    const embedType = content.isPreviewable ? 'scribd' : null;
    const linkAttrs = {
      embed: embedType ? {
        type: embedType,
        autoOpenPreview: autoOpenPreview && !disablePreview,
        disablePreview
      } : null,
      text,
      target: '_blank',
      href: url,
      id: content.id || null,
      class: embedType ? void 0 : 'inline_disabled',
      forceRename: true // A change to "text" should always update the link's text

    };
    props.onSave(linkAttrs);
  }

  function handlePreviewChange(event) {
    setAutoOpenPreview(event.target.checked);
  }

  function handlePreviewOptionChange(_event, value) {
    setDisablePreview(value === 'overlay');
  }

  return /*#__PURE__*/React.createElement(Tray, {
    "data-testid": "RCELinkOptionsTray",
    "data-mce-component": true,
    label: formatMessage('Link Options'),
    onDismiss: props.onRequestClose,
    onEntered: props.onEntered,
    onExited: props.onExited,
    open: props.open,
    placement: "end",
    shouldCloseOnDocumentClick: true,
    shouldContainFocus: true,
    shouldReturnFocus: true
  }, /*#__PURE__*/React.createElement(Flex, {
    direction: "column",
    height: getTrayHeight()
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    as: "header",
    padding: "medium"
  }, /*#__PURE__*/React.createElement(Flex, {
    direction: "row"
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    grow: true,
    shrink: true
  }, /*#__PURE__*/React.createElement(Heading, {
    as: "h2"
  }, formatMessage('Link Options'))), /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(CloseButton, {
    placement: "static",
    variant: "icon",
    onClick: props.onRequestClose
  }, formatMessage('Close'))))), /*#__PURE__*/React.createElement(Flex.Item, {
    as: "form",
    grow: true,
    margin: "none",
    shrink: true,
    onSubmit: handleSave
  }, /*#__PURE__*/React.createElement(Flex, {
    justifyItems: "space-between",
    direction: "column",
    height: "100%"
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    grow: true,
    padding: "small",
    shrink: true
  }, /*#__PURE__*/React.createElement("input", {
    type: "submit",
    style: {
      display: 'none'
    }
  }), /*#__PURE__*/React.createElement(Flex, {
    direction: "column"
  }, showText && /*#__PURE__*/React.createElement(Flex.Item, {
    padding: "small"
  }, /*#__PURE__*/React.createElement(TextInput, {
    renderLabel: () => formatMessage('Text'),
    onChange: function (event) {
      setText(event.target.value);
    },
    value: text
  })), /*#__PURE__*/React.createElement(Flex.Item, {
    padding: "small"
  }, /*#__PURE__*/React.createElement(TextInput, {
    renderLabel: () => formatMessage('Link'),
    onChange: function (event) {
      setUrl(event.target.value);
    },
    value: url
  })), err && /*#__PURE__*/React.createElement(Flex.Item, {
    padding: "small",
    "data-testid": "url-error"
  }, /*#__PURE__*/React.createElement(Alert, {
    variant: "error"
  }, err)), content.isPreviewable && /*#__PURE__*/React.createElement(Flex.Item, {
    margin: "small none none none",
    padding: "small"
  }, function () {
    return /*#__PURE__*/React.createElement(FormFieldGroup, {
      description: formatMessage('Display Options'),
      layout: "stacked",
      rowSpacing: "small"
    }, /*#__PURE__*/React.createElement(RadioInputGroup, {
      description: " "
      /* the FormFieldGroup is providing the label */
      ,
      name: "preview_option",
      onChange: handlePreviewOptionChange,
      value: disablePreview ? 'overlay' : 'inline'
    }, /*#__PURE__*/React.createElement(RadioInput, {
      key: "overlay",
      value: "overlay",
      label: formatMessage('Preview in overlay')
    }), /*#__PURE__*/React.createElement(RadioInput, {
      key: "inline",
      value: "inline",
      label: formatMessage('Preview inline')
    })), !disablePreview && /*#__PURE__*/React.createElement(View, {
      as: "div",
      margin: "0 0 0 small"
    }, /*#__PURE__*/React.createElement(Checkbox, {
      label: formatMessage('Expand preview by Default'),
      name: "auto-preview",
      onChange: handlePreviewChange,
      checked: autoOpenPreview
    })));
  }()))), /*#__PURE__*/React.createElement(Flex.Item, {
    background: "secondary",
    borderWidth: "small none none none",
    padding: "small medium",
    textAlign: "end"
  }, /*#__PURE__*/React.createElement(Button, {
    disabled: showText && !text || !(url && isValidURL),
    onClick: handleSave,
    variant: "primary"
  }, formatMessage('Done')))))));
}
LinkOptionsTray.propTypes = {
  // content is required only if the tray is open
  content: props => {
    if (props.open) {
      checkPropTypes({
        content: shape({
          $element: object,
          // the DOM's HTMLElement
          dispalyAs: oneOf([DISPLAY_AS_LINK, DISPLAY_AS_EMBED]),
          isPreviewable: bool,
          text: string,
          url: string
        }).isRequired
      }, props, 'content', 'LinkOptionsTray');
    }
  },
  onEntered: func,
  onExited: func,
  onRequestClose: func.isRequired,
  onSave: func.isRequired,
  open: bool.isRequired
};
LinkOptionsTray.defaultProps = {
  onEntered: null,
  onExited: null
};