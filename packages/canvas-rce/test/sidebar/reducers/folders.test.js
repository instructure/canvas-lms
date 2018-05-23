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
import proxyquire from "proxyquire";
import sinon from "sinon";
import * as actions from "../../../src/sidebar/actions/files";

const folderStub = {};
const folders = proxyquire("../../../src/sidebar/reducers/folders", {
  "./folder": folderStub
}).default;

function proxiesActionToId(type) {
  return () => {
    const spy = sinon.spy();
    folderStub.default = spy;
    const id = 1;
    const state = { [id]: {} };
    const action = { type, id };
    folders(state, action);
    sinon.assert.calledWith(spy, state[id], action);
    delete folderStub.default;
  };
}

describe("Folders reducer", () => {
  describe("proxies actions for property by action id to folder", () => {
    it("ADD_FOLDER", proxiesActionToId(actions.ADD_FOLDER));
    it("RECEIVE_FILES", proxiesActionToId(actions.RECEIVE_FILES));
    it("RECEIVE_SUBFOLDERS", proxiesActionToId(actions.RECEIVE_SUBFOLDERS));
    it("REQUEST_FILES", proxiesActionToId(actions.REQUEST_FILES));
    it("REQUEST_SUBFOLDERS", proxiesActionToId(actions.REQUEST_SUBFOLDERS));
    it("TOGGLE", proxiesActionToId(actions.TOGGLE));
  });

  it("does not proxy unknown actions", () => {
    assert.throws(proxiesActionToId("unknown.action"));
  });

  it("does not modify the state if for unknown actions", () => {
    const state = {};
    assert(folders(state, { type: "unknown.action" }) === state);
  });
});
