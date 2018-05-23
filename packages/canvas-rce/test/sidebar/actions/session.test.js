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
import { spiedStore } from "./utils";
import * as session from "../../../src/sidebar/actions/session";

describe("Session actions", () => {
  describe("get", () => {
    let store, state, data;

    const source = {
      getSession: () => Promise.resolve(data)
    };

    beforeEach(() => {
      data = { canUploadFiles: true };
      state = { source };
      store = spiedStore(state);
    });

    it("dispatches RECEIVE_SESSION with data from source", () => {
      return store.dispatch(session.get).then(() => {
        sinon.assert.calledWithMatch(store.spy, {
          type: session.RECEIVE_SESSION,
          data
        });
      });
    });
  });
});
