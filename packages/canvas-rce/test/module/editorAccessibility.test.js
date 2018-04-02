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
import accessibleEditor from "../../src/rce/editorAccessibility";

let elementMap, editor, doc, shortcuts, accEd;

describe("accessibleEditor", () => {
  before(() => {
    elementMap = {};
    shortcuts = {};
    editor = {
      editorContainer: {
        id: 42
      },
      addShortcut: (keys, alt, pressHandler) => {
        shortcuts[keys] = pressHandler;
      },
      triggerShortcut: keys => {
        shortcuts[keys].call();
      },
      element: {
        querySelector: selector => {
          if (elementMap[selector] === undefined) {
            elementMap[selector] = {
              attrMap: {},
              removedAttrs: [],
              subQueries: [],
              style: {},
              gotFocused: false,
              focus: () => {
                elementMap[selector].gotFocused = true;
              },
              setAttribute: (attr, value) => {
                elementMap[selector].attrMap[attr] = value;
              },
              removeAttribute: attr => {
                elementMap[selector].removedAttrs.push(attr);
              },
              querySelector: subSelector => {
                elementMap[selector].subQueries.push(subSelector);
                return elementMap[selector];
              }
            };
          }
          return elementMap[selector];
        }
      }
    };

    doc = {
      getElementById: id => {
        if (id === 42) {
          return editor.element;
        }
      }
    };

    accEd = new accessibleEditor(editor, doc);
  });

  it("applies better aria labels", () => {
    accEd.addLabels();
    let bgColorLabel =
      elementMap[accEd.selectors.bgColorBtn].attrMap["aria-label"];
    assert.equal(bgColorLabel, "Background Color, press down to select");
  });

  it("puts a better title on the iframe", () => {
    accEd.addLabels();
    let editorIframeTitle =
      elementMap[accEd.selectors.editorIframe].attrMap["title"];
    assert.equal(editorIframeTitle, "Rich Text Area. Press ALT+F8 for help");
  });

  it("makes the menubar hidden initially", () => {
    accEd.accessibilizeMenubar();
    assert.equal(elementMap[accEd.selectors.menubar].style.display, "none");
  });

  it("shows the menubar on a keyboard shortcut", () => {
    accEd.accessibilizeMenubar();
    editor.triggerShortcut("Alt+F9");
    assert.equal(elementMap[accEd.selectors.menubar].style.display, "");
    assert.equal(elementMap[accEd.selectors.menubar].gotFocused, true);
  });

  it("un-tab-indexes the statusbar", () => {
    accEd.removeStatusbarFromTabindex();
    let tIndex = elementMap[accEd.selectors.statusbar].attrMap["tabindex"];
    assert.equal(tIndex, -1);
  });
});
