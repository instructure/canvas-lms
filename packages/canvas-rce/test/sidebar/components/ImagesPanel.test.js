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

import assert from "assert";
import React from "react";
import ImagesPanel from "../../../src/sidebar/components/ImagesPanel";
import sd from "skin-deep";

describe("ImagesPanel", () => {
  let noop = () => {};
  let defaultProps = {
    withUploadForm: true,
    upload: { folders: [], uploading: false, formExpanded: false },
    images: { records: [], isLoading: false, hasMore: false },
    fetchImages: noop,
    fetchFolders: noop,
    startUpload: noop,
    flickr: { searchResults: [], searching: false, formExpanded: false },
    flickrSearch: noop,
    toggleFlickrForm: noop,
    toggleUploadForm: noop,
    onImageEmbed: noop
  };

  describe("rendering", () => {
    it("includes upload form if withUploadForm", () => {
      let panel = sd.shallowRender(
        <ImagesPanel {...defaultProps} withUploadForm={true} />
      );
      let instance = panel.getMountedInstance();
      assert(instance.renderUploadForm() != null);
    });

    it("excludes upload form if withUploadForm is false", () => {
      let panel = sd.shallowRender(
        <ImagesPanel {...defaultProps} withUploadForm={false} />
      );
      let instance = panel.getMountedInstance();
      assert(instance.renderUploadForm() == null);
    });
  });
});
