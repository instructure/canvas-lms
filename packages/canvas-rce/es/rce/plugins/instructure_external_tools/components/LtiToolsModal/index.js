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
import { func, arrayOf, oneOfType, number, shape, string } from 'prop-types';
import { Modal } from '@instructure/ui-modal';
import { Button, CloseButton } from '@instructure/ui-buttons';
import { Heading } from '@instructure/ui-heading';
import { List } from '@instructure/ui-list';
import { View } from '@instructure/ui-view';
import { Flex } from '@instructure/ui-flex';
import { ScreenReaderContent } from '@instructure/ui-a11y-content';
import { TextInput } from '@instructure/ui-text-input';
import { IconSearchLine } from '@instructure/ui-icons';
import { Alert } from '@instructure/ui-alerts';
import formatMessage from "../../../../../format-message.js";
import LtiTool from "./LtiTool.js"; // TODO: we really need a way for the client to pass this to the RCE

const getLiveRegion = () => document.getElementById('flash_screenreader_holder');

const getFilterResults = (term, thingsToFilter) => {
  if (term.length <= 0) {
    return thingsToFilter;
  }

  const query = term ? new RegExp(term, 'i') : null;
  return thingsToFilter.filter(item => query && query.test(item.title));
};

export function LtiToolsModal(props) {
  const _useState = useState(''),
        _useState2 = _slicedToArray(_useState, 2),
        filterTerm = _useState2[0],
        setFilterTerm = _useState2[1];

  const _useState3 = useState(props.ltiButtons),
        _useState4 = _slicedToArray(_useState3, 2),
        filteredResults = _useState4[0],
        setFilteredResults = _useState4[1];

  const filterEmpty = filteredResults.length <= 0;
  return /*#__PURE__*/React.createElement(Modal, {
    "data-mce-component": true,
    liveRegion: getLiveRegion,
    size: "medium",
    theme: {
      mediumMaxWidth: '42rem'
    },
    label: formatMessage('Apps'),
    onDismiss: props.onDismiss,
    open: true,
    shouldCloseOnDocumentClick: true
  }, /*#__PURE__*/React.createElement(Modal.Header, {
    theme: {
      padding: '0.5rem'
    }
  }, /*#__PURE__*/React.createElement(CloseButton, {
    placement: "end",
    offset: "medium",
    onClick: props.onDismiss
  }, formatMessage('Close')), /*#__PURE__*/React.createElement(Heading, {
    margin: "small"
  }, formatMessage('All Apps')), /*#__PURE__*/React.createElement(View, {
    as: "div",
    padding: "x-small none x-small medium"
  }, /*#__PURE__*/React.createElement(TextInput, {
    type: "search",
    renderLabel: /*#__PURE__*/React.createElement(ScreenReaderContent, null, formatMessage('Search')),
    placeholder: formatMessage('Search'),
    renderAfterInput: /*#__PURE__*/React.createElement(IconSearchLine, {
      inline: false
    }),
    onChange: e => {
      setFilterTerm(e.target.value);
      setFilteredResults(getFilterResults(e.target.value, props.ltiButtons));
    }
  }))), /*#__PURE__*/React.createElement(Modal.Body, {
    overflow: "fit"
  }, /*#__PURE__*/React.createElement(Flex, {
    as: "div",
    direction: "column"
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    as: "div",
    shouldShrink: true,
    shouldGrow: true
  }, /*#__PURE__*/React.createElement(Alert, {
    liveRegion: getLiveRegion,
    variant: "info",
    screenReaderOnly: !filterEmpty
  }, filterEmpty && formatMessage('No results found for {filterTerm}', {
    filterTerm
  }), !filterEmpty && formatMessage(`Found { count, plural,
              =0 {# results}
              one {# result}
              other {# results}
            }`, {
    count: filteredResults.length
  })), function (ltiButtons) {
    return /*#__PURE__*/React.createElement(List, {
      variant: "unstyled"
    }, ltiButtons.sort((a, b) => a.title.localeCompare(b.title)).map(b => {
      return /*#__PURE__*/React.createElement(List.Item, {
        key: b.id
      }, /*#__PURE__*/React.createElement(View, {
        as: "div",
        padding: "medium medium small none"
      }, /*#__PURE__*/React.createElement(LtiTool, {
        title: b.title,
        image: b.image,
        onAction: () => {
          b.onAction();
          props.onDismiss();
        },
        description: b.description
      })));
    }));
  }(filteredResults)))), /*#__PURE__*/React.createElement(Modal.Footer, null, /*#__PURE__*/React.createElement(Button, {
    onClick: props.onDismiss,
    color: "primary"
  }, formatMessage('Done'))));
}
LtiToolsModal.propTypes = {
  ltiButtons: arrayOf(shape({
    description: string.isRequired,
    id: oneOfType([string, number]).isRequired,
    image: string.isRequired,
    onAction: func.isRequired,
    title: string.isRequired
  })),
  onDismiss: func.isRequired
};