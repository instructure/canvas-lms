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
import React, { Suspense, useCallback, useEffect, useRef, useState } from 'react';
import { bool, func, instanceOf, shape, string } from 'prop-types';
import { Tray } from '@instructure/ui-tray';
import { CloseButton } from '@instructure/ui-buttons';
import { Heading } from '@instructure/ui-heading';
import { Spinner } from '@instructure/ui-spinner';
import { Flex } from '@instructure/ui-flex';
import ErrorBoundary from "./ErrorBoundary.js";
import Bridge from "../../../bridge/Bridge.js";
import formatMessage from "../../../format-message.js";
import Filter, { useFilterSettings } from "./Filter.js";
import { StoreProvider } from "./StoreContext.js";
import { getTrayHeight } from "./trayUtils.js";
/**
 * Returns the translated tray label
 * @param {string} contentType - The type of content showing on tray
 * @param {string} contentSubtype - The current subtype of content loaded in the tray
 * @param {string} contextType - The user's context
 * @returns {string}
 */

function getTrayLabel(contentType, contentSubtype, contextType) {
  if (contentType === 'links' && contextType === 'course') {
    return formatMessage('Course Links');
  } else if (contentType === 'links' && contextType === 'group') {
    return formatMessage('Group Links');
  }

  switch (contentSubtype) {
    case 'buttons_and_icons':
      return formatMessage('Buttons and Icons');

    case 'images':
      if (contentType === 'course_files') return formatMessage('Course Images');
      if (contentType === 'group_files') return formatMessage('Group Images');
      return formatMessage('User Images');

    case 'media':
      if (contentType === 'course_files') return formatMessage('Course Media');
      if (contentType === 'group_files') return formatMessage('Group Media');
      return formatMessage('User Media');

    case 'documents':
      if (contentType === 'course_files') return formatMessage('Course Documents');
      if (contentType === 'group_files') return formatMessage('Group Documents');
      return formatMessage('User Documents');

    default:
      return formatMessage('Tray');
    // Shouldn't ever get here
  }
}

const thePanels = {
  buttons_and_icons: /*#__PURE__*/React.lazy(() => import('../instructure_buttons/components/SavedButtonList')),
  links: /*#__PURE__*/React.lazy(() => import('../instructure_links/components/LinksPanel')),
  images: /*#__PURE__*/React.lazy(() => import('../instructure_image/Images')),
  documents: /*#__PURE__*/React.lazy(() => import('../instructure_documents/components/DocumentsPanel')),
  media: /*#__PURE__*/React.lazy(() => import('../instructure_record/MediaPanel')),
  all: /*#__PURE__*/React.lazy(() => import('./FileBrowser')),
  unknown: /*#__PURE__*/React.lazy(() => import('./UnknownFileTypePanel'))
}; // Returns a Suspense wrapped lazy loaded component
// pulled from useLazy's cache

function DynamicPanel(props) {
  let key = '';

  if (props.contentType === 'links') {
    key = 'links';
  } else {
    key = props.contentSubtype in thePanels ? props.contentSubtype : 'unknown';
  }

  const Component = thePanels[key];
  return /*#__PURE__*/React.createElement(Suspense, {
    fallback: /*#__PURE__*/React.createElement(Spinner, {
      renderTitle: renderLoading,
      size: "large"
    })
  }, /*#__PURE__*/React.createElement(Component, props));
}

function renderLoading() {
  return formatMessage('Loading');
}

