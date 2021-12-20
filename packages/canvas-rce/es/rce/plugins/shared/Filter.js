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
import React, { useEffect, useState } from 'react';
import { bool, func, oneOf, string } from 'prop-types';
import formatMessage from "../../../format-message.js";
import { Flex } from '@instructure/ui-flex';
import { View } from '@instructure/ui-view';
import { TextInput } from '@instructure/ui-text-input';
import { SimpleSelect } from '@instructure/ui-simple-select';
import { IconButton } from '@instructure/ui-buttons';
import { ScreenReaderContent } from '@instructure/ui-a11y-content';
import { IconLinkLine, IconFolderLine, IconImageLine, IconDocumentLine, IconAttachMediaLine, IconSearchLine, IconXLine } from '@instructure/ui-icons';
const DEFAULT_FILTER_SETTINGS = {
  contentSubtype: 'all',
  contentType: 'links',
  sortValue: 'date_added',
  searchString: ''
};
export function useFilterSettings(default_settings) {
  const _useState = useState(default_settings || DEFAULT_FILTER_SETTINGS),
        _useState2 = _slicedToArray(_useState, 2),
        filterSettings = _useState2[0],
        setFilterSettings = _useState2[1];

  return [filterSettings, function (nextSettings) {
    setFilterSettings(_objectSpread(_objectSpread({}, filterSettings), nextSettings));
  }];
}

function fileLabelFromContext(contextType) {
  switch (contextType) {
    case 'user':
      return formatMessage('User Files');

    case 'course':
      return formatMessage('Course Files');

    case 'group':
      return formatMessage('Group Files');

    case 'files':
    default:
      return formatMessage('Files');
  }
}

function renderTypeOptions(contentType, contentSubtype, userContextType) {
  const options = [/*#__PURE__*/React.createElement(SimpleSelect.Option, {
    key: "links",
    id: "links",
    value: "links",
    renderBeforeLabel: IconLinkLine
  }, formatMessage('Links'))];

  if (userContextType === 'course' && contentType !== 'links' && contentSubtype !== 'all') {
    options.push( /*#__PURE__*/React.createElement(SimpleSelect.Option, {
      key: "course_files",
      id: "course_files",
      value: "course_files",
      renderBeforeLabel: IconFolderLine
    }, fileLabelFromContext('course')));
  }

  if (userContextType === 'group' && contentType !== 'links' && contentSubtype !== 'all') {
    options.push( /*#__PURE__*/React.createElement(SimpleSelect.Option, {
      key: "group_files",
      id: "group_files",
      value: "group_files",
      renderBeforeLabel: IconFolderLine
    }, fileLabelFromContext('group')));
  } // Buttons and Icons are only stored in course folders.


  if (contentSubtype !== 'buttons_and_icons') {
    options.push( /*#__PURE__*/React.createElement(SimpleSelect.Option, {
      key: "user_files",
      id: "user_files",
      value: "user_files",
      renderBeforeLabel: IconFolderLine
    }, fileLabelFromContext(contentType === 'links' || contentSubtype === 'all' ? 'files' : 'user')));
  }

  return options;
}

function renderType(contentType, contentSubtype, onChange, userContextType, containingContextType) {
  // Check containingContextType so that we always show context links
  if (containingContextType === 'course' || containingContextType === 'group') {
    return /*#__PURE__*/React.createElement(SimpleSelect, {
      renderLabel: /*#__PURE__*/React.createElement(ScreenReaderContent, null, formatMessage('Content Type')),
      assistiveText: formatMessage('Use arrow keys to navigate options.'),
      onChange: (e, selection) => {
        const changed = {
          contentType: selection.value
        };

        if (contentType === 'links') {
          // when changing away from links, go to all user files
          changed.contentSubtype = 'all';
        }

        onChange(changed);
      },
      value: contentType
    }, renderTypeOptions(contentType, contentSubtype, userContextType));
  } else {
    return /*#__PURE__*/React.createElement(View, {
      as: "div",
      borderWidth: "small",
      padding: "x-small small",
      borderRadius: "medium",
      width: "100%"
    }, /*#__PURE__*/React.createElement(ScreenReaderContent, null, formatMessage('Content Type')), fileLabelFromContext('user', contentSubtype));
  }
}

function shouldSearch(searchString) {
  return searchString.length === 0 || searchString.length >= 3;
}

