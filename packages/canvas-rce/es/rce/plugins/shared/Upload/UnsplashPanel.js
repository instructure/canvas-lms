import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";
import _objectSpread from "@babel/runtime/helpers/esm/objectSpread2";

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
import React, { useState, useEffect, useReducer, useRef, useCallback } from 'react';
import { string, func, object } from 'prop-types';
import { TextInput } from '@instructure/ui-text-input';
import { Flex } from '@instructure/ui-flex';
import { View } from '@instructure/ui-view';
import { Avatar } from '@instructure/ui-avatar';
import { Img } from '@instructure/ui-img';
import { Spinner } from '@instructure/ui-spinner';
import { Alert } from '@instructure/ui-alerts';
import { Pagination } from '@instructure/ui-pagination';
import { Button } from '@instructure/ui-buttons';
import { debounce } from 'lodash';
import formatMessage from "../../../../format-message.js";
import { StyleSheet, css } from "../../../../common/aphroditeExtensions.js";
import UnsplashSVG from "./UnsplashSVG.js";

const unsplashFetchReducer = (state, action) => {
  switch (action.type) {
    case 'FETCH':
      return _objectSpread(_objectSpread({}, state), {}, {
        loading: true,
        hasLoaded: false
      });

    case 'FETCH_SUCCESS':
      return _objectSpread(_objectSpread({}, state), {}, {
        loading: false,
        hasLoaded: true,
        totalPages: action.payload.total_pages,
        totalResults: action.payload.total_results,
        results: _objectSpread(_objectSpread({}, state.results), {
          [state.searchPage]: action.payload.results
        })
      });

    case 'FETCH_FAILURE':
      return _objectSpread(_objectSpread({}, state), {}, {
        loading: false,
        error: true,
        hasLoaded: true
      });

    case 'SET_SEARCH_DATA':
      {
        const newState = _objectSpread(_objectSpread({}, state), action.payload);

        if (state.searchTerm !== action.payload.searchTerm) {
          newState.results = {};
        }

        return newState;
      }

    default:
      throw new Error('Not implemented');
    // Should never get here.
  }
};

const useUnsplashSearch = source => {
  const _useReducer = useReducer(unsplashFetchReducer, {
    loading: false,
    error: false,
    results: {},
    totalPages: 1,
    searchTerm: '',
    searchPage: 1
  }),
        _useReducer2 = _slicedToArray(_useReducer, 2),
        state = _useReducer2[0],
        dispatch = _useReducer2[1];

  const effectFirstRun = useRef(true);
  useEffect(() => {
    const fetchData = () => {
      dispatch({
        type: 'FETCH'
      });
      source.searchUnsplash(state.searchTerm, state.searchPage).then(results => {
        dispatch({
          type: 'FETCH_SUCCESS',
          payload: results
        });
      }).catch(() => {
        dispatch({
          type: 'FETCH_FAILURE'
        });
      });
    };

    if (effectFirstRun.current) {
      effectFirstRun.current = false;
    } else if (state.results[state.searchPage]) {// It's already in cache
    } else if (state.searchTerm.length > 0) {
      fetchData();
    }
  }, [state.searchTerm, state.searchPage, state.results, source]);
  return _objectSpread(_objectSpread({}, state), {}, {
    search: (term, page) => {
      dispatch({
        type: 'SET_SEARCH_DATA',
        payload: {
          searchTerm: term,
          searchPage: page
        }
      });
    }
  });
};

function Attribution({
  name,
  avatarUrl,
  profileUrl
}) {
  return /*#__PURE__*/React.createElement(Flex, null, /*#__PURE__*/React.createElement(Flex.Item, {
    margin: "xx-small"
  }, /*#__PURE__*/React.createElement(Avatar, {
    name: name,
    src: avatarUrl,
    size: "small",
    "data-fs-exclude": true
  })), /*#__PURE__*/React.createElement(Flex.Item, {
    margin: "xx-small",
    shrink: true
  }, /*#__PURE__*/React.createElement(Button, {
    size: "small",
    variant: "link-inverse",
    href: profileUrl,
    target: "_blank",
    rel: "noopener",
    fluidWidth: true
  }, name)));
}

function renderAlert(term, hasLoaded, totalResults, results, page, liveRegion) {
  if (hasLoaded && results[page] && term.length >= 1) {
    if (totalResults < 1) {
      return /*#__PURE__*/React.createElement(Alert, {
        variant: "info",
        transition: "none",
        liveRegion: liveRegion,
        timeout: 1000
      }, formatMessage('No results found for {term}.', {
        term
      }));
    }

    return /*#__PURE__*/React.createElement(Alert, {
      variant: "info",
      transition: "none",
      screenReaderOnly: true,
      liveRegion: liveRegion,
      timeout: 1000
    }, formatMessage('{totalResults} results found, {numDisplayed} results currently displayed', {
      totalResults,
      numDisplayed: results[page].length
    }));
  }
}

