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
import React, { useState } from 'react';
import { arrayOf, bool, func, number, shape, string } from 'prop-types';
import { ScreenReaderContent } from '@instructure/ui-a11y-content';
import { Button, CloseButton } from '@instructure/ui-buttons';
import { Heading } from '@instructure/ui-heading';
import { RadioInput, RadioInputGroup } from '@instructure/ui-radio-input';
import { SimpleSelect } from '@instructure/ui-simple-select';
import { TextArea } from '@instructure/ui-text-area';
import { IconQuestionLine } from '@instructure/ui-icons';
import { Flex } from '@instructure/ui-flex';
import { FormFieldGroup } from '@instructure/ui-form-field';
import { View } from '@instructure/ui-view';
import { Tooltip } from '@instructure/ui-tooltip';
import { Tray } from '@instructure/ui-tray';
import { StoreProvider } from "../../shared/StoreContext.js";
import { ClosedCaptionPanel } from '@instructure/canvas-media';
import { CUSTOM, MIN_WIDTH_VIDEO, videoSizes, labelForImageSize, scaleToSize } from "../../instructure_image/ImageEmbedOptions.js";
import Bridge from "../../../../bridge/index.js";
import formatMessage from "../../../../format-message.js";
import DimensionsInput, { useDimensionsState } from "../../shared/DimensionsInput/index.js";
import { getTrayHeight } from "../../shared/trayUtils.js";

const getLiveRegion = () => document.getElementById('flash_screenreader_holder');

