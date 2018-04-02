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
import normalizeLocale from "../../src/rce/normalizeLocale";

describe("normalizeLocale", () => {
  it("returns 'en' for null/undefined", () => {
    assert.equal(normalizeLocale(null), "en");
    assert.equal(normalizeLocale(undefined), "en");
  });

  it("maps old-style canvas locales to new-style", () => {
    assert.equal(normalizeLocale("he-IL"), "he");
  });

  it("reduces unrecognized custom locales to the base locale", () => {
    assert.equal(normalizeLocale("en-GB-x-bogus"), "en-GB");
  });

  it("recognizes known custom locales and doesn't reduce them", () => {
    assert.equal(normalizeLocale("en-GB-x-lbs"), "en-GB-x-lbs");
  });

  it("otherwise just return en", () => {
    assert.equal(normalizeLocale("some-locale"), "en");
  });
});
