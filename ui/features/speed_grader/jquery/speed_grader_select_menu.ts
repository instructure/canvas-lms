/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import type JQuery from 'jquery'
import $ from 'jquery'
import 'jquery-selectmenu'
import SpeedgraderHelpers from './speed_grader_helpers'
import htmlEscape from '@instructure/html-escape'

export type SelectOptionDefinition = {
  anonymizableId?: 'anonymous_id' | 'id'
  anonymous_id?: string
  className?: {
    formatted?: string
    raw: string
  }
  data?: {
    'section-id': string
  }
  id?: string
  name: string
  options?: SelectOptionDefinition[]
}

function optionsToHtml(optionDefinitions: SelectOptionDefinition[]) {
  return optionDefinitions
    .map(definition => {
      let html = ''

      if (definition.options) {
        const childrenHtml = optionsToHtml(definition.options)
        html = `
        <optgroup label="${htmlEscape(definition.name)}">
          ${childrenHtml}
        </optgroup>
      `
      } else {
        if (definition.anonymizableId == null) {
          throw Error('`anonymizableId` required in optionDefinition objects')
        }
        const labels = [definition.name]

        if (definition.className && definition.className.formatted) {
          labels.push(definition.className.formatted)
        }

        html = `
        <option
          value="${htmlEscape(definition[definition.anonymizableId])}"
          class="${htmlEscape(definition.className?.raw)} ui-selectmenu-hasIcon"
        >
          ${htmlEscape(labels.join(' – '))}
        </option>
      `
      }

      return html
    })
    .join('')
}

export function buildStudentIdMap(optionDefinitions: SelectOptionDefinition[]) {
  const studentMap: Record<string, number> = {}
  let adjust = 0
  optionDefinitions.forEach((optionDefinition, index) => {
    if (optionDefinition.options) {
      // There should only ever be one, but just in case
      adjust += 1
    } else if (optionDefinition.anonymizableId) {
      const id = optionDefinition[optionDefinition.anonymizableId]
      if (id) {
        studentMap[id] = index - adjust
      }
    }
  })
  return studentMap
}

export function focusHandlerAccessibilityFixes(container: JQuery) {
  const focus = function () {
    $(container).find('span.ui-selectmenu-icon').css('background-position', '-17px 0')
  }
  const focusOut = function () {
    $(container).find('span.ui-selectmenu-icon').css('background-position', '0 0')
  }

  // In case someone mouseovers, let's visual color to match a
  // keyboard focus
  $(container).on('focus', 'a.ui-selectmenu', focus)
  $(container).on('focusout', 'a.ui-selectmenu', focusOut)

  // Remove the focus binding from jquery that steals away from
  // the select and add our own that doesn't, but still does some
  // visual decoration.
  const $select_menu = $(container).find('select#students_selectmenu')
  $select_menu.unbind('focus')
  $select_menu.bind('focus', focus)
  $select_menu.bind('focusout', focusOut)
}

// xsslint safeString.function getIcon
function getIconHtml(helper_text: string) {
  let icon = "<span class='ui-selectmenu-item-icon speedgrader-selectmenu-icon'>"
  if (helper_text === 'graded') {
    icon += "<i class='icon-check'></i>"
  } else if (['not_graded', 'resubmitted'].indexOf(helper_text) !== -1) {
    // This is the UTF-8 code for "Black Circle"
    icon += '&#9679;'
  }
  return icon.concat('</span>')
}

function buildHtml(options: SelectOptionDefinition[]) {
  const optionHtml = optionsToHtml(options)

  return `<select id='students_selectmenu'>${optionHtml}</select>`
}

export function selectMenuAccessibilityFixes(container: JQuery) {
  const $select_menu = $(container).find('select#students_selectmenu')

  $(container)
    .find('a.ui-selectmenu')
    .removeAttr('role')
    .removeAttr('aria-haspopup')
    .removeAttr('aria-owns')
    .removeAttr('aria-disabled')
    .attr('aria-hidden', 'true')
    .attr('tabindex', -1)
    .css('margin', 0)

  $select_menu
    .addClass('screenreader-only')
    .removeAttr('style')
    .removeAttr('aria-disabled')
    .attr('tabindex', 0)
    .show()
}

export function replaceDropdownIcon(container: JQuery) {
  const $span = $(container).find('span.ui-selectmenu-icon')
  $span.removeClass('ui-icon')
  $("<i class='icon-mini-arrow-down'></i>").appendTo($span)
}

export default class SpeedgraderSelectMenu {
  options_array: SelectOptionDefinition[]

  option_index: number = 0

  opt_group_found: boolean = false

  option_sub_index: number = 0

  option_tag_array: JQuery = $()

  student_id_map: Record<string, number> = {}

  $el: JQuery = $()

  constructor(optionsArray: SelectOptionDefinition[]) {
    this.options_array = optionsArray
  }

  keyEventAccessibilityFixes(container: JQuery) {
    const $select_menu = $(container).find('select#students_selectmenu')
    // The fake gui menu won't update in firefox until the select is
    // chosen, to work around this, we force an update on any key
    // press.
    $select_menu.bind('keyup', e => {
      const code = e.keyCode || e.which
      if (code === 37 || code === 38 || code === 39 || code === 40) {
        // left, up, right, down arrow
        this.$el.change()
      }
    })
  }

