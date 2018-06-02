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

export const ADD_IMAGE = "action.images.add_image";
export const REQUEST_IMAGES = "action.images.request_images";
export const RECEIVE_IMAGES = "action.images.receive_images";
export const FAIL_IMAGES_LOAD = "action.images.fail_images_load";

export function createAddImage({
  id,
  filename,
  display_name,
  url,
  thumbnail_url
}) {
  return {
    type: ADD_IMAGE,
    id,
    filename,
    display_name,
    preview_url: url,
    thumbnail_url
  };
}

export function requestImages(bookmark) {
  return { type: REQUEST_IMAGES, bookmark: bookmark };
}

export function receiveImages(response) {
  return {
    type: RECEIVE_IMAGES,
    imageRecords: response.images,
    bookmark: response.bookmark
  };
}

export function failImagesLoad(error) {
  return { type: FAIL_IMAGES_LOAD, error };
}

// gets images to embed for context
export function fetchImages(fetchEvent) {
  return (dispatch, getState) => {
    var calledFromRender = fetchEvent.calledFromRender;
    const { source, images, host, contextId, contextType } = getState();
    if (!images.requested) {
      dispatch(requestImages(images.bookmark));
      return source
        .fetchImages({ host, contextId, contextType })
        .then(imageBody => {
          dispatch(receiveImages(imageBody));
        })
        .catch(error => {
          dispatch(failImagesLoad(error));
        });
    } else if (!calledFromRender && images.hasMore) {
      dispatch(requestImages(images.bookmark));
      return source
        .fetchImages({ bookmark: images.bookmark })
        .then(imageBody => {
          dispatch(receiveImages(imageBody));
        })
        .catch(error => {
          dispatch(failImagesLoad(error));
        });
    } else {
      return new Promise(resolve => {
        resolve();
      });
    }
  };
}
