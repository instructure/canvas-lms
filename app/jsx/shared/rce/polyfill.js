/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import _ from 'underscore'

  const editorExtensions = {
    call(methodName, ...args) {
      // since exists? has a ? and cant be a regular function (yet we want
      // the same signature as editorbox) just return true rather than
      // calling as a fn on the editor
      if (methodName === "exists?") { return true }
      return this[methodName](...args)
    },

    focus() {
      // TODO implement this once in service
    }
  }

  const sidebarExtensions = {
    show() {
      // TODO generalize/adapt this once in service
      $("#editor_tabs").show()
    },

    hide() {
      // TODO generalize/adapt this once in service
      $("#editor_tabs").hide()
    }
  }

  const polyfill = {
    wrapEditor(editor) {
      let extensions = _.extend({}, editorExtensions, editor)
      return _.extend(editor, extensions)
    },

    wrapSidebar(sidebar) {
      let extensions = _.extend({}, sidebarExtensions, sidebar)
      return _.extend(sidebar, extensions)
    }
  }

export default polyfill
