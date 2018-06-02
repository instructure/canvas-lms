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
import * as contentRendering from "../../src/rce/contentRendering";

describe("contentRendering", () => {
  describe("renderLink", () => {
    let link;
    beforeEach(() => {
      link = {
        href: "/some/path",
        url: "/other/path",
        title: "Here Be Links",
        contents: "Click On Me"
      };
    });

    it("uses link data to build html", () => {
      const rendered = contentRendering.renderLink(link);
      assert.equal(
        rendered,
        '<a href="/some/path" title="Here Be Links">Click On Me</a>'
      );
    });

    it("can use url if no href", () => {
      link.href = undefined;
      const rendered = contentRendering.renderLink(link);
      assert.equal(
        rendered,
        '<a href="/other/path" title="Here Be Links">Click On Me</a>'
      );
    });

    it("defaults title to 'Link'", () => {
      link.title = undefined;
      const rendered = contentRendering.renderLink(link);
      assert.equal(
        rendered,
        '<a href="/some/path" title="Link">Click On Me</a>'
      );
    });

    it("defaults contents to title", () => {
      link.contents = undefined;
      const rendered = contentRendering.renderLink(link);
      assert.equal(
        rendered,
        '<a href="/some/path" title="Here Be Links">Here Be Links</a>'
      );
    });

    it("defaults contents to 'Link' if no title either", () => {
      link.contents = undefined;
      link.title = undefined;
      const rendered = contentRendering.renderLink(link);
      assert.equal(rendered, '<a href="/some/path" title="Link">Link</a>');
    });
  });

  describe("renderImage", () => {
    let image;
    beforeEach(() => {
      image = {
        href: "/some/path",
        url: "/other/path",
        title: "Here Be Images"
      };
    });

    it("builds image html from image data", () => {
      const rendered = contentRendering.renderImage(image);
      assert.equal(rendered, '<img alt="Here Be Images" src="/some/path"/>');
    });

    it("uses url if no href", () => {
      image.href = undefined;
      const rendered = contentRendering.renderImage(image);
      assert.equal(rendered, '<img alt="Here Be Images" src="/other/path"/>');
    });

    it("defaults alt text to image display_name", () => {
      image.title = undefined;
      image.display_name = "foo";
      const rendered = contentRendering.renderImage(image);
      assert.equal(rendered, '<img alt="foo" src="/some/path"/>');
    });

    it("builds linked image html from linked image data", () => {
      const linkElem = {
        getAttribute: () => {
          return "http://example.com";
        }
      };

      const rendered = contentRendering.renderLinkedImage(linkElem, image);
      assert.equal(
        rendered,
        '<a href="http://example.com" data-mce-href="http://example.com"><img alt="Here Be Images" src="/some/path"/></a>'
      );
    });
    it("renders a linked image if object has link property", () => {
      image.link = "http://someurl";
      const rendered = contentRendering.renderImage(image);
      assert.equal(
        rendered,
        '<a href="http://someurl" target="_blank"><img alt="Here Be Images" src="/some/path"/></a>'
      );
    });
  });
});
