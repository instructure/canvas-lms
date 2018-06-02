/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

/* this class is a solution to CNVS-37129. this solution will create DOM
 * MutationObserver to all tables created in tinymce. it does this by hooking
 * the tinymce editor object's "AddVisual" method. this method gets called
 * often and is called internally by tinymce in a way that hooking it will
 * allow us to catch all cases where tables are created.
 * the hook simply looks at all tables currently created in the tinymce
 * editor and adds a MutationObserver on that table for when any subtree
 * changes are made. when this occurs, that code will figure out if there are
 * any '<td><iframe>' conditions in the table. if there are, the code inserts
 * a div to make it '<td><div><iframe>'
 * ultimately, we need to get this fixed in tinymce, but this hack will resolve
 * the customer issue now in the short term. 
 */
export default class IframesTableFix {
  getHackedTables(editor) {
    return editor.hackedTables || [];
  }

  setHackedTables(editor, hackedTables) {
    editor.hackedTables = hackedTables;
  }

  cleanHackedTables(editor) {
    const hackedTables = this.getHackedTables(editor);
    const tables = editor.dom.select("table");
    this.setHackedTables(
      editor,
      hackedTables.filter(t => tables.indexOf(t) > -1)
    );
  }

  isTableHacked(editor, table) {
    this.cleanHackedTables(editor);
    return this.getHackedTables(editor).indexOf(table) > -1;
  }

  addHackedTable(editor, table) {
    this.getHackedTables(editor).push(table);
  }

  fixIframes(editor) {
    const tds =
      editor && editor.dom && editor.dom.select ? editor.dom.select("td") : [];
    const brokenTds = [];
    tds.forEach(td => {
      const spanChildren = [].slice
        .call(td.children)
        .filter(
          n =>
            n.tagName === "SPAN" &&
            n.getAttribute("data-mce-object") === "iframe"
        );
      if (spanChildren.length > 0) {
        if (brokenTds.indexOf(td) === -1) {
          td.innerHTML = `<div>${td.innerHTML}</div>`;
          brokenTds.push(td);
        }
      }
    });
  }

  addMutationObserverToTables(editor, MutationObserver) {
    const tables =
      editor && editor.dom && editor.dom.select
        ? editor.dom.select("table").filter(t => !this.isTableHacked(editor, t))
        : [];
    if (tables.length > 0) {
      const mo = new MutationObserver(() => {
        this.fixIframes(editor);
      });
      for (let i = tables.length - 1; i >= 0; i--) {
        const table = tables[i];
        mo.observe(table, { childList: true, subtree: true });
        this.addHackedTable(editor, table);
      }
    }
    this.fixIframes(editor);
  }

  hookAddVisual(editor, MutationObserver) {
    const addVisual = editor.addVisual.bind(editor);
    const newAddVisual = elm => {
      this.addMutationObserverToTables(editor, MutationObserver);
      addVisual(elm);
    };
    editor.addVisual = newAddVisual.bind(editor);
    this.addMutationObserverToTables(editor, MutationObserver);
  }
}
