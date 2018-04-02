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

export default function(ed, document) {
  var selectedNode = ed.selection.getNode();
  // Internal image object like a flash placeholder
  if (ed.dom.getAttrib(selectedNode, "class", "").indexOf("mceItem") != -1)
    return;

  // this is deprecated and we should be using new CustomEvent(), but it isn't
  // supported by IE11
  var ev = document.createEvent("CustomEvent");
  ev.initCustomEvent("tinyRCE/initImagePicker", true, true, {
    ed,
    selectedNode
  });
  document.dispatchEvent(ev);
}
