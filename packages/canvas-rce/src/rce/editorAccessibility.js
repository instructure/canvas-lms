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

import formatMessage from "../format-message";
import htmlEscape from "escape-html";

export default function accessibleEditor(editor, docContext) {
  this.selectors = {
    fontBtn: "div[aria-label='Font Sizes']",
    formatBtn: "div.mce-listbox.mce-last:not([aria-label])",
    fgColorBtn: "div[aria-label='Text color']",
    bgColorBtn: "div[aria-label='Background color']",
    recordBtn: "div[aria-label='Record/Upload Media']",
    menubar: ".mce-menubar",
    statusbar: ".mce-statusbar > .mce-container-body",
    editorIframe: ".mce-edit-area iframe"
  };

  this.editorElement = function() {
    return docContext.getElementById(editor.editorContainer.id);
  };

  this.find = function(selectorName) {
    return this.editorElement().querySelector(this.selectors[selectorName]);
  };

  this.applyLabelToSelector = function(selectorName, label) {
    let subElement = this.find(selectorName);
    if (subElement !== null) {
      subElement.setAttribute("aria-label", label);
    }
  };

  this.addLabels = function() {
    this.applyLabelToSelector(
      "fontBtn",
      htmlEscape(formatMessage("Font Size, press down to select"))
    );
    this.applyLabelToSelector(
      "formatBtn",
      htmlEscape(formatMessage("Formatting, press down to select"))
    );
    this.applyLabelToSelector(
      "fgColorBtn",
      htmlEscape(formatMessage("Text Color, press down to select"))
    );
    this.applyLabelToSelector(
      "bgColorBtn",
      htmlEscape(formatMessage("Background Color, press down to select"))
    );
    this.find("editorIframe").setAttribute(
      "title",
      htmlEscape(formatMessage("Rich Text Area. Press ALT+F8 for help"))
    );
  };

  // Hide the menubar until ALT+F9 is pressed.
  this.accessibilizeMenubar = function() {
    let menubar = this.find("menubar");
    if (menubar !== null) {
      let firstMenu = menubar.querySelector(".mce-menubtn");
      menubar.style.display = "none";
      editor.addShortcut("Alt+F9", "", function() {
        menubar.style.display = "";
        firstMenu.focus();
      });
    }
  };

  // keyboard only nav gets permastuck in the statusbar in FF. If you can't
  // click with a mouse, the only way out is to refresh the page.
  this.removeStatusbarFromTabindex = function() {
    let statusbar = this.find("statusbar");
    if (statusbar !== null) {
      statusbar.setAttribute("tabindex", -1);
    }
  };
}