  accessibilityFixes(container: JQuery) {
    focusHandlerAccessibilityFixes(container)
    selectMenuAccessibilityFixes(container)
    this.keyEventAccessibilityFixes(container)
  }

  appendTo(selector: string, onChange: (event: any) => void) {
    this.student_id_map = buildStudentIdMap(this.options_array)

    $(
      '<label class="screenreader-only" for="students_selectmenu">Select a student</label>'
    ).appendTo(selector)

    this.$el = $(buildHtml(this.options_array))
      .appendTo(selector)
      .selectmenu({
        // @ts-expect-error
        style: 'dropdown',
        format: () => this.formatSelectText(),
        open: () => this.our_open(),
      })

    $('ul#students_selectmenu-menu li.ui-selectmenu-group').remove()
    this.option_tag_array = $('#students_selectmenu > option')
    this.$el.change(onChange)
    this.accessibilityFixes(this.$el.parent())
    replaceDropdownIcon(this.$el.parent())
  }

  // The following 4 functions just delegate to the contained component.

  // @ts-expect-error
  val(...args) {
    // @ts-expect-error
    return String(this.$el.val(...args))
  }

  data(str: string) {
    return this.$el.data(str)
  }

  // @ts-expect-error
  selectmenu(...args) {
    // @ts-expect-error
    return this.$el.selectmenu(...args)
  }

  // @ts-expect-error
  change(...args) {
    return this.$el.change(...args)
  }

  our_open() {
    this.accessibilityFixes(this.$el.parent())
  }

  formatSelectText() {
    let option = this.options_array[this.option_index]
    let optgroup
    let html = ''

    if (option.options) {
      optgroup = option

      if (!this.opt_group_found && optgroup.options) {
        // We encountered this optgroup but haven't start traversing it yet
        this.opt_group_found = true
        this.option_sub_index = 0
        option = optgroup.options?.[this.option_sub_index]
      }

      if (
        this.opt_group_found &&
        optgroup.options &&
        this.option_sub_index < optgroup.options.length
      ) {
        // We're still traversing this optgroup, carry on
        option = optgroup.options[this.option_sub_index]

        this.option_sub_index++
      } else {
        this.opt_group_found = false
        this.option_sub_index = 0
        this.option_index++

        option = this.options_array[this.option_index]
        this.option_index++
      }
    } else {
      this.opt_group_found = false
      this.option_sub_index = 0
      this.option_index++
    }

    if (option.options) {
      html = htmlEscape(option.name)
    }

    return `
        ${html}
        ${getIconHtml(htmlEscape(option.className?.raw || ''))}
        <span class="ui-selectmenu-item-header">
          ${htmlEscape(option.name)}
        </span>
    `
  }

  updateSelectMenuStatus({
    student,
    isCurrentStudent,
    newStudentInfo,
    anonymizableId,
  }: {
    student: any
    isCurrentStudent: boolean
    newStudentInfo: string
    anonymizableId: 'anonymous_id' | 'id'
  }) {
    if (!student) return
    const optionIndex = this.student_id_map[student[anonymizableId]]
    let $query = this.$el.data('ui-selectmenu').list.find(`li:eq(${optionIndex})`)
    const className = SpeedgraderHelpers.classNameBasedOnStudent(student)
    const submissionStates = 'not_graded not_submitted graded resubmitted'

    if (isCurrentStudent) {
      $query = $query.add(this.$el.data('ui-selectmenu').newelement)
    }
    $query.removeClass(submissionStates).addClass(className.raw)

    const $status = $('.ui-selectmenu-status')
    const $statusIcon = $status.find('.speedgrader-selectmenu-icon')
    const $queryIcon = $query.find('.speedgrader-selectmenu-icon')

    const option = $(this.option_tag_array[optionIndex])
    option.text(newStudentInfo).removeClass(submissionStates).addClass(className.raw)

    if (className.raw === 'graded' || className.raw === 'not_gradeable') {
      $queryIcon.text('').append("<i class='icon-check'></i>")
      if (isCurrentStudent) {
        $status.addClass('graded')
        $statusIcon.text('').append("<i class='icon-check'></i>")
      }
    } else if (className.raw === 'not_graded') {
      $queryIcon.text('').append('&#9679;')
      if (isCurrentStudent) {
        $status.removeClass('graded')
        $statusIcon.text('').append('&#9679;')
      }
    } else {
      $queryIcon.text('')
      if (isCurrentStudent) {
        $status.removeClass('graded')
        $statusIcon.text('')
      }
    }

    // this is because selectmenu.js uses .data('optionClasses' on the
    // li to keep track of what class to put on the selected option (
    // aka: $selectmenu.data('ui-selectmenu').newelement ) when this li
    // is selected.  so even though we set the class of the li and the
    // $selectmenu.data('ui-selectmenu').newelement when it is graded, we
    // need to also set the data() so that if you skip back to this
    // student it doesnt show the old checkbox status.
    $.each(submissionStates.split(' '), function () {
      $query.data('optionClasses', $query.data('optionClasses').replace(this, ''))
    })
  }
}
