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
import configureStore from "../../src/sidebar/store/configureStore";
import * as actions from "../../src/sidebar/actions/ui";
import SidebarFacade from "../../src/sidebar/facade";

describe("Sidebar facade", () => {
  let store, facade;

  beforeEach(() => {
    store = configureStore();
    facade = new SidebarFacade(store);
  });

  it("shows the sidebar on show()", () => {
    store.dispatch(actions.hideSidebar());
    facade.show();
    assert.equal(store.getState().ui.hidden, false);
  });

  it("hides the sidebar on hide()", () => {
    store.dispatch(actions.showSidebar());
    facade.hide();
    assert.equal(store.getState().ui.hidden, true);
  });
});
