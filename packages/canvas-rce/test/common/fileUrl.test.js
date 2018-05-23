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

import { ok, strictEqual } from "assert";
import * as fileUrl from "../../src/common/fileUrl";

describe("Common file url utils", () => {
  describe("downloadToWrap", () => {
    let url;

    beforeEach(() => {
      const downloadUrl = "/some/path?download_frd=1";
      url = fileUrl.downloadToWrap(downloadUrl);
    });

    it("removes download_frd from the query params", () => {
      ok(!/download_frd/.test(url));
    });

    it("adds wrap=1 to the query params", () => {
      ok(/wrap=1/.test(url));
    });

    it("returns null if url is null", () => {
      strictEqual(fileUrl.downloadToWrap(null), null);
    });

    it("returns undefined if url is undefined", () => {
      strictEqual(fileUrl.downloadToWrap(undefined), undefined);
    });

    it("returns empty string for empty strings", () => {
      strictEqual(fileUrl.downloadToWrap(""), "");
    });
  });
});