export default function VideoOptionsTray(props) {
  var _ENV, _ENV$FEATURES;

  const videoOptions = props.videoOptions,
        onEntered = props.onEntered,
        onExited = props.onExited,
        onRequestClose = props.onRequestClose,
        onSave = props.onSave,
        open = props.open,
        trayProps = props.trayProps,
        id = props.id;
  const naturalHeight = videoOptions.naturalHeight,
        naturalWidth = videoOptions.naturalWidth;
  const currentHeight = videoOptions.appliedHeight || naturalHeight;
  const currentWidth = videoOptions.appliedWidth || naturalWidth;

  const _useState = useState(videoOptions.titleText),
        _useState2 = _slicedToArray(_useState, 2),
        titleText = _useState2[0],
        setTitleText = _useState2[1];

  const _useState3 = useState('embed'),
        _useState4 = _slicedToArray(_useState3, 2),
        displayAs = _useState4[0],
        setDisplayAs = _useState4[1];

  const _useState5 = useState(videoOptions.videoSize),
        _useState6 = _slicedToArray(_useState5, 2),
        videoSize = _useState6[0],
        setVideoSize = _useState6[1];

  const _useState7 = useState(currentHeight),
        _useState8 = _slicedToArray(_useState7, 2),
        videoHeight = _useState8[0],
        setVideoHeight = _useState8[1];

  const _useState9 = useState(currentWidth),
        _useState10 = _slicedToArray(_useState9, 2),
        videoWidth = _useState10[0],
        setVideoWidth = _useState10[1];

  const _useState11 = useState(videoOptions.tracks || []),
        _useState12 = _slicedToArray(_useState11, 2),
        subtitles = _useState12[0],
        setSubtitles = _useState12[1];

  const _useState13 = useState(MIN_WIDTH_VIDEO),
        _useState14 = _slicedToArray(_useState13, 1),
        minWidth = _useState14[0];

  const _useState15 = useState(Math.round(videoHeight / videoWidth * MIN_WIDTH_VIDEO)),
        _useState16 = _slicedToArray(_useState15, 1),
        minHeight = _useState16[0];

  const dimensionsState = useDimensionsState(videoOptions, {
    minHeight,
    minWidth
  });

  function handleTitleTextChange(event) {
    setTitleText(event.target.value);
  }

  function handleDisplayAsChange(event) {
    event.target.focus();
    setDisplayAs(event.target.value);
  }

  function handleVideoSizeChange(event, selectedOption) {
    setVideoSize(selectedOption.value);

    if (selectedOption.value === CUSTOM) {
      setVideoHeight(currentHeight);
      setVideoWidth(currentWidth);
    } else {
      const _scaleToSize = scaleToSize(selectedOption.value, naturalWidth, naturalHeight),
            height = _scaleToSize.height,
            width = _scaleToSize.width;

      setVideoHeight(height);
      setVideoWidth(width);
    }
  }

  function handleUpdateSubtitles(new_subtitles) {
    setSubtitles(new_subtitles);
  }

  function handleSave(event, updateMediaObject) {
    event.preventDefault();
    let appliedHeight = videoHeight;
    let appliedWidth = videoWidth;

    if (videoSize === CUSTOM) {
      appliedHeight = dimensionsState.height;
      appliedWidth = dimensionsState.width;
    }

    onSave({
      media_object_id: videoOptions.id,
      titleText,
      appliedHeight,
      appliedWidth,
      displayAs,
      subtitles,
      updateMediaObject
    });
  }

  const tooltipText = formatMessage('Used by screen readers to describe the video');
  const textAreaLabel = /*#__PURE__*/React.createElement(Flex, {
    alignItems: "center"
  }, /*#__PURE__*/React.createElement(Flex.Item, null, formatMessage('Title')), /*#__PURE__*/React.createElement(Flex.Item, {
    margin: "0 0 0 xx-small"
  }, /*#__PURE__*/React.createElement(Tooltip, {
    on: ['hover', 'focus'],
    placement: "top",
    tip: /*#__PURE__*/React.createElement(View, {
      display: "block",
      id: "alt-text-label-tooltip",
      maxWidth: "14rem"
    }, tooltipText)
  }, /*#__PURE__*/React.createElement(Button, {
    icon: IconQuestionLine,
    size: "small",
    variant: "icon"
  }, /*#__PURE__*/React.createElement(ScreenReaderContent, null, tooltipText)))));
  const messagesForSize = [];

  if (videoSize !== CUSTOM) {
    messagesForSize.push({
      text: formatMessage('{width} x {height}px', {
        height: videoHeight,
        width: videoWidth
      }),
      type: 'hint'
    });
  }

  const saveDisabled = displayAs === 'embed' && (titleText === '' || videoSize === CUSTOM && !dimensionsState.isValid); //  yes I know ENV shouldn't be used in the sub-package, but it's temporary

  const cc_in_rce_video_tray = !!((_ENV = ENV) !== null && _ENV !== void 0 && (_ENV$FEATURES = _ENV.FEATURES) !== null && _ENV$FEATURES !== void 0 && _ENV$FEATURES.cc_in_rce_video_tray);
  return /*#__PURE__*/React.createElement(StoreProvider, trayProps, contentProps => /*#__PURE__*/React.createElement(Tray, {
    key: "video-options-tray",
    "data-mce-component": true,
    label: formatMessage('Video Options Tray'),
    onDismiss: onRequestClose,
    onEntered: onEntered,
    onExited: onExited,
    open: open,
    placement: "end",
    shouldCloseOnDocumentClick: true,
    shouldContainFocus: true,
    shouldReturnFocus: true,
    size: cc_in_rce_video_tray ? 'regular' : void 0
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
  }, formatMessage('Video Options'))), /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(CloseButton, {
    placemet: "static",
    variant: "icon",
    onClick: onRequestClose
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
  }, /*#__PURE__*/React.createElement(TextArea, {
    "aria-describedby": "alt-text-label-tooltip",
    disabled: displayAs === 'link',
    height: "4rem",
    label: textAreaLabel,
    onChange: handleTitleTextChange,
    placeholder: formatMessage('(Describe the video)'),
    resize: "vertical",
    value: titleText
  })), /*#__PURE__*/React.createElement(Flex.Item, {
    margin: "small none none none",
    padding: "small"
  }, /*#__PURE__*/React.createElement(RadioInputGroup, {
    description: formatMessage('Display Options'),
    name: "display-video-as",
    onChange: handleDisplayAsChange,
    value: displayAs
  }, /*#__PURE__*/React.createElement(RadioInput, {
    label: formatMessage('Embed Video'),
    value: "embed"
  }), /*#__PURE__*/React.createElement(RadioInput, {
    label: formatMessage('Display Text Link (Opens in a new tab)'),
    value: "link"
  }))), /*#__PURE__*/React.createElement(Flex.Item, {
    margin: "small none xx-small none"
  }, /*#__PURE__*/React.createElement(View, {
    as: "div",
    padding: "small small xx-small small"
  }, /*#__PURE__*/React.createElement(SimpleSelect, {
    id: `${id}-size`,
    disabled: displayAs !== 'embed',
    renderLabel: formatMessage('Size'),
    messages: messagesForSize,
    assistiveText: formatMessage('Use arrow keys to navigate options.'),
    onChange: handleVideoSizeChange,
    value: videoSize
  }, videoSizes.map(size => /*#__PURE__*/React.createElement(SimpleSelect.Option, {
    id: `${id}-size-${size}`,
    key: size,
    value: size
  }, labelForImageSize(size))))), videoSize === CUSTOM && /*#__PURE__*/React.createElement(View, {
    as: "div",
    padding: "xx-small small"
  }, /*#__PURE__*/React.createElement(DimensionsInput, {
    dimensionsState: dimensionsState,
    disabled: displayAs !== 'embed',
    minHeight: minHeight,
    minWidth: minWidth
  }))), cc_in_rce_video_tray && /*#__PURE__*/React.createElement(Flex.Item, {
    padding: "small"
  }, /*#__PURE__*/React.createElement(FormFieldGroup, {
    description: formatMessage('Closed Captions/Subtitles')
  }, /*#__PURE__*/React.createElement(ClosedCaptionPanel, {
    subtitles: subtitles.map(st => ({
      locale: st.locale,
      file: {
        name: st.language || st.locale
      } // this is an artifact of ClosedCaptionCreatorRow's inards

    })),
    uploadMediaTranslations: Bridge.uploadMediaTranslations,
    languages: Bridge.languages,
    updateSubtitles: handleUpdateSubtitles,
    liveRegion: getLiveRegion
  }))))), /*#__PURE__*/React.createElement(Flex.Item, {
    background: "secondary",
    borderWidth: "small none none none",
    padding: "small medium",
    textAlign: "end"
  }, /*#__PURE__*/React.createElement(Button, {
    disabled: saveDisabled,
    onClick: event => handleSave(event, contentProps.updateMediaObject),
    variant: "primary"
  }, formatMessage('Done'))))))));
}
VideoOptionsTray.propTypes = {
  videoOptions: shape({
    titleText: string.isRequired,
    appliedHeight: number,
    appliedWidth: number,
    naturalHeight: number.isRequired,
    naturalWidth: number.isRequired,
    tracks: arrayOf(shape({
      locale: string.isRequired
    }))
  }).isRequired,
  onEntered: func,
  onExited: func,
  onRequestClose: func.isRequired,
  onSave: func.isRequired,
  open: bool.isRequired,
  trayProps: shape({
    host: string.isRequired,
    jwt: string.isRequired
  }),
  id: string
};
VideoOptionsTray.defaultProps = {
  onEntered: null,
  onExited: null,
  id: 'video-options-tray'
};