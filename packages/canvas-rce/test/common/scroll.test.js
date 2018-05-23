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
import sinon from "sinon";
import scroll from "../../src/common/scroll";
import scrollIntoView from "scroll-into-view";

describe("scroll", () => {
  beforeEach(() => {
    sinon.stub(scrollIntoView, "scrollIntoView");
  });

  afterEach(() => {
    scrollIntoView.scrollIntoView.restore();
  });

  describe("element in view method", () => {
    it("calls scrollIntoView()", done => {
      scroll.scrollIntoViewWDelay(null, {});
      setTimeout(() => {
        assert.ok(scrollIntoView.scrollIntoView.calledWith(null, {}));
        done();
      }, scroll.INTERIM_DELAY * 1.1);
    });
  });
});
