/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React from "react";
import { render, unmountComponentAtNode } from "react-dom";
import RCEWrapper from "./RCEWrapper";
import tinyRCE from "./tinyRCE";
import normalizeProps from "./normalizeProps";
import formatMessage from "../format-message";
import Bridge from "../bridge";
import skin from "tinymce-light-skin";

if (!process.env.BUILD_LOCALE) {
  formatMessage.setup({
    locale: "en",
    generateId: require("format-message-generate-id/underscored_crc32"),
    missingTranslation: "ignore"
  });
}

export function renderIntoDiv(target, props, renderCallback) {
  if (!props.skin) {
    skin.useCanvas();
  }
  // prevent tinymce from loading the theme
  tinyRCE.DOM.loadCSS = () => {};

  // normalize props
  props = normalizeProps(props, tinyRCE);

  formatMessage.setup({ locale: props.language });
  // render the editor to the target element
  let renderedComponent = render(
    <RCEWrapper
      {...props}
      handleUnmount={() => unmountComponentAtNode(target)}
    />,
    target
  );

  // connect the editor to the event bridge if no editor is currently active
  Bridge.renderEditor(renderedComponent);

  // pass it back
  renderCallback && renderCallback(renderedComponent);
}