const FILTER_SETTINGS_BY_PLUGIN = {
  user_documents: {
    contextType: 'user',
    contentType: 'user_files',
    contentSubtype: 'documents',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  course_documents: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'documents',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  group_documents: {
    contextType: 'group',
    contentType: 'group_files',
    contentSubtype: 'documents',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  user_images: {
    contextType: 'user',
    contentType: 'user_files',
    contentSubtype: 'images',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  course_images: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'images',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  group_images: {
    contextType: 'group',
    contentType: 'group_files',
    contentSubtype: 'images',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  user_media: {
    contextType: 'user',
    contentType: 'user_files',
    contentSubtype: 'media',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  course_media: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'media',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  group_media: {
    contextType: 'group',
    contentType: 'group_files',
    contentSubtype: 'media',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  course_links: {
    contextType: 'course',
    contentType: 'links',
    contentSubtype: 'all',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  group_links: {
    contextType: 'group',
    contentType: 'links',
    contentSubtype: 'all',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  list_buttons_and_icons: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'buttons_and_icons',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  all: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'all',
    sortValue: 'alphabetical',
    sortDir: 'asc',
    searchString: ''
  }
};

function isLoading(cprops) {
  var _cprops$collections$a, _cprops$collections$a2, _cprops$collections$d, _cprops$collections$m, _cprops$collections$q, _cprops$collections$w, _cprops$documents$cou, _cprops$documents$use, _cprops$documents$gro, _cprops$media$course, _cprops$media$user, _cprops$media$group, _cprops$all_files;

  return ((_cprops$collections$a = cprops.collections.announcements) === null || _cprops$collections$a === void 0 ? void 0 : _cprops$collections$a.isLoading) || ((_cprops$collections$a2 = cprops.collections.assignments) === null || _cprops$collections$a2 === void 0 ? void 0 : _cprops$collections$a2.isLoading) || ((_cprops$collections$d = cprops.collections.discussions) === null || _cprops$collections$d === void 0 ? void 0 : _cprops$collections$d.isLoading) || ((_cprops$collections$m = cprops.collections.modules) === null || _cprops$collections$m === void 0 ? void 0 : _cprops$collections$m.isLoading) || ((_cprops$collections$q = cprops.collections.quizzes) === null || _cprops$collections$q === void 0 ? void 0 : _cprops$collections$q.isLoading) || ((_cprops$collections$w = cprops.collections.wikiPages) === null || _cprops$collections$w === void 0 ? void 0 : _cprops$collections$w.isLoading) || ((_cprops$documents$cou = cprops.documents.course) === null || _cprops$documents$cou === void 0 ? void 0 : _cprops$documents$cou.isLoading) || ((_cprops$documents$use = cprops.documents.user) === null || _cprops$documents$use === void 0 ? void 0 : _cprops$documents$use.isLoading) || ((_cprops$documents$gro = cprops.documents.group) === null || _cprops$documents$gro === void 0 ? void 0 : _cprops$documents$gro.isLoading) || ((_cprops$media$course = cprops.media.course) === null || _cprops$media$course === void 0 ? void 0 : _cprops$media$course.isLoading) || ((_cprops$media$user = cprops.media.user) === null || _cprops$media$user === void 0 ? void 0 : _cprops$media$user.isLoading) || ((_cprops$media$group = cprops.media.group) === null || _cprops$media$group === void 0 ? void 0 : _cprops$media$group.isLoading) || ((_cprops$all_files = cprops.all_files) === null || _cprops$all_files === void 0 ? void 0 : _cprops$all_files.isLoading);
}
/**
 * This component is used within various plugins to handle loading in content
 * from Canvas.  It is essentially the main component.
 */


export default function CanvasContentTray(props) {
  // should the tray be rendered open?
  const _useState = useState(false),
        _useState2 = _slicedToArray(_useState, 2),
        isOpen = _useState2[0],
        setIsOpen = _useState2[1]; // has the tray fully opened. we use this to defer rendering the content
  // until the tray is open.


  const _useState3 = useState(false),
        _useState4 = _slicedToArray(_useState3, 2),
        hasOpened = _useState4[0],
        setHasOpened = _useState4[1]; // should we close the tray after the user clicks on something in it?


  const _useState5 = useState(true),
        _useState6 = _slicedToArray(_useState5, 2),
        hidingTrayOnAction = _useState6[0],
        setHidingTrayOnAction = _useState6[1];

  const trayRef = useRef(null);
  const scrollingAreaRef = useRef(null);

  const _useFilterSettings = useFilterSettings(),
        _useFilterSettings2 = _slicedToArray(_useFilterSettings, 2),
        filterSettings = _useFilterSettings2[0],
        setFilterSettings = _useFilterSettings2[1];

  const _props = _objectSpread({}, props),
        bridge = _props.bridge,
        editor = _props.editor,
        onTrayClosing = _props.onTrayClosing;

  const handleDismissTray = useCallback(() => {
    // return focus to the RCE if focus was on this tray
    if (trayRef.current && trayRef.current.contains(document.activeElement)) {
      bridge.focusActiveEditor(false);
    }

    onTrayClosing && onTrayClosing(CanvasContentTray.globalOpenCount); // tell RCEWrapper we're closing if we're open

    setIsOpen(false);
  }, [bridge, onTrayClosing]);
  useEffect(() => {
    bridge.attachController({
      showTrayForPlugin(plugin) {
        // increment a counter that's used as the key when rendering
        // this gets us a new instance everytime, which is necessary
        // to get the queries run so we have up to date data.
        ++CanvasContentTray.globalOpenCount;
        setFilterSettings(FILTER_SETTINGS_BY_PLUGIN[plugin]);
        setIsOpen(true);
      },

      hideTray(forceClose) {
        if (forceClose || hidingTrayOnAction) {
          handleDismissTray();
        }
      }

    }, editor.id);
    return () => {
      bridge.detachController(editor.id);
    }; // it's OK the setFilterSettings is not a dependency
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [editor.id, bridge, handleDismissTray, hidingTrayOnAction]);
  useEffect(() => {
    if (hasOpened && scrollingAreaRef.current && !scrollingAreaRef.current.style.overscrollBehaviorY) {
      scrollingAreaRef.current.style.overscrollBehaviorY = 'contain';
    }
  }, [hasOpened]);

  function handleOpenTray() {
    bridge.focusEditor(editor);
    setHasOpened(true);
  }

  function handleExitTray() {
    onTrayClosing && onTrayClosing(true); // tell RCEWrapper we're closing
  }

  function handleCloseTray() {
    setHasOpened(false);
    onTrayClosing && onTrayClosing(false); // tell RCEWrapper we're closed
  }

  function handleFilterChange(newFilter, onChangeContext, onChangeSearchString, onChangeSortBy) {
    const newFilterSettings = _objectSpread({}, newFilter);

    if (newFilterSettings.sortValue) {
      newFilterSettings.sortDir = newFilterSettings.sortValue === 'alphabetical' ? 'asc' : 'desc';
      onChangeSortBy({
        sort: newFilterSettings.sortValue,
        dir: newFilterSettings.sortDir
      });
    }

    if ('searchString' in newFilterSettings && filterSettings.searchString !== newFilterSettings.searchString) {
      onChangeSearchString(newFilterSettings.searchString);
    }

    setFilterSettings(newFilterSettings);

    if (newFilterSettings.contentType) {
      let contextType, contextId;

      switch (newFilterSettings.contentType) {
        case 'user_files':
          contextType = 'user';
          contextId = props.containingContext.userId;
          break;

        case 'group_files':
          contextType = 'group';
          contextId = props.containingContext.contextId;
          break;

        case 'course_files':
          contextType = props.contextType;
          contextId = props.containingContext.contextId;
          break;

        case 'links':
          contextType = props.containingContext.contextType;
          contextId = props.containingContext.contextId;
      }

      onChangeContext({
        contextType,
        contextId
      });
    }
  }

  return /*#__PURE__*/React.createElement(StoreProvider, Object.assign({}, props, {
    key: CanvasContentTray.globalOpenCount,
    contextType: filterSettings.contextType || props.contextType
  }), contentProps => /*#__PURE__*/React.createElement(Tray, {
    "data-mce-component": true,
    "data-testid": "CanvasContentTray",
    label: getTrayLabel(filterSettings.contentType, filterSettings.contentSubtype, contentProps.contextType),
    open: isOpen,
    placement: "end",
    size: "regular",
    shouldContainFocus: true,
    shouldReturnFocus: false,
    shouldCloseOnDocumentClick: false,
    onDismiss: handleDismissTray,
    onClose: handleCloseTray,
    onExit: handleExitTray,
    onOpen: handleOpenTray,
    onEntered: () => {
      const c = document.querySelector('[role="main"]');
      let target_w = 0;

      if (c) {
        var _trayRef$current;

        const margin = window.getComputedStyle(c).direction === 'ltr' ? document.body.getBoundingClientRect().right - c.getBoundingClientRect().right : c.getBoundingClientRect().left;
        target_w = c.offsetWidth - ((_trayRef$current = trayRef.current) === null || _trayRef$current === void 0 ? void 0 : _trayRef$current.offsetWidth) + margin;

        if (target_w >= 320 && target_w < c.offsetWidth) {
          c.style.boxSizing = 'border-box';
          c.style.width = `${target_w}px`;
        }
      }

      setHidingTrayOnAction(target_w < 320);
    },
    onExiting: () => {
      const c = document.querySelector('[role="main"]');
      if (c) c.style.width = '';
    },
    contentRef: el => trayRef.current = el
  }, isOpen && hasOpened ? /*#__PURE__*/React.createElement(Flex, {
    direction: "column",
    as: "div",
    height: getTrayHeight(),
    overflowY: "hidden",
    tabIndex: "-1",
    "data-canvascontenttray-content": true
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    padding: "medium",
    shadow: "above"
  }, /*#__PURE__*/React.createElement(Flex, {
    margin: "none none medium none"
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    shouldgrow: true,
    shouldshrink: true
  }, /*#__PURE__*/React.createElement(Heading, {
    level: "h2"
  }, formatMessage('Add'))), /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(CloseButton, {
    placement: "end",
    onClick: handleDismissTray,
    "data-testid": "CloseButton_ContentTray",
    screenReaderLabel: formatMessage('Close')
  }))), /*#__PURE__*/React.createElement(Filter, Object.assign({}, filterSettings, {
    userContextType: props.contextType,
    containingContextType: props.containingContext.contextType,
    onChange: newFilter => {
      handleFilterChange(newFilter, contentProps.onChangeContext, contentProps.onChangeSearchString, contentProps.onChangeSortBy);
    },
    isContentLoading: isLoading(contentProps),
    use_rce_buttons_and_icons: props.use_rce_buttons_and_icons
  }))), /*#__PURE__*/React.createElement(Flex.Item, {
    shouldgrow: true,
    shouldshrink: true,
    margin: "xx-small xxx-small 0",
    elementRef: el => scrollingAreaRef.current = el
  }, /*#__PURE__*/React.createElement(ErrorBoundary, null, /*#__PURE__*/React.createElement(DynamicPanel, Object.assign({
    contentType: filterSettings.contentType,
    contentSubtype: filterSettings.contentSubtype,
    sortBy: {
      sort: filterSettings.sortValue,
      order: filterSettings.sortDir
    },
    searchString: filterSettings.searchString,
    source: props.source,
    jwt: props.jwt,
    host: props.host,
    refreshToken: props.refreshToken,
    context: {
      type: props.contextType,
      id: props.contextId
    }
  }, contentProps))))) : null));
}
CanvasContentTray.globalOpenCount = 0;

function requiredWithoutSource(props, propName, componentName) {
  if (props.source == null && props[propName] == null) {
    throw new Error(`The prop \`${propName}\` is marked as required in \`${componentName}\`, but its value is \`${props[propName]}\`.`);
  }
}

const trayPropsMap = {
  canUploadFiles: bool.isRequired,
  contextId: string.isRequired,
  // initial value indicating the user's context (e.g. student v teacher), not the tray's
  contextType: string.isRequired,
  // initial value indicating the user's context, not the tray's
  containingContext: shape({
    contextType: string.isRequired,
    contextId: string.isRequired,
    userId: string.isRequired
  }),
  filesTabDisabled: bool,
  host: requiredWithoutSource,
  jwt: requiredWithoutSource,
  refreshToken: func,
  source: shape({
    fetchImages: func.isRequired
  }),
  themeUrl: string
};
export const trayPropTypes = shape(trayPropsMap);
CanvasContentTray.propTypes = _objectSpread({
  bridge: instanceOf(Bridge).isRequired,
  editor: shape({
    id: string
  }).isRequired,
  onTrayClosing: func
}, trayPropsMap); // the way we define trayProps, eslint doesn't recognize the following as props

/* eslint-disable react/default-props-match-prop-types */

CanvasContentTray.defaultProps = {
  canUploadFiles: false,
  filesTabDisabled: false,
  refreshToken: null,
  source: null,
  themeUrl: null
};
/* eslint-enable react/default-props-match-prop-types */