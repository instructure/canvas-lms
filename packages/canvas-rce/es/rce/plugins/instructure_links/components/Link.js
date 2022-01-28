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
import { func, oneOf, string } from 'prop-types';
import { linkShape } from "./propTypes.js";
import formatMessage from "../../../../format-message.js";
import { renderLink as renderLinkHtml } from "../../../contentRendering.js";
import dragHtml from "../../../../sidebar/dragHtml.js";
import { applyTimezoneOffsetToDate } from "../../shared/dateUtils.js";
import { AccessibleContent } from '@instructure/ui-a11y-content';
import { Flex } from '@instructure/ui-flex';
import { View } from '@instructure/ui-view';
import { Text } from '@instructure/ui-text';
import { Focusable } from '@instructure/ui-focusable';
import { SVGIcon } from '@instructure/ui-svg-images';
import { IconDragHandleLine, IconAssignmentLine, IconDiscussionLine, IconModuleLine, IconQuizLine, IconAnnouncementLine, IconPublishSolid, IconUnpublishedSolid, IconDocumentLine } from '@instructure/ui-icons';

function IconBlank() {
  return /*#__PURE__*/React.createElement(SVGIcon, {
    name: "IconBlank",
    viewBox: "0 0 1920 1920"
  }, /*#__PURE__*/React.createElement("g", {
    role: "presentation"
  }));
}

function getIcon(type) {
  switch (type) {
    case 'assignments':
      return IconAssignmentLine;

    case 'discussions':
      return IconDiscussionLine;

    case 'modules':
      return IconModuleLine;

    case 'quizzes':
      return IconQuizLine;

    case 'announcements':
      return IconAnnouncementLine;

    case 'wikiPages':
      return IconDocumentLine;

    case 'navigation':
      return IconBlank;

    default:
      return IconDocumentLine;
  }
}

export default function Link(props) {
  const _useState = useState(false),
        _useState2 = _slicedToArray(_useState, 2),
        isHovering = _useState2[0],
        setIsHovering = _useState2[1];

  const _props$link = props.link,
        title = _props$link.title,
        published = _props$link.published,
        date = _props$link.date,
        date_type = _props$link.date_type;
  const Icon = getIcon(props.type);
  const color = published ? 'success' : 'primary';
  let dateString = null;

  if (date) {
    if (date === 'multiple') {
      dateString = formatMessage('Due: Multiple Dates');
    } else {
      // Uses user locale and timezone
      const when = formatMessage.date(applyTimezoneOffsetToDate(date, ENV.TIMEZONE), 'long');

      switch (date_type) {
        case 'todo':
          dateString = formatMessage('To Do: {when}', {
            when
          });
          break;

        case 'published':
          dateString = formatMessage('Published: {when}', {
            when
          });
          break;

        case 'posted':
          dateString = formatMessage('Posted: {when}', {
            when
          });
          break;

        case 'delayed_post':
          dateString = formatMessage('To Be Posted: {when}', {
            when
          });
          break;

        case 'due':
        default:
          dateString = formatMessage('Due: {when}', {
            when
          });
          break;
      }
    }
  }

  const publishedMsg = props.link.published ? formatMessage('published') : formatMessage('unpublished');

  function handleLinkClick(e) {
    e.preventDefault();
    props.onClick(props.link);
  }

  function handleLinkKey(e) {
    // press the button on enter or space
    if (e.keyCode === 13 || e.keyCode === 32) {
      handleLinkClick(e);
    }
  }

  function handleHover(e) {
    setIsHovering(e.type === 'mouseenter');
  }

  return /*#__PURE__*/React.createElement("div", {
    "data-testid": "instructure_links-Link",
    draggable: true,
    onDragStart: function (e) {
      dragHtml(e, renderLinkHtml(props.link, props.link.title));
    },
    onDragEnd: function () {
      document.body.click(); // closes the tray
    },
    onMouseEnter: handleHover,
    onMouseLeave: handleHover,
    style: {
      position: 'relative'
    }
  }, /*#__PURE__*/React.createElement(Focusable, null, ({
    focused
  }) => /*#__PURE__*/React.createElement(View, {
    focused: focused,
    focusPosition: "inset",
    position: "relative",
    as: "div",
    role: "button",
    tabIndex: "0",
    background: "primary",
    display: "block",
    width: "100%",
    borderWidth: "0 0 small 0",
    padding: "x-small",
    "aria-describedby": props.describedByID,
    onClick: handleLinkClick,
    onKeyDown: handleLinkKey,
    elementRef: props.elementRef
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
    size: "x-small",
    inline: false
  }))), /*#__PURE__*/React.createElement(Flex.Item, {
    padding: "0 x-small 0 0",
    grow: true,
    shrink: true,
    textAlign: "start"
  }, /*#__PURE__*/React.createElement(View, {
    as: "div",
    margin: "0"
  }, title), dateString ? /*#__PURE__*/React.createElement(View, {
    as: "div"
  }, dateString) : null), 'published' in props.link && /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(AccessibleContent, {
    alt: publishedMsg
  }, /*#__PURE__*/React.createElement(Text, {
    color: color
  }, published ? /*#__PURE__*/React.createElement(IconPublishSolid, {
    inline: false
  }) : /*#__PURE__*/React.createElement(IconUnpublishedSolid, {
    inline: false
  })))))))))));
}
Link.propTypes = {
  link: linkShape.isRequired,
  type: oneOf(['assignments', 'discussions', 'modules', 'quizzes', 'announcements', 'wikiPages', 'navigation']).isRequired,
  onClick: func.isRequired,
  describedByID: string.isRequired,
  elementRef: func
};