export default function Filter(props) {
  const contentType = props.contentType,
        contentSubtype = props.contentSubtype,
        onChange = props.onChange,
        sortValue = props.sortValue,
        searchString = props.searchString,
        userContextType = props.userContextType,
        isContentLoading = props.isContentLoading,
        containingContextType = props.containingContextType;

  const _useState3 = useState(searchString),
        _useState4 = _slicedToArray(_useState3, 2),
        pendingSearchString = _useState4[0],
        setPendingSearchString = _useState4[1];

  const _useState5 = useState(0),
        _useState6 = _slicedToArray(_useState5, 2),
        searchInputTimer = _useState6[0],
        setSearchInputTimer = _useState6[1]; // only run on mounting to trigger change to correct contextType


  useEffect(() => {
    onChange({
      contentType
    });
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  function doSearch(value) {
    if (shouldSearch(value)) {
      if (searchInputTimer) {
        window.clearTimeout(searchInputTimer);
        setSearchInputTimer(0);
      }

      onChange({
        searchString: value
      });
    }
  }

  function handleChangeSearch(value) {
    setPendingSearchString(value);

    if (searchInputTimer) {
      window.clearTimeout(searchInputTimer);
    }

    const tid = window.setTimeout(() => doSearch(value), 250);
    setSearchInputTimer(tid);
  }

  function handleClear() {
    handleChangeSearch('');
  }

  const searchMessage = formatMessage('Enter at least 3 characters to search');
  const loadingMessage = formatMessage('Loading, please wait');
  const msg = isContentLoading ? loadingMessage : searchMessage;
  return /*#__PURE__*/React.createElement(View, {
    display: "block",
    direction: "column"
  }, renderType(contentType, contentSubtype, onChange, userContextType, containingContextType), contentType !== 'links' && /*#__PURE__*/React.createElement(Flex, {
    margin: "small none none none"
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    grow: true,
    shrink: true,
    margin: "none xx-small none none"
  }, /*#__PURE__*/React.createElement(SimpleSelect, {
    renderLabel: /*#__PURE__*/React.createElement(ScreenReaderContent, null, formatMessage('Content Subtype')),
    assistiveText: formatMessage('Use arrow keys to navigate options.'),
    onChange: (e, selection) => {
      const changed = {
        contentSubtype: selection.value
      };

      if (changed.contentSubtype === 'all') {
        // when flipped to All, the context needs to be user
        // so we can get media_objects, which are all returned in the user context
        changed.contentType = 'user_files';
      } else if (changed.contentSubtype === 'buttons_and_icons') {
        // Buttons and Icons only belong to Courses.
        changed.contentType = 'course_files';
      }

      onChange(changed);
    },
    value: contentSubtype
  }, /*#__PURE__*/React.createElement(SimpleSelect.Option, {
    id: "images",
    value: "images",
    renderBeforeLabel: IconImageLine
  }, formatMessage('Images')), /*#__PURE__*/React.createElement(SimpleSelect.Option, {
    id: "documents",
    value: "documents",
    renderBeforeLabel: IconDocumentLine
  }, formatMessage('Documents')), /*#__PURE__*/React.createElement(SimpleSelect.Option, {
    id: "media",
    value: "media",
    renderBeforeLabel: IconAttachMediaLine
  }, formatMessage('Media')), props.use_rce_buttons_and_icons && /*#__PURE__*/React.createElement(SimpleSelect.Option, {
    id: "buttons_and_icons",
    value: "buttons_and_icons",
    renderBeforeLabel: IconImageLine
  }, formatMessage('Buttons and Icons')), /*#__PURE__*/React.createElement(SimpleSelect.Option, {
    id: "all",
    value: "all"
  }, formatMessage('All')))), contentSubtype !== 'all' && /*#__PURE__*/React.createElement(Flex.Item, {
    grow: true,
    shrink: true,
    margin: "none none none xx-small"
  }, /*#__PURE__*/React.createElement(SimpleSelect, {
    renderLabel: /*#__PURE__*/React.createElement(ScreenReaderContent, null, formatMessage('Sort By')),
    assistiveText: formatMessage('Use arrow keys to navigate options.'),
    onChange: (e, selection) => {
      onChange({
        sortValue: selection.value
      });
    },
    value: sortValue
  }, /*#__PURE__*/React.createElement(SimpleSelect.Option, {
    id: "date_added",
    value: "date_added"
  }, formatMessage('Date Added')), /*#__PURE__*/React.createElement(SimpleSelect.Option, {
    id: "alphabetical",
    value: "alphabetical"
  }, formatMessage('Alphabetical'))))), /*#__PURE__*/React.createElement(View, {
    as: "div",
    margin: "small none none none"
  }, /*#__PURE__*/React.createElement(TextInput, {
    renderLabel: /*#__PURE__*/React.createElement(ScreenReaderContent, null, formatMessage('Search')),
    renderBeforeInput: /*#__PURE__*/React.createElement(IconSearchLine, {
      inline: false
    }),
    renderAfterInput: function () {
      if (pendingSearchString) {
        return /*#__PURE__*/React.createElement(IconButton, {
          screenReaderLabel: formatMessage('Clear'),
          onClick: handleClear,
          interaction: isContentLoading ? 'disabled' : 'enabled',
          withBorder: false,
          withBackground: false,
          size: "small"
        }, /*#__PURE__*/React.createElement(IconXLine, null));
      }

      return void 0;
    }(),
    messages: [{
      type: 'hint',
      text: msg
    }],
    placeholder: formatMessage('Search'),
    value: pendingSearchString,
    onChange: (e, value) => handleChangeSearch(value),
    onKeyDown: e => {
      if (e.key === 'Enter') {
        doSearch(pendingSearchString);
      }
    },
    interaction: isContentLoading ? 'readonly' : 'enabled'
  })));
}
Filter.propTypes = {
  /**
   * `contentSubtype` is the secondary filter setting, currently only used when
   * `contentType` is set to "files"
   */
  contentSubtype: string.isRequired,

  /**
   * `contentType` is the primary filter setting (e.g. links, files)
   */
  contentType: oneOf(['links', 'user_files', 'course_files', 'group_files']).isRequired,

  /**
   * `onChange` is called when any of the Filter settings are changed
   */
  onChange: func.isRequired,

  /**
   * `sortValue` defines how items in the CanvasContentTray are sorted
   */
  sortValue: string.isRequired,

  /**
   * `searchString` is used to search for matching file names. Must be >3 chars long
   */
  searchString: string.isRequired,

  /**
   * The user's context
   */
  userContextType: oneOf(['user', 'course', 'group']),

  /**
   * Is my content currently loading?
   */
  isContentLoading: bool,

  /**
   * The page context
   */
  containingContextType: oneOf(['user', 'course', 'group'])
};