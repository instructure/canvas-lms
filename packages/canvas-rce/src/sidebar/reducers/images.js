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

import { ADD_IMAGE, REQUEST_IMAGES, RECEIVE_IMAGES } from "../actions/images";

export default function imagesReducer(images = {}, action) {
  switch (action.type) {
    case ADD_IMAGE: {
      const { id, filename, display_name, preview_url, thumbnail_url } = action;

      return {
        ...images,
        records: images.records.concat({
          id,
          filename,
          display_name,
          preview_url,
          thumbnail_url,
          href: preview_url
        })
      };
    }
    case REQUEST_IMAGES:
      return {
        ...images,
        requested: true,
        isLoading: true
      };
    case RECEIVE_IMAGES: {
      const receivedImages = action.imageRecords;
      return {
        ...images,
        records: images.records.concat(receivedImages),
        isLoading: false,
        bookmark: action.bookmark,
        hasMore: !!action.bookmark
      };
    }
    default:
      return images;
  }
}
