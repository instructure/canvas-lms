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
import sanitizeEditorOptions from "../../src/rce/sanitizeEditorOptions";

describe("sanitizeEditorOptions", () => {
  describe("changing options that canvas has that we don't support", () => {
    it("changes nothing for inoffensive options", () => {
      let rawOptions = {
        plugins: ["link", "table"],
        toolbar: [
          "bold,italic,underline,indent,superscript,subscript,bullist,numlist",
          "table,link,unlink,instructure_image,ltr,rtl"
        ]
      };
      let cleanOptions = sanitizeEditorOptions(rawOptions);
      assert.equal(cleanOptions.plugins[1], "table");
      assert.equal(
        cleanOptions.toolbar[1],
        "table,link,unlink,instructure_image,ltr,rtl"
      );
    });
  });

  describe("replacing plugin configurations", () => {
    describe("with external_plugins", () => {
      let rawOptions = {};

      beforeEach(() => {
        rawOptions = {
          plugins: "table",
          external_plugins: {
            instructure_links:
              "/javascripts/tinymce_plugins/instructure_links/plugin.js",
            instructure_embed:
              "/javascripts/tinymce_plugins/instructure_embed/plugin.js",
            some_other_plugin: "http://example.com/custom/plugin"
          }
        };
      });

      it("doesnt put instructure_embed through as a plugin because we don't supply that functionality", () => {
        // it's functionality will be replaced by the sidebar component
        let cleanOptions = sanitizeEditorOptions(rawOptions);
        assert.equal(
          cleanOptions.external_plugins["instructure_embed"],
          undefined
        );
      });

      it("leaves other custom external plugins in the config", () => {
        let cleanOptions = sanitizeEditorOptions(rawOptions);
        assert.equal(
          cleanOptions.external_plugins["some_other_plugin"],
          "http://example.com/custom/plugin"
        );
      });
    });
  });
});
