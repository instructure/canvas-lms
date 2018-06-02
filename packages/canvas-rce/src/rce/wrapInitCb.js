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

import IframesTableFix from "./IframesTableFix";

// mirror attributes onto tinymce editor (if this can be done
// via tiny api, it is preferable, but I dont see a way)
export default function wrapInitCb(
  mirroredAttrs,
  editorOptions,
  MutationObserver
) {
  MutationObserver =
    MutationObserver === undefined ? window.MutationObserver : MutationObserver;
  let oldInitInstCb = editorOptions.init_instance_callback;
  editorOptions.init_instance_callback = function(ed) {
    let attrs = mirroredAttrs || {};
    let el = ed.getElement();
    if (el) {
      Object.keys(attrs).forEach(function(attr) {
        el.setAttribute(attr, attrs[attr]);
      });

      // add data to textarea so it can be found by canvas
      // (which unfortunately relies on this a lot)
      el.dataset.rich_text = true;
    }

    // hookAddVisual for hacky <td><iframe> fix
    const ifr = new IframesTableFix();
    ifr.hookAddVisual(ed, MutationObserver);

    // wrap old cb (dont overwrite)
    oldInitInstCb && oldInitInstCb(ed);
  };
  return editorOptions;
}
