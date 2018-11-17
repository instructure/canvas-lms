//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Backbone from 'Backbone'
import template from 'jst/accounts/admin_tools/AdminTools'
import 'jqueryui/tabs'
// This is the main container view that holds
// all of the tabs on the admin tools page.
// It allows you to give it a tab property that should
// look like this
// tabs:
//   courseRestore  : true
//   viewMessages   : true
//   anotherTabName : true

export default class AdminToolsView extends Backbone.View {
  static initClass() {
    // Define children that use this backbone template.
    // @api custom backbone
    this.child('restoreContentPaneView', '#restoreContentPane')
    this.child('messageContentPaneView', '#commMessagesPane')
    this.child('loggingContentPaneView', '#loggingPane')
    this.optionProperty('tabs')

    this.prototype.template = template

    this.prototype.els = {'#adminToolsTabs': '$adminToolsTabs'}
  }

  // Enable the tabs after items are loaded.
  // @api custom backbone override
  afterRender() {
    return this.$adminToolsTabs.tabs()
  }

  toJSON(json) {
    json = super.toJSON(...arguments)
    json.courseRestore = this.tabs.courseRestore
    json.viewMessages = this.tabs.viewMessages
    json.logging = this.tabs.logging
    return json
  }
}
AdminToolsView.initClass()
