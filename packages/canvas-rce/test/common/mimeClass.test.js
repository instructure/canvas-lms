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

"use strict";

import assert from "assert";
import { fileEmbed, mimeClass } from "../../src/common/mimeClass";

describe("fileEmbed", () => {
  let base_file = { preview_url: "some_url" };

  function getBaseFile(...args) {
    return Object.assign({}, base_file, ...args);
  }

  it("defaults to file", () => {
    assert.equal(fileEmbed({}).type, "file");
  });

  it("uses content-type to identify video and audio", () => {
    let video = fileEmbed(getBaseFile({ "content-type": "video/mp4" }));
    let audio = fileEmbed(getBaseFile({ "content-type": "audio/mpeg" }));
    assert.equal(video.type, "video");
    assert.equal(video.id, "maybe");
    assert.equal(audio.type, "audio");
    assert.equal(audio.id, "maybe");
  });

  it("returns media entry id if provided", () => {
    let video = fileEmbed(
      getBaseFile({
        "content-type": "video/mp4",
        media_entry_id: "42"
      })
    );
    assert.equal(video.id, "42");
  });

  it("returns maybe in place of media entry id if not provided", () => {
    let video = fileEmbed(getBaseFile({ "content-type": "video/mp4" }));
    assert.equal(video.id, "maybe");
  });

  it("picks scribd if there is a preview_url", () => {
    let scribd = fileEmbed(getBaseFile({ preview_url: "some-url" }));
    assert.equal(scribd.type, "scribd");
  });

  it("uses content-type to identify images", () => {
    let image = fileEmbed(
      getBaseFile({
        "content-type": "image/png",
        canvadoc_session_url: "some-url"
      })
    );
    assert.equal(image.type, "image");
  });
});

describe("mimeClass", () => {
  it("returns mime_class attribute if present", () => {
    let mime_class = "wooper";
    assert.equal(mimeClass({ mime_class: mime_class }), mime_class);
  });

  it("returns value corresponding to provided `content-type`", () => {
    assert.equal(mimeClass({ "content-type": "video/mp4" }), "video");
  });

  it("returns value corresponding to provided `type`", () => {
    assert.equal(mimeClass({ type: "video/mp4" }), "video");
  });
});
