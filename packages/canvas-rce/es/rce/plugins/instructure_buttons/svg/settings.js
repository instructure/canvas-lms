import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";

/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import { useState, useEffect, useReducer } from 'react';
import { svgSettings as svgSettingsReducer, defaultState } from "../reducers/svgSettings.js";
const TYPE = 'image/svg+xml';
export const statuses = {
  ERROR: 'error',
  LOADING: 'loading',
  IDLE: 'idle'
};
export function useSvgSettings(editor, editing) {
  const _useReducer = useReducer(svgSettingsReducer, defaultState),
        _useReducer2 = _slicedToArray(_useReducer, 2),
        settings = _useReducer2[0],
        dispatch = _useReducer2[1];

  const _useState = useState(statuses.IDLE),
        _useState2 = _slicedToArray(_useState, 2),
        status = _useState2[0],
        setStatus = _useState2[1];

  useEffect(() => {
    // If we are editing rather than creating, fetch existing settings
    if (editing) (async () => {
      try {
        var _editor$selection$get, _svg$querySelector;

        setStatus(statuses.LOADING); // Parse SVG. If no SVG found, return defaults

        const svg = await svgFromUrl((_editor$selection$get = editor.selection.getNode()) === null || _editor$selection$get === void 0 ? void 0 : _editor$selection$get.src);
        if (!svg) return; // Parse metadata. If no metadata found, return defaults

        const metadata = (_svg$querySelector = svg.querySelector('metadata')) === null || _svg$querySelector === void 0 ? void 0 : _svg$querySelector.innerHTML;
        if (!metadata) return; // settings found, return parsed results

        dispatch(JSON.parse(metadata));
        setStatus(statuses.IDLE);
      } catch (e) {
        setStatus(statuses.ERROR);
      }
    })();
  }, [editor, editing]);
  return [settings, status, dispatch];
}
export async function svgFromUrl(url) {
  const response = await fetch(url);
  const data = await response.text();
  return new DOMParser().parseFromString(data, TYPE);
}