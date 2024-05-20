// @ts-nocheck
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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import '@canvas/datetime/jquery'
import '@canvas/jquery-keycodes'
import type GridSupport from '../react/default_gradebook/GradebookGrid/GridSupport/index'

type KeyBinding = {
  key: string
  handler?: string
  desc: string
}

type Location = {region: string; cell?: any; row?: any; columnId?: string}

const I18n = useI18nScope('gradebookGradebookKeyboardNav')

type GradebookKeyboardNavOptions = {
  getColumnTypeForColumnId: (columnId: string) => string
  gridSupport: GridSupport
  toggleDefaultSort: (columnId: string) => void
  openSubmissionTray: (studentId: string, assignmentId: string) => void
}

const defaultkeyBindings: KeyBinding[] = [
  {
    //   handler: function
    //   key: the string representation of the key pressed - for use in the help dialog
    //   desc: string describing what the shortcut does - for use in the help dialog
    handler: 'sortOnHeader',
    key: I18n.t('keycodes.sort', 's'),
    desc: I18n.t('keyboard_sort_desc', 'Sort the grid on the current active column'),
  },
  {
    handler: 'toggleColumnHeaderMenu',
    key: I18n.t('keycodes.menu', 'm'),
    desc: I18n.t('keyboard_menu_desc', 'Open menu for the active column'),
  },
  {
    // this one is just for display in the dialog, the menu will take care of itself
    key: I18n.t('keycodes.close_menu', 'esc'),
    desc: I18n.t('keyboard_close_menu', 'Close the currently active menu'),
  },
  {
    handler: 'gotoAssignment',
    key: I18n.t('keycodes.goto_assignment', 'g'),
    desc: I18n.t('keyboard_assignment_desc', "Go to the current assignment's detail page"),
  },
  {
    handler: 'showSubmissionTray',
    key: 'c',
    desc: I18n.t('Open the grade detail tray'),
  },
]

export default class GradebookKeyboardNav {
  gradebookElements: (HTMLElement | null)[]

  gridSupport: GridSupport

  options: GradebookKeyboardNavOptions

  prevActiveElement: Element | null = null

  prevActiveLocation: Location | null = null

  keyBindings: KeyBinding[] = defaultkeyBindings

  constructor(options: GradebookKeyboardNavOptions) {
    this.shouldHandleEvent = this.shouldHandleEvent.bind(this)
    this.haveLocation = this.haveLocation.bind(this)
    this.preprocessKeydown = this.preprocessKeydown.bind(this)
    this.currentRegion = this.currentRegion.bind(this)
    this.currentColumnId = this.currentColumnId.bind(this)
    this.currentColumnType = this.currentColumnType.bind(this)
    this.handleMenuOrDialogClose = this.handleMenuOrDialogClose.bind(this)
    this.addGradebookElement = this.addGradebookElement.bind(this)
    this.removeGradebookElement = this.removeGradebookElement.bind(this)
    this.getHeaderFromActiveCell = this.getHeaderFromActiveCell.bind(this)
    this.sortOnHeader = this.sortOnHeader.bind(this)
    this.toggleColumnHeaderMenu = this.toggleColumnHeaderMenu.bind(this)
    this.gotoAssignment = this.gotoAssignment.bind(this)
    this.showSubmissionTray = this.showSubmissionTray.bind(this)
    this.options = options
    this.gridSupport = this.options.gridSupport
    this.gradebookElements = [document.querySelector('#gradebook_grid')]
    this.sortOnHeader = this.preprocessKeydown(this.sortOnHeader)
    this.toggleColumnHeaderMenu = this.preprocessKeydown(this.toggleColumnHeaderMenu, true)
    this.gotoAssignment = this.preprocessKeydown(this.gotoAssignment)
    this.showSubmissionTray = this.preprocessKeydown(this.showSubmissionTray)
  }

  init() {
    let binding, i, len, ref

    if (!ENV.disable_keyboard_shortcuts) {
      ref = this.keyBindings
      for (i = 0, len = ref.length; i < len; i++) {
        binding = ref[i]
        if (binding.handler != null && binding.key != null && this[binding.handler] != null) {
          $(document.body).keycodes(binding.key, this[binding.handler])
        }
      }
    }
  }

