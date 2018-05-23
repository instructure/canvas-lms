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
import normalizeProps from "../../src/sidebar/normalizeProps";
import Bridge from "../../src/bridge";

describe("Sidebar normalizeProps", () => {
  it("defaults onLinkClick to Bridge.insertLink", () => {
    let normalized = normalizeProps({});
    assert.equal(normalized.onLinkClick, Bridge.insertLink);
  });

  it("allows overriding onLinkClick", () => {
    let onLinkClick = () => {};
    let normalized = normalizeProps({ onLinkClick });
    assert.equal(normalized.onLinkClick, onLinkClick);
  });

  it("retains other props", () => {
    let normalized = normalizeProps({ canUploadFiles: true });
    assert.ok(normalized.canUploadFiles);
  });
});
