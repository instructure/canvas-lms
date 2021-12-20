import _objectSpread from "@babel/runtime/helpers/esm/objectSpread2";

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
import React, { useEffect } from 'react';
import { View } from '@instructure/ui-view';
import ImageList from "../../../../instructure_image/Images/index.js";
import { useStoreProps } from "../../../../shared/StoreContext.js";
import useDataUrl from "../../../../shared/useDataUrl.js";
import { actions } from "../../../reducers/imageSection.js";

const Course = ({
  dispatch
}) => {
  const storeProps = useStoreProps();
  const _storeProps$images$st = storeProps.images[storeProps.contextType],
        files = _storeProps$images$st.files,
        bookmark = _storeProps$images$st.bookmark,
        isLoading = _storeProps$images$st.isLoading,
        hasMore = _storeProps$images$st.hasMore;

  const _useDataUrl = useDataUrl(),
        setUrl = _useDataUrl.setUrl,
        dataUrl = _useDataUrl.dataUrl,
        dataLoading = _useDataUrl.dataLoading,
        dataError = _useDataUrl.dataError; // Handle image selection


  useEffect(() => {
    // Don't clear the current image on re-render
    if (!dataUrl) return;
    dispatch(_objectSpread(_objectSpread({}, actions.SET_IMAGE), {}, {
      payload: dataUrl
    }));
  }, [dataUrl]); // Handle loading states

  useEffect(() => {
    dispatch(dataLoading ? actions.START_LOADING : actions.STOP_LOADING);
  }, [dataLoading]);
  return /*#__PURE__*/React.createElement(View, null, /*#__PURE__*/React.createElement(ImageList, {
    fetchInitialImages: storeProps.fetchInitialImages,
    fetchNextImages: storeProps.fetchNextImages,
    contextType: storeProps.contextType,
    images: {
      [storeProps.contextType]: {
        files,
        bookmark,
        hasMore,
        isLoading
      }
    },
    sortBy: {
      sort: 'date_added',
      order: 'desc'
    },
    onImageEmbed: file => {
      setUrl(file.download_url);
      dispatch(_objectSpread(_objectSpread({}, actions.SET_IMAGE_NAME), {}, {
        payload: file.filename
      }));
    }
  }));
};

export default Course;