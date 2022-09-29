/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('AssignmentKeyBindingsMixin')

export default {
  keyBindings: [
    {
      keyCode: 74,
      handler: 'goToNextItem',
      get key() {
        return I18n.t('keycodes.next', 'j')
      },
      get desc() {
        return I18n.t('keyboard_next_item', 'Focus on the next assignment or group')
      },
    },
    {
      keyCode: 75,
      handler: 'goToPrevItem',
      get key() {
        return I18n.t('keycodes.previous', 'k')
      },
      get desc() {
        return I18n.t('keyboard_prev_item', 'Focus on the previous assignment or group')
      },
    },
    {
      keyCode: 69,
      handler: 'editItem',
      get key() {
        return I18n.t('keycodes.edit_item', 'e')
      },
      get desc() {
        return I18n.t('keyboard_edit_item', 'Edit the current assignment or group')
      },
    },
    {
      keyCode: 68,
      handler: 'deleteItem',
      get key() {
        return I18n.t('keycodes.del_item', 'd')
      },
      get desc() {
        return I18n.t('keyboard_del_item', 'Delete the current assignment or group')
      },
    },
    {
      keyCode: 65,
      handler: 'addItem',
      get key() {
        return I18n.t('keycodes.add_item', 'a')
      },
      get desc() {
        return I18n.t('keyboard_add_item', 'Add an assignment to selected group')
      },
    },
    {
      keyCode: 70,
      handler: 'showAssignment',
      get key() {
        return I18n.t('keycodes.show_assign', 'f')
      },
      get desc() {
        return I18n.t('keyboard_show_assign', 'Show full preview of the selected assignment')
      },
    },
    {
      keyCode: null,
      get key() {
        return I18n.t('keycodes.close_menu', 'esc')
      },
      get desc() {
        return I18n.t('keyboard_close_menu', 'Close the active dialog')
      },
    },
  ],

  handleKeys(e) {
    if (['shiftKey', 'altKey', 'ctrlKey'].some(mod => e[mod])) return
    const b = this.keyBindings.find(binding => binding.keyCode === e.keyCode)
    if (b?.handler) {
      if (typeof this[b.handler] === 'function') {
        this[b.handler](e)
      }
      return e.stopPropagation()
    }
  },
}
