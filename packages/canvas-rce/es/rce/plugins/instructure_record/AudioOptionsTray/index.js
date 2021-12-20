import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";

/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import React, { useState } from 'react';
import { arrayOf, bool, func, shape, string } from 'prop-types';
import { Flex } from '@instructure/ui-flex';
import { Tray } from '@instructure/ui-tray';
import { FormFieldGroup } from '@instructure/ui-form-field';
import { ClosedCaptionPanel } from '@instructure/canvas-media';
import { Button, CloseButton } from '@instructure/ui-buttons';
import { StoreProvider } from "../../shared/StoreContext.js";
import Bridge from "../../../../bridge/index.js";
import formatMessage from "../../../../format-message.js";
import { getTrayHeight } from "../../shared/trayUtils.js";
import { Heading } from '@instructure/ui-heading';

const getLiveRegion = () => document.getElementById('flash_screenreader_holder');

export default function AudioOptionsTray({
  open,
  onEntered,
  onExited,
  onDismiss,
  onSave,
  trayProps,
  audioOptions
}) {
  const _useState = useState(audioOptions.tracks || []),
        _useState2 = _slicedToArray(_useState, 2),
        subtitles = _useState2[0],
        setSubtitles = _useState2[1];

  const handleSave = (e, contentProps) => {
    onSave({
      media_object_id: audioOptions.id,
      subtitles,
      updateMediaObject: contentProps.updateMediaObject
    });
  };

  return /*#__PURE__*/React.createElement(StoreProvider, trayProps, contentProps => /*#__PURE__*/React.createElement(Tray, {
    key: "audio-options-tray",
    "data-mce-component": true,
    label: formatMessage('Audio Options Tray'),
    onDismiss: onDismiss,
    onEntered: onEntered,
    onExited: onExited,
    open: open,
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
  }, formatMessage('Audio Options'))), /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(CloseButton, {
    placement: "static",
    variant: "icon",
    onClick: onDismiss
  }, formatMessage('Close'))))), /*#__PURE__*/React.createElement(Flex.Item, {
    as: "form",
    grow: true,
    margin: "none",
    shrink: true
  }, /*#__PURE__*/React.createElement(Flex, {
    justifyItems: "space-between",
    direction: "column",
    height: "100%"
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    grow: true,
    padding: "small",
    shrink: true
  }, /*#__PURE__*/React.createElement(Flex, {
    direction: "column"
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    padding: "small"
  }, /*#__PURE__*/React.createElement(FormFieldGroup, {
    description: formatMessage('Closed Captions/Subtitles')
  }, /*#__PURE__*/React.createElement(ClosedCaptionPanel, {
    subtitles: subtitles.map(st => ({
      locale: st.locale,
      file: {
        name: st.language || st.locale
      }
    })),
    uploadMediaTranslations: Bridge.uploadMediaTranslations,
    languages: Bridge.languages,
    updateSubtitles: newSubtitles => setSubtitles(newSubtitles),
    liveRegion: getLiveRegion
  }))))), /*#__PURE__*/React.createElement(Flex.Item, {
    background: "secondary",
    borderWidth: "small none none none",
    padding: "small medium",
    textAlign: "end"
  }, /*#__PURE__*/React.createElement(Button, {
    onClick: e => handleSave(e, contentProps),
    variant: "primary"
  }, formatMessage('Done'))))))));
}
AudioOptionsTray.propTypes = {
  onEntered: func,
  onExited: func,
  onDismiss: func,
  onSave: func,
  open: bool.isRequired,
  trayProps: shape({
    host: string.isRequired,
    jwt: string.isRequired
  }).isRequired,
  audioOptions: shape({
    id: string.isRequired,
    titleText: string.isRequired,
    tracks: arrayOf(shape({
      locale: string.isRequired
    }))
  }).isRequired
};
AudioOptionsTray.defaultProps = {
  onEntered: null,
  onExited: null,
  onDismiss: null,
  onSave: null
};