  shouldHandleEvent(e) {
    let element, i, len
    const ref = this.gradebookElements
    for (i = 0, len = ref.length; i < len; i++) {
      element = ref[i]
      if (element.contains(e.target)) {
        return true
      }
    }
    return false
  }

  haveLocation(usePrevActiveLocation: boolean = false) {
    if (this.gridSupport.state.getActiveLocation().cell != null) {
      return true
    }
    return usePrevActiveLocation && this.prevActiveLocation != null
  }

  preprocessKeydown(
    handler: (e: KeyboardEvent) => void,
    usePrevActiveLocation: boolean = false
  ): (e: KeyboardEvent) => void {
    return e => {
      if (!this.shouldHandleEvent(e) || !this.haveLocation(usePrevActiveLocation)) {
        return
      }
      return handler(e)
    }
  }

  currentRegion() {
    return this.gridSupport.state.getActiveLocation().region
  }

  currentColumnId() {
    return this.gridSupport.state.getActiveLocation().columnId
  }

  currentColumnType() {
    return this.options.getColumnTypeForColumnId(this.currentColumnId())
  }

  handleMenuOrDialogClose() {
    if (this.prevActiveLocation == null) {
      return
    }
    if (this.prevActiveLocation.region === 'header') {
      this.gridSupport.state.setActiveLocation(
        this.prevActiveLocation.region,
        this.prevActiveLocation
      )
      if (this.prevActiveElement instanceof HTMLElement) {
        this.prevActiveElement.focus()
      }
    } else {
      this.gridSupport.state.setActiveLocation(
        this.prevActiveLocation.region,
        this.prevActiveLocation
      )
      if (this.currentColumnType() === 'assignment') {
        // return to the cell, but do not engage the editor
        // (exit any existing editor)
        this.gridSupport.helper.commitCurrentEdit()
      }
      this.gridSupport.helper.focus()
    }
    this.prevActiveLocation = null
    return (this.prevActiveElement = null)
  }

  addGradebookElement(element: HTMLElement) {
    if (!this.gradebookElements.includes(element)) {
      return this.gradebookElements.push(element)
    }
  }

  removeGradebookElement(element: HTMLElement) {
    return (this.gradebookElements = this.gradebookElements.filter(function (e) {
      return e !== element
    }))
  }

  getHeaderFromActiveCell() {
    let header
    header = this.gridSupport.state.getActiveColumnHeaderNode()
    if (!header && this.prevActiveLocation?.cell != null) {
      header = this.gridSupport.state.getColumnHeaderNode(this.prevActiveLocation.cell)
    }
    return header
  }

  sortOnHeader(_event: Event) {
    this.options.toggleDefaultSort(this.currentColumnId())
    const activeLocation = this.gridSupport.state.getActiveLocation()
    if (this.currentColumnType() === 'student' && activeLocation.region === 'body') {
      return this.gridSupport.state.setActiveLocation(activeLocation.region, activeLocation)
    }
  }

  toggleColumnHeaderMenu(e: KeyboardEvent) {
    // Prevent sending keystroke to text input of editable cells
    e.preventDefault()
    const activeLocation = this.gridSupport.state.getActiveLocation()
    if (activeLocation.cell != null && !this.prevActiveLocation) {
      this.prevActiveLocation = activeLocation
      this.prevActiveElement = document.activeElement
    }
    this.getHeaderFromActiveCell().querySelector('.Gradebook__ColumnHeaderAction button')?.click()
  }

  gotoAssignment(_event: Event) {
    if (this.currentColumnType() !== 'assignment') {
      return
    }
    const url = this.getHeaderFromActiveCell().querySelector('a .assignment-name').closest('a').href
    window.location = url
  }

  showSubmissionTray(_event: Event) {
    if (!(this.currentRegion() === 'body' && this.currentColumnType() === 'assignment')) {
      return
    }
    const activeLocation = this.gridSupport.state.getActiveLocation()
    const assignmentId = this.gridSupport.grid.getColumns()[activeLocation.cell]?.assignmentId
    const studentId = this.gridSupport.options.rows[activeLocation.row]?.id
    if (studentId != null && assignmentId != null) {
      return this.options.openSubmissionTray(studentId, assignmentId)
    }
  }
}
