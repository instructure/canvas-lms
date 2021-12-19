import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";
import _objectSpread from "@babel/runtime/helpers/esm/objectSpread2";
import _objectWithoutProperties from "@babel/runtime/helpers/esm/objectWithoutProperties";
const _excluded = ["children"],
      _excluded2 = ["children"];

/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import React, { createContext, useContext, useState } from 'react';
import { connect, Provider as ReduxProvider } from 'react-redux';
import bridge from "../../../bridge/index.js";
import sidebarHandlers from "../../../sidebar/containers/sidebarHandlers.js";
import { propsFromState } from "../../../sidebar/containers/Sidebar.js";
import configureStore from "../../../sidebar/store/configureStore.js";

function Consumer(_ref) {
  let children = _ref.children,
      props = _objectWithoutProperties(_ref, _excluded);

  return children(_objectSpread({
    onLinkClick: bridge.insertLink,
    onImageEmbed: bridge.embedImage,
    onMediaEmbed: bridge.embedMedia,
    onFileSelect: bridge.insertFileLink
  }, props));
}

export const StoreConsumer = connect(propsFromState, sidebarHandlers)(Consumer);
const StoreContext = /*#__PURE__*/createContext();
export function StoreProvider(_ref2) {
  let children = _ref2.children,
      storeProps = _objectWithoutProperties(_ref2, _excluded2);

  const _useState = useState(() => configureStore(storeProps)),
        _useState2 = _slicedToArray(_useState, 1),
        store = _useState2[0];

  return /*#__PURE__*/React.createElement(ReduxProvider, {
    store: store
  }, /*#__PURE__*/React.createElement(StoreConsumer, null, props => /*#__PURE__*/React.createElement(StoreContext.Provider, {
    value: props
  }, children(props))));
}
export function useStoreProps() {
  const storeProps = useContext(StoreContext);
  if (!storeProps) throw new Error('useStoreProps should be used within a StoreProvider');
  return storeProps;
}