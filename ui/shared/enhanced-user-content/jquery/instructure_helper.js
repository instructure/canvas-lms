/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

// create a global object "INST" that we will have be Instructure's namespace.
import $ from 'jquery'
import 'jqueryui/dialog'

window.equella = {
  ready(data) {
    $(document).triggerHandler('equella_ready', data)
  },
  cancel() {
    $(document).triggerHandler('equella_cancel')
  },
}
$(document)
  .bind('equella_ready', function (event, data) {
    $('#equella_dialog').triggerHandler('equella_ready', data)
  })
  .bind('equella_cancel', function () {
    $('#equella_dialog').dialog('close')
  })

window.external_tool_dialog = {
  ready(data) {
    const e = $.Event('selection')
    e.contentItems = data
    $('#resource_selection_dialog:visible').triggerHandler(e)
    $('#homework_selection_dialog:visible').triggerHandler(e)
  },
  cancel() {
    $('#external_tool_button_dialog').dialog('close')
    $('#resource_selection_dialog').dialog('close')
    $('#homework_selection_dialog:visible').dialog('close')
  },
}
