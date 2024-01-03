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
import {map, find} from 'lodash'
import {View} from '@canvas/backbone'
import template from '../../jst/section_to_show_menu.handlebars'
import 'jquery-kyle-menu'
import 'jquery-tinypubsub'

const I18n = useI18nScope('gradebookSectionMenuView')

const boundMethodCheck = function (instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new Error('Bound instance method accessed before binding')
  }
}

class SectionMenuView extends View {
  determineDefaultSection() {
    let defaultSection
    if (this.showSections || !this.course) {
      defaultSection = I18n.t('all_sections', 'All Sections')
    } else {
      defaultSection = this.course.name
    }
    return defaultSection
  }

  constructor(options) {
    super(options)
    this.onSectionChange = this.onSectionChange.bind(this)
    this.defaultSection = this.determineDefaultSection()
    if (this.sections.length > 1) {
      this.sections.unshift({
        name: this.defaultSection,
        checked: !options.currentSection,
      })
    }
    this.updateSections()
  }

  render() {
    this.detachEvents()
    super.render()
    this.$('button').prop('disabled', this.disabled).kyleMenu()
    return this.attachEvents()
  }

  detachEvents() {
    $.unsubscribe('currentSection/change', this.onSectionChange)
    return this.$('.section-select-menu').off('menuselect')
  }

  attachEvents() {
    $.subscribe('currentSection/change', this.onSectionChange)
    this.$('.section-select-menu').on('click', function (e) {
      return e.preventDefault()
    })
    return this.$('.section-select-menu').on('menuselect', (event, ui) => {
      const section =
        this.$('[aria-checked=true] input[name=section_to_show_radio]').val() || undefined
      $.publish('currentSection/change', [section, this.cid])
      return this.trigger('menuselect', event, ui, this.currentSection)
    })
  }

  onSectionChange(section, _author) {
    boundMethodCheck(this, SectionMenuView)
    this.currentSection = section
    this.updateSections()
    return this.render()
  }

  updateSections() {
    return map(this.sections, section => {
      section.checked = section.id === this.currentSection
      return section
    })
  }

  showSections() {
    return this.showSections
  }

  toJSON() {
    let ref
    return {
      sections: this.sections,
      showSections: this.showSections,
      currentSection:
        ((ref = find(this.sections, {
          id: this.currentSection,
        })) != null
          ? ref.name
          : undefined) || this.defaultSection,
    }
  }
}

SectionMenuView.optionProperty('sections')

SectionMenuView.optionProperty('course')

SectionMenuView.optionProperty('showSections')

SectionMenuView.optionProperty('disabled')

SectionMenuView.optionProperty('currentSection')

SectionMenuView.prototype.template = template

export default SectionMenuView
