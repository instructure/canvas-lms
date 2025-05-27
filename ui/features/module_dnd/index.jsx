/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {addEmptyModuleUI, MODULE_ITEM_LIST} from '@canvas/context-modules/utils/moduleHelpers'
import ready from '@instructure/ready'

ready(() => {
  const zones = document.querySelectorAll('.editable_context_module:not(#context_module_blank)')
  zones.forEach(zone => {
    const content = zone.querySelector('.content')
    if (!content) return
    const itemslist = content?.querySelector('.context_module_items')
    if (!itemslist) {
      content.insertAdjacentHTML('afterbegin', MODULE_ITEM_LIST)
    }
    const moduleDnd = zone.querySelector('.module_dnd')
    if (moduleDnd) {
      addEmptyModuleUI(zone)
    }
  })
})
