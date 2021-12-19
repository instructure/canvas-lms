import _objectSpread from "@babel/runtime/helpers/esm/objectSpread2";

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
import { ADD_IMAGE, REQUEST_INITIAL_IMAGES, REQUEST_IMAGES, RECEIVE_IMAGES, FAIL_IMAGES_LOAD } from "../actions/images.js";
import { CHANGE_CONTEXT, CHANGE_SEARCH_STRING } from "../actions/filter.js";
export default function imagesReducer(prevState = {}, action) {
  const ctxt = action.payload && action.payload.contextType;

  const state = _objectSpread({}, prevState);

  if (ctxt && !state[ctxt]) {
    state[ctxt] = {
      files: [],
      bookmark: null,
      isLoading: false,
      hasMore: true
    };
  }

  switch (action.type) {
    case ADD_IMAGE:
      {
        const _action$payload$newIm = action.payload.newImage,
              id = _action$payload$newIm.id,
              filename = _action$payload$newIm.filename,
              display_name = _action$payload$newIm.display_name,
              href = _action$payload$newIm.href,
              preview_url = _action$payload$newIm.preview_url,
              thumbnail_url = _action$payload$newIm.thumbnail_url;
        state[ctxt] = {
          files: state[ctxt].files.concat({
            id,
            filename,
            display_name,
            preview_url,
            thumbnail_url,
            href: preview_url || href
          })
        };
        return state;
      }

    case REQUEST_INITIAL_IMAGES:
      state[ctxt] = {
        files: [],
        bookmark: null,
        isLoading: true,
        hasMore: true
      };
      return state;

    case REQUEST_IMAGES:
      state[ctxt].isLoading = true;
      return state;

    case RECEIVE_IMAGES:
      // If a request resolved with files but the searchString has since
      // changed, then the files should not be concatenated because this
      // request will have been redundant at best and wrong at worst.
      if (action.payload.searchString === state.searchString) {
        state[ctxt] = {
          files: state[ctxt].files.concat(action.payload.files),
          isLoading: false,
          bookmark: action.payload.bookmark,
          hasMore: !!action.payload.bookmark
        };
      }

      return state;

    case FAIL_IMAGES_LOAD:
      state[ctxt] = {
        isLoading: false,
        error: action.payload.error
      };

      if (action.payload.files && action.payload.files.length === 0) {
        state[ctxt].bookmark = null;
      }

      return state;

    case CHANGE_CONTEXT:
      {
        return state;
      }

    case CHANGE_SEARCH_STRING:
      {
        state.searchString = action.payload;
        return state;
      }

    default:
      return prevState;
  }
}