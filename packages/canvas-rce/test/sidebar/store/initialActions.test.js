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

import sinon from "sinon";
import initialActions from "../../../src/sidebar/store/initialActions";
import { init as filesInit } from "../../../src/sidebar/actions/files";
import { get as sessionGet } from "../../../src/sidebar/actions/session";

describe("initialActions", () => {
  let store;

  beforeEach(() => {
    store = {
      dispatch: sinon.spy()
    };
    initialActions(store);
  });

  it("dispatches get session", () => {
    sinon.assert.calledWith(store.dispatch, sessionGet);
  });

  it("dispatches files init", () => {
    sinon.assert.calledWith(store.dispatch, filesInit);
  });
});
