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
import React, { useEffect, useState } from 'react';
import { func, shape, string } from 'prop-types';
import { BTN_AND_ICON_ATTRIBUTE } from "../../instructure_buttons/registerEditToolbar.js";
import Images from "../../instructure_image/Images/index.js";
export function rceToFile({
  createdAt,
  id,
  name,
  thumbnailUrl,
  type,
  url
}) {
  return {
    content_type: type,
    date: createdAt,
    display_name: name,
    filename: name,
    href: url,
    id,
    thumbnail_url: thumbnailUrl,
    [BTN_AND_ICON_ATTRIBUTE]: true
  };
}

const SavedButtonList = ({
  context,
  onImageEmbed,
  searchString,
  sortBy,
  source
}) => {
  const _useState = useState(null),
        _useState2 = _slicedToArray(_useState, 2),
        buttonsAndIconsBookmark = _useState2[0],
        setButtonsAndIconsBookmark = _useState2[1];

  const _useState3 = useState([]),
        _useState4 = _slicedToArray(_useState3, 2),
        buttonsAndIcons = _useState4[0],
        setButtonsAndIcons = _useState4[1];

  const _useState5 = useState(true),
        _useState6 = _slicedToArray(_useState5, 2),
        hasMore = _useState6[0],
        setHasMore = _useState6[1];

  const _useState7 = useState(true),
        _useState8 = _slicedToArray(_useState7, 2),
        isLoading = _useState8[0],
        setIsLoading = _useState8[1];

  const resetState = () => {
    setButtonsAndIconsBookmark(null);
    setButtonsAndIcons([]);
    setHasMore(true);
    setIsLoading(true);
  };

  const onLoadedImages = ({
    bookmark,
    files
  }) => {
    setButtonsAndIconsBookmark(bookmark);
    setHasMore(bookmark !== null);
    setIsLoading(false);
    setButtonsAndIcons(prevButtonsAndIcons => [...prevButtonsAndIcons, ...files.filter(({
      type
    }) => type === 'image/svg+xml').map(rceToFile)]);
  };

  const fetchButtonsAndIcons = bookmark => {
    setIsLoading(true);
    source.fetchButtonsAndIcons({
      contextId: context.id,
      contextType: context.type
    }, bookmark, searchString, sortBy, onLoadedImages);
  };

  useEffect(() => {
    resetState();
  }, [searchString, sortBy.order, sortBy.sort]);
  return /*#__PURE__*/React.createElement(Images, {
    contextType: context.type,
    fetchInitialImages: () => {
      fetchButtonsAndIcons();
    },
    fetchNextImages: () => {
      fetchButtonsAndIcons(buttonsAndIconsBookmark);
    },
    images: {
      [context.type]: {
        error: null,
        files: buttonsAndIcons,
        hasMore,
        isLoading
      }
    },
    onImageEmbed: onImageEmbed,
    searchString: searchString,
    sortBy: sortBy
  });
};

SavedButtonList.propTypes = {
  context: shape({
    id: string.isRequired,
    type: string.isRequired
  }),
  onImageEmbed: func.isRequired,
  searchString: string,
  sortBy: shape({
    order: string,
    sort: string
  }),
  source: shape({
    fetchButtonsAndIcons: func.isRequired
  })
};
export default SavedButtonList;