export default function UnsplashPanel({
  source,
  setUnsplashData,
  brandColor,
  liveRegion
}) {
  const _useState = useState(1),
        _useState2 = _slicedToArray(_useState, 2),
        page = _useState2[0],
        setPage = _useState2[1];

  const _useState3 = useState(''),
        _useState4 = _slicedToArray(_useState3, 2),
        term = _useState4[0],
        setTerm = _useState4[1];

  const _useState5 = useState(null),
        _useState6 = _slicedToArray(_useState5, 2),
        selectedImage = _useState6[0],
        setSelectedImage = _useState6[1];

  const _useState7 = useState(0),
        _useState8 = _slicedToArray(_useState7, 2),
        focusedImageIndex = _useState8[0],
        setFocusedImageIndex = _useState8[1];

  const _useUnsplashSearch = useUnsplashSearch(source),
        totalPages = _useUnsplashSearch.totalPages,
        totalResults = _useUnsplashSearch.totalResults,
        results = _useUnsplashSearch.results,
        loading = _useUnsplashSearch.loading,
        search = _useUnsplashSearch.search,
        hasLoaded = _useUnsplashSearch.hasLoaded;

  const debouncedSearch = useCallback(debounce(search, 1000), []);
  const resultRefs = [];
  const skipEffect = useRef(false);
  useEffect(() => {
    if (skipEffect.current) {
      skipEffect.current = false;
      return;
    }

    if (resultRefs[focusedImageIndex]) {
      resultRefs[focusedImageIndex].focus();
    }
  }, [focusedImageIndex, resultRefs]);
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(UnsplashSVG, {
    width: "10em"
  }), /*#__PURE__*/React.createElement(TextInput, {
    type: "search",
    renderLabel: formatMessage('Search Term'),
    value: term,
    onChange: (e, val) => {
      setFocusedImageIndex(0);
      setTerm(val);
      debouncedSearch(val, page);
    }
  }), loading ? /*#__PURE__*/React.createElement(Spinner, {
    renderTitle: function () {
      return formatMessage('Loading');
    },
    size: "large",
    margin: "0 0 0 medium"
  }) : /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(View, {
    margin: "0 small"
  }, renderAlert(term, hasLoaded, totalResults, results, page, liveRegion)), /*#__PURE__*/React.createElement("div", {
    className: css(styles.container),
    "data-testid": "UnsplashResultsContainer"
  }, results[page] && results[page].map(resultImage => /*#__PURE__*/React.createElement("div", {
    className: css(hoverStyles.imageWrapper, styles.imageWrapper),
    key: resultImage.id
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "link",
    fluidWidth: true,
    theme: {
      mediumPaddingHorizontal: '0'
    },
    onClick: () => {
      setSelectedImage(resultImage.id);
      setUnsplashData({
        id: resultImage.id,
        url: resultImage.urls.link,
        alt: resultImage.alt_text
      });
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: css(styles.imageContainer),
    style: resultImage.id === selectedImage ? {
      border: `5px solid ${brandColor}`,
      padding: '2px'
    } : null
  }, resultImage.id === selectedImage ? /*#__PURE__*/React.createElement(Alert, {
    variant: "info",
    transition: "none",
    screenReaderOnly: true,
    liveRegion: liveRegion,
    timeout: 1000
  }, `${formatMessage('Selected')}: ${resultImage.alt_text}`) : null, /*#__PURE__*/React.createElement(Img, {
    src: resultImage.urls.thumbnail,
    alt: resultImage.id === selectedImage ? `${formatMessage('Selected')} ${resultImage.alt_text}` : resultImage.alt_text,
    constrain: "contain",
    height: "10em"
  }))), /*#__PURE__*/React.createElement("div", {
    className: css(styles.imageAttribution)
  }, /*#__PURE__*/React.createElement(Attribution, {
    name: resultImage.user.name,
    avatarUrl: resultImage.user.avatar,
    profileUrl: resultImage.user.url
  })))))), totalPages > 1 && results && Object.keys(results).length > 0 && /*#__PURE__*/React.createElement(Flex, {
    as: "div",
    width: "100%",
    justifyItems: "center",
    margin: "small 0 small"
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    margin: "auto small auto small"
  }, /*#__PURE__*/React.createElement(Pagination, {
    as: "nav",
    variant: "compact",
    labelNext: formatMessage('Next Page'),
    labelPrev: formatMessage('Previous Page')
  }, Array.from(Array(totalPages)).map((_v, i) => /*#__PURE__*/React.createElement(Pagination.Page, {
    key: i // eslint-disable-line react/no-array-index-key
    ,
    onClick: () => {
      setPage(i + 1);
      search(term, i + 1);
    },
    current: i + 1 === page
  }, i + 1))))));
}
UnsplashPanel.propTypes = {
  setUnsplashData: func,
  source: object,
  brandColor: string,
  liveRegion: func
};
export const styles = StyleSheet.create({
  container: {
    marginTop: '12px',
    display: 'flex',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    flexWrap: 'wrap',
    flexFlow: 'row wrap',
    width: '100%'
  },
  imageWrapper: {
    position: 'relative',
    margin: '12px',
    'min-width': '200px'
  },
  imageAttribution: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    width: '100%',
    'min-height': '8px',
    opacity: 0,
    'background-color': '#2d3b45',
    'z-index': 99
  },
  imageContainer: {
    'text-align': 'center'
  },
  positionedText: {
    position: 'absolute',
    height: '100%',
    width: '100%',
    top: '0',
    left: '0'
  }
});
export const hoverStyles = StyleSheet.create({
  imageWrapper: {
    [`#:hover ${css(styles.imageAttribution)}`]: {
      opacity: 0.8
    },
    [`#:focus-within ${css(styles.imageAttribution)}`]: {
      opacity: 0.8
    }
  }
});