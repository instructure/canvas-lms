#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'Backbone'
  'jquery'
  'jst/accounts/admin_tools/AdminTools'
  'jqueryui/tabs'
], (Backbone, $, template) ->
  # This is the main container view that holds 
  # all of the tabs on the admin tools page.
  # It allows you to give it a tab property that should
  # look like this
  # tabs: 
  #   courseRestore  : true
  #   viewMessages   : true
  #   anotherTabName : true
  class AdminToolsView extends Backbone.View
    # Define children that use this backbone template.
    # @api custom backbone
    @child 'restoreContentPaneView', '#restoreContentPane'
    @child 'messageContentPaneView', '#commMessagesPane'
    @child 'loggingContentPaneView', '#loggingPane'
    @optionProperty 'tabs'

    template: template

    els: 
      '#adminToolsTabs' : '$adminToolsTabs'

    # Enable the tabs after items are loaded. 
    # @api custom backbone override
    afterRender: -> 
      @$adminToolsTabs.tabs()

    toJSON: (json) -> 
      json = super
      json.courseRestore = @tabs.courseRestore
      json.viewMessages = @tabs.viewMessages
      json.logging = @tabs.logging
      json

