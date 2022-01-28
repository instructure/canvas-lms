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
import React, { useState, useEffect } from 'react';
import { View } from '@instructure/ui-view';
import { useStoreProps } from "../../../shared/StoreContext.js";
import { useSvgSettings, statuses } from "../../svg/settings.js";
import { BTN_AND_ICON_ATTRIBUTE } from "../../registerEditToolbar.js";
import { buildSvg, buildStylesheet } from "../../svg/index.js";
import formatMessage from "../../../../../format-message.js";
import { Header } from "./Header.js";
import { ShapeSection } from "./ShapeSection.js";
import { ColorSection } from "./ColorSection.js";
import { TextSection } from "./TextSection.js";
import { ImageSection } from "./ImageSection/index.js";
import { Footer } from "./Footer.js";
export const CreateButtonForm = ({
  editor,
  onClose,
  editing
}) => {
  const _useSvgSettings = useSvgSettings(editor, editing),
        _useSvgSettings2 = _slicedToArray(_useSvgSettings, 3),
        settings = _useSvgSettings2[0],
        settingsStatus = _useSvgSettings2[1],
        dispatch = _useSvgSettings2[2];

  const _useState = useState(statuses.IDLE),
        _useState2 = _slicedToArray(_useState, 2),
        status = _useState2[0],
        setStatus = _useState2[1];

  const storeProps = useStoreProps();

  const handleSubmit = ({
    replaceFile = false
  }) => {
    setStatus(statuses.LOADING);
    const svg = buildSvg(settings, {
      isPreview: false
    });
    buildStylesheet().then(stylesheet => {
      svg.appendChild(stylesheet);
      return storeProps.startButtonsAndIconsUpload({
        name: `${settings.name || formatMessage('untitled')}.svg`,
        domElement: svg
      }, {
        onDuplicate: replaceFile && 'overwrite'
      });
    }).then(writeButtonToRCE).then(onClose).catch(() => setStatus(statuses.ERROR));
  };

  const writeButtonToRCE = ({
    url
  }) => {
    const img = editor.dom.createHTML('img', {
      src: url,
      alt: settings.alt,
      [BTN_AND_ICON_ATTRIBUTE]: true
    });
    editor.insertContent(img);
  };

  useEffect(() => {
    setStatus(settingsStatus);
  }, [settingsStatus]);
  return /*#__PURE__*/React.createElement(View, {
    as: "div"
  }, /*#__PURE__*/React.createElement(Header, {
    settings: settings,
    onChange: dispatch
  }), /*#__PURE__*/React.createElement(ShapeSection, {
    settings: settings,
    onChange: dispatch
  }), /*#__PURE__*/React.createElement(ColorSection, {
    settings: settings,
    onChange: dispatch
  }), /*#__PURE__*/React.createElement(TextSection, {
    settings: settings,
    onChange: dispatch
  }), /*#__PURE__*/React.createElement(ImageSection, {
    editor: editor,
    settings: settings,
    onChange: dispatch,
    editing: editing
  }), /*#__PURE__*/React.createElement(Footer, {
    disabled: status === statuses.LOADING,
    onCancel: onClose,
    onSubmit: handleSubmit,
    onReplace: () => handleSubmit({
      replaceFile: true
    }),
    editing: editing
  }));
};