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
import UploadedImage from "../../../src/sidebar/components/UploadedImage";
import sinon from "sinon";
import sd from "skin-deep";

describe("UploadedImage", () => {
  let noop = () => {};
  let fakeEvent = {
    preventDefault() {}
  };
  let image;

  beforeEach(() => {
    image = {
      id: 42,
      filename: "filename.jpeg",
      preview_url: "/big/image",
      thumbnail_url: "/small/image",
      href: "/big/image",
      display_name: "Image Name"
    };
  });

  it("renders an img for the result", () => {
    let imageComp = sd.shallowRender(
      <UploadedImage image={image} onImageEmbed={noop} />
    );
    assert.equal(imageComp.subTree("img").props.src, image.thumbnail_url);
  });

  it("handles drag start on link for firefox", () => {
    let imageComp = sd.shallowRender(
      <UploadedImage image={image} onImageEmbed={noop} />
    );
    assert.equal(
      imageComp.subTree("a").props.onDragStart,
      imageComp.getMountedInstance().onDrag
    );
  });

  it("calls back to provided function on click", () => {
    let clickSpy = sinon.spy();
    let imageComp = sd.shallowRender(
      <UploadedImage image={image} onImageEmbed={clickSpy} />
    );
    let vdom = imageComp.getRenderOutput();
    vdom.props.onClick(fakeEvent);
    assert.ok(clickSpy.called);
  });

  it("uses the right url on drag events", () => {
    let imageData = null;
    let dndEvent = {
      dataTransfer: {
        getData: () => {
          return `<img src="http://canvas.docker/images/thumbnails/show/55/BI8re30hgKqgYgEYMf8AwTr7wvFjqFSdSZvNU96R">`;
        },
        setData: (type, data) => {
          imageData = data;
        }
      }
    };
    let imageComp = sd.shallowRender(
      <UploadedImage image={image} onImageEmbed={noop} />
    );
    let instance = imageComp.getMountedInstance();
    instance.onDrag(dndEvent);
    assert.equal(imageData, `<img alt="Image Name" src="/big/image"/>`);
  });

  it("uses display_name in image alt", () => {
    let imageComp = sd.shallowRender(
      <UploadedImage image={image} onImageEmbed={noop} />
    );
    const img = imageComp.subTree("img");
    assert.equal(img.props.alt, image.display_name);
  });

  it("uses display_name in image title", () => {
    let imageComp = sd.shallowRender(
      <UploadedImage image={image} onImageEmbed={noop} />
    );
    const img = imageComp.subTree("img");
    assert.ok(img.props.title.indexOf(image.display_name) > -1);
  });
});
