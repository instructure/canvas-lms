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

import React from "react";
import { render } from "react-dom";
import { Provider } from "react-redux";
import Sidebar from "./containers/Sidebar";
import configureStore from "./store/configureStore";
import SidebarFacade from "./facade";
import normalizeProps from "./normalizeProps";
import Bridge from "../bridge";

export function renderIntoDiv(target, props = {}, renderCallback) {
  // create a new store for the Provider to use (it will then be passed on to
  // any container components under the Provider)
  let store = configureStore(props);

  // normalize props
  props = normalizeProps(props);

  // render the sidebar, inside a Provider, to the target element

  Bridge.editorRendered.then(() => {
    render(
      <Provider store={store}>
        <Sidebar
          onLinkClick={props.onLinkClick}
          onImageEmbed={props.onImageEmbed}
          canUploadFiles={props.canUploadFiles}
        />
      </Provider>,
      target
    );

    if (renderCallback) {
      // capture the store that's driving the component in a facade that
      // exposes a public API to the caller. then pass it back
      renderCallback(new SidebarFacade(store));
    }
  });
}
