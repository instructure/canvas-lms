#
# Copyright (C) 2016 - present Instructure, Inc.
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

define ['course_settings_helper', 'jquery'], ({tabIdFromElement}, $) ->
  QUnit.module "course_settings_helper",
    test 'non LTI 2 tools', ->
      externalTool = document.createElement('li')
      externalTool.id = 'nav_edit_tab_id_context_external_tool_165'
      tabId = tabIdFromElement(externalTool)
      equal tabId, 'context_external_tool_165'

    test 'LTI 2 tools', ->
      externalTool = document.createElement('li')
      externalTool.id = 'nav_edit_tab_id_lti/message_handler_1'
      tabId = tabIdFromElement(externalTool)
      equal tabId, 'lti/message_handler_1'

    test 'standard navigation items', ->
      externalTool = document.createElement('li')
      externalTool.id = 'nav_edit_tab_id_4'
      tabId = tabIdFromElement(externalTool)
      equal tabId, '4'
