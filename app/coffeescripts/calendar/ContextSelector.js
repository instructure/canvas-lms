/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import $ from 'jquery'
import _ from 'underscore'
import I18n from 'i18n!context_sector'
import contextSelectorTemplate from 'jst/calendar/contextSelector'
import contextSelectorItemTemplate from 'jst/calendar/contextSelectorItem'
import preventDefault from '../fn/preventDefault'

class ContextSelectorItem {
  constructor(context) {
    this.context = context
    this.state = 'off'
    this.locked = false
  }

  render($list) {
    this.$listItem = $(contextSelectorItemTemplate(this.context))
    this.$listItem.appendTo($list)
    this.$sectionsList = this.$listItem.find('.ag_sections')

    this.$listItem.find('.ag_sections_toggle').click(preventDefault(this.toggleSections))
    this.$contentCheckbox = this.$listItem.find('[name="context_codes[]"]')
    this.$contentCheckbox.change(preventDefault(this.change))
    this.$sectionCheckboxes = this.$listItem.find('[name="sections[]"]')
    this.$sectionCheckboxes.change(this.sectionChange)
  }

  toggleSections = e => {
    this.$sectionsList.toggleClass('hidden')
    const $toggle = this.$listItem.find('.ag_sections_toggle')
    $toggle.toggleClass('ag-sections-expanded')

    if ($toggle.hasClass('ag-sections-expanded')) {
      $toggle
        .find('.screenreader-only')
        .text(I18n.t('Hide course sections for course %{name}', {name: this.context.name}))
    } else {
      $toggle
        .find('.screenreader-only')
        .text(I18n.t('Show course sections for course %{name}', {name: this.context.name}))
    }
  }

  change = () => {
    const newState = (() => {
      switch (this.state) {
        case 'off':
          return 'on'
        case 'on':
          return 'off'
        case 'partial':
          return 'on'
      }
    })()
    this.setState(newState)
  }

  setState = state => {
    if (this.locked) return

    this.state = state
    switch (this.state) {
      case 'on':
      case 'off':
        var checked = this.state === 'on'
        this.$contentCheckbox.prop('checked', checked)
        this.$contentCheckbox.prop('indeterminate', false)
        this.$sectionCheckboxes.prop('checked', checked)
        break
      case 'partial':
        this.$contentCheckbox.prop('checked', true)
        this.$contentCheckbox.prop('indeterminate', true)
        break
    }

    $.publish('/contextSelector/changed')
  }

  sectionChange = () => {
    switch (this.$sectionCheckboxes.filter(':checked').length) {
      case 0:
        return this.setState('off')
      case this.$sectionCheckboxes.length:
        return this.setState('on')
      default:
        return this.setState('partial')
    }
  }

  disableSelf() {
    this.$contentCheckbox.prop('disabled', true)
  }

  disableSections() {
    this.$sectionCheckboxes.prop('disabled', true)
  }

  disableAll() {
    this.disableSelf()
    this.disableSections()
  }

  lock() {
    this.locked = true
    this.disableAll()
  }

  isChecked() {
    return this.state !== 'off'
  }

  sections() {
    const checked = this.$sectionCheckboxes.filter(':checked')
    if (
      checked.length === this.$sectionCheckboxes.length &&
      !this.$contentCheckbox.attr('disabled')
    ) {
      return []
    } else {
      return _.map(checked, cb => cb.value)
    }
  }
}

export default class ContextSelector {
  constructor(selector, apptGroup, contexts, contextsChangedCB, closeCB) {
    this.apptGroup = apptGroup
    this.contexts = contexts
    this.$menu = $(selector).html(contextSelectorTemplate())

    const $contextsList = this.$menu.find('.ag-contexts')

    $.subscribe('/contextSelector/changed', () =>
      contextsChangedCB(this.selectedContexts(), this.selectedSections())
    )

    this.contextSelectorItems = {}
    this.contexts.forEach(c => {
      const item = new ContextSelectorItem(c)
      item.render($contextsList)
      this.contextSelectorItems[item.context.asset_string] = item
    })

    // if groups can sign up, then we only have one context (course) and one sub-context (group)
    // a context without sub-contexts means the whole context is selected
    // a context with sub-contexts means that under that context, only those sub-contexts are selected
    // there can be a mix of contexts with and without sub-contexts
    if (
      this.apptGroup.sub_context_codes.length > 0 &&
      this.apptGroup.sub_context_codes[0].match(/^group_category_/)
    ) {
      for (const c in this.contextSelectorItems) {
        const item = this.contextSelectorItems[c]
        if (c === this.apptGroup.context_codes[0]) {
          item.setState('on')
        }
        item.lock()
      }
    } else {
      let context
      const contextsBySubContext = {}

      this.contexts.forEach(c => {
        c.course_sections.forEach(section => {
          contextsBySubContext[section.asset_string] = c.asset_string
        })
      })

      this.apptGroup.sub_context_codes.forEach(subContextCode => {
        $(`[value='${subContextCode}']`).prop('checked', true)
        context = contextsBySubContext[subContextCode]
        const item = this.contextSelectorItems[context]
        item.sectionChange()
        item.lock()
      })

      this.apptGroup.context_codes.forEach(contextCode => {
        const item = this.contextSelectorItems[contextCode]
        if (item.state === 'off') {
          item.setState('on')
          item.lock()
        }
      })

      for (const c in this.contextSelectorItems) {
        const item = this.contextSelectorItems[c]
        if (!item.locked && !item.context.can_create_appointment_groups.all_sections) {
          item.toggleSections()
          item.disableSelf()
        }
      }
    }

    $('.ag_contexts_done').click(preventDefault(closeCB))

    contextsChangedCB(this.selectedContexts(), this.selectedSections())
  }

  selectedContexts() {
    const contexts = _.chain(this.contextSelectorItems)
      .values()
      .filter(c => c.state !== 'off')
      .map(c => c.context.asset_string)
      .value()

    return contexts
  }

  selectedSections() {
    const sections = _.chain(this.contextSelectorItems)
      .values()
      .map(c => c.sections())
      .reject(ss => ss.length === 0)
      .flatten()
      .value()

    return sections
  }
}
