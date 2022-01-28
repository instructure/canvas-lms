import _objectSpread from "@babel/runtime/helpers/esm/objectSpread2";
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
import { func, instanceOf, shape } from 'prop-types';
import { fileOrMediaObjectShape } from "../../shared/fileShape.js";
import classnames from 'classnames';
import { AccessibleContent } from '@instructure/ui-a11y-content';
import { Flex } from '@instructure/ui-flex';
import { View } from '@instructure/ui-view';
import { Text } from '@instructure/ui-text';
import { IconDragHandleLine, IconPublishSolid, IconUnpublishedSolid } from '@instructure/ui-icons';
import formatMessage from "../../../../format-message.js";
import { renderLink as renderLinkHtml } from "../../../contentRendering.js";
import dragHtml from "../../../../sidebar/dragHtml.js";
import { getIconFromType } from "../../shared/fileTypeUtils.js";
import { isPreviewable } from "../../shared/Previewable.js";
import { applyTimezoneOffsetToDate } from "../../shared/dateUtils.js";
export default function Link(props) {
  const _useState = useState(false),
        _useState2 = _slicedToArray(_useState, 2),
        isHovering = _useState2[0],
        setIsHovering = _useState2[1];

  const filename = props.filename,
        display_name = props.display_name,
        title = props.title,
        content_type = props.content_type,
        published = props.published,
        date = props.date;
  const Icon = getIconFromType(content_type);
  const color = published ? 'success' : 'primary'; // Uses user locale and timezone

  const dateString = formatMessage.date(applyTimezoneOffsetToDate(date, ENV.TIMEZONE), 'long');
  const publishedMsg = published ? formatMessage('published') : formatMessage('unpublished');

  function linkAttrsFromDoc() {
    const canPreview = isPreviewable(props.content_type);
    const clazz = classnames('instructure_file_link', {
      instructure_scribd_file: canPreview,
      inline_disabled: true
    });
    const attrs = {
      id: props.id,
      href: props.href,
      target: '_blank',
      class: clazz,
      text: props.display_name || props.filename,
      // because onClick only takes a single object
      content_type: props.content_type,
      // files have this
      // media_objects have these
      title: props.title,
      type: props.type,
      embedded_iframe_url: props.embedded_iframe_url
    };

    if (canPreview) {
      attrs['data-canvas-previewable'] = true;
    }

    return attrs;
  }

  function handleLinkClick(e) {
    e.preventDefault();
    props.onClick(linkAttrsFromDoc());
  }

  function handleHover(e) {
    setIsHovering(e.type === 'mouseenter');
  }

  let elementRef = null;

  if (props.focusRef) {
    elementRef = ref => props.focusRef.current = ref;
  }

  return /*#__PURE__*/React.createElement("div", {
    "data-testid": "instructure_links-Link",
    draggable: true,
    onDragStart: function (e) {
      const linkAttrs = linkAttrsFromDoc();
      dragHtml(e, renderLinkHtml(linkAttrs, linkAttrs.text));
    },
    onDragEnd: function () {
      document.body.click();
    },
    onMouseEnter: handleHover,
    onMouseLeave: handleHover,
    style: {
      position: 'relative'
    }
  }, /*#__PURE__*/React.createElement(View, {
    as: "div",
    role: "button",
    position: "relative",
    focusPosition: "inset",
    focusColor: "info",
    tabIndex: "0",
    "aria-describedby": props.describedByID,
    elementRef: elementRef,
    background: "primary",
    borderWidth: "0 0 small 0",
    padding: "x-small",
    width: "100%",
    onClick: handleLinkClick,
    onKeyDown: function (e) {
      // press the button on enter or space
      if (e.keyCode === 13 || e.keyCode === 32) {
        handleLinkClick(e);
      }
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      pointerEvents: 'none'
    }
  }, /*#__PURE__*/React.createElement(Flex, null, /*#__PURE__*/React.createElement(Flex.Item, {
    margin: "0 xx-small 0 0",
    size: "1.125rem"
  }, isHovering ? /*#__PURE__*/React.createElement(IconDragHandleLine, {
    size: "x-small",
    inline: false
  }) : null), /*#__PURE__*/React.createElement(Flex.Item, {
    grow: true,
    shrink: true
  }, /*#__PURE__*/React.createElement(Flex, null, /*#__PURE__*/React.createElement(Flex.Item, {
    padding: "0 x-small 0 0"
  }, /*#__PURE__*/React.createElement(Text, {
    color: color
  }, /*#__PURE__*/React.createElement(Icon, {
    size: "x-small"
  }))), /*#__PURE__*/React.createElement(Flex.Item, {
    padding: "0 x-small 0 0",
    grow: true,
    shrink: true,
    textAlign: "start"
  }, /*#__PURE__*/React.createElement(View, {
    as: "div",
    margin: "0"
  }, display_name || title || filename), dateString ? /*#__PURE__*/React.createElement(View, {
    as: "div"
  }, dateString) : null), /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(AccessibleContent, {
    alt: publishedMsg
  }, /*#__PURE__*/React.createElement(Text, {
    color: color
  }, published ? /*#__PURE__*/React.createElement(IconPublishSolid, {
    inline: false
  }) : /*#__PURE__*/React.createElement(IconUnpublishedSolid, {
    inline: false
  }))))))))));
}
Link.propTypes = _objectSpread(_objectSpread({
  focusRef: shape({
    current: instanceOf(Element)
  })
}, fileOrMediaObjectShape), {}, {
  onClick: func.isRequired
});
Link.defaultProps = {
  focusRef: null
};