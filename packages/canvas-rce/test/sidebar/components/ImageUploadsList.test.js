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
import ImageUploadsList from "../../../src/sidebar/components/ImageUploadsList";
import sinon from "sinon";
import sd from "skin-deep";

describe("ImageUploadsList", () => {
  let noop = () => {};
  let defaultProps = {
    images: {
      records: [],
      isLoading: false,
      hasMore: false
    },
    fetchImages: noop,
    onImageEmbed: noop
  };

  it("calls for images on mount", () => {
    let imagesSpy = sinon.spy();
    sd.shallowRender(
      <ImageUploadsList {...defaultProps} fetchImages={imagesSpy} />
    );
    assert.ok(imagesSpy.called);
  });
});
