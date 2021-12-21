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
import React from 'react';
import { func, instanceOf, number, shape, string } from 'prop-types';
import { Img } from '@instructure/ui-img';
import { Link } from '@instructure/ui-link';
import { Text } from '@instructure/ui-text';
import { TruncateText } from '@instructure/ui-truncate-text';
import { View } from '@instructure/ui-view';
import dragHtml from "../../../../sidebar/dragHtml.js";
import formatMessage from "../../../../format-message.js";
import { renderImage as renderImageHtml } from "../../../contentRendering.js";
export default function Image({
  focusRef,
  image,
  onClick
}) {
  const imgTitle = formatMessage('Click to embed {imageName}', {
    imageName: image.display_name
  });

  function handleDragStart(event) {
    dragHtml(event, renderImageHtml(image));
  }

  let elementRef = null;

  if (focusRef) {
    elementRef = ref => {
      focusRef.current = ref;
    };
  }

  return /*#__PURE__*/React.createElement(Link, {
    draggable: false,
    elementRef: elementRef,
    onClick: function (event) {
      event.preventDefault();
      onClick(image);
    },
    onDragStart: handleDragStart
  }, /*#__PURE__*/React.createElement(View, {
    as: "div",
    borderRadius: "medium",
    margin: "none none small none",
    overflowX: "hidden",
    overflowY: "hidden"
  }, /*#__PURE__*/React.createElement(Img, {
    alt: image.display_name,
    constrain: "cover",
    draggable: true,
    height: "6rem",
    inline: false,
    onDragStart: handleDragStart,
    onDragEnd: function () {
      document.body.click();
    },
    src: image.thumbnail_url,
    title: imgTitle,
    width: "6rem"
  })), /*#__PURE__*/React.createElement(TruncateText, null, /*#__PURE__*/React.createElement(Text, {
    size: "small"
  }, image.display_name)));
}
Image.propTypes = {
  focusRef: shape({
    current: instanceOf(Element)
  }),
  image: shape({
    display_name: string.isRequired,
    filename: string,
    href: string.isRequired,
    id: number,
    preview_url: string,
    thumbnail_url: string.isRequired
  }).isRequired,
  onClick: func.isRequired
};
Image.defaultProps = {
  focusRef: null
};