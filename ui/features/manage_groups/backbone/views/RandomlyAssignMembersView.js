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

import $ from 'jquery'
import {some} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import DialogFormView from '@canvas/forms/backbone/views/DialogFormView'
import GroupCategoryCloneView from './GroupCategoryCloneView'
import template from '../../jst/randomlyAssignMembers.handlebars'
import wrapper from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import groupHasSubmissions from '../../groupHasSubmissions'

const I18n = useI18nScope('groups')

export default class RandomlyAssignMembersView extends DialogFormView {
  static initClass() {
    this.prototype.defaults = {
      title: I18n.t('randomly_assigning_members', 'Randomly Assigning Students'),
      width: 450,
      height: 250,
    }

    this.prototype.template = template

    this.prototype.wrapperTemplate = wrapper

    this.prototype.className = 'form-dialog'

    this.prototype.events = {
      'click .dialog_closer': 'close',
      'click .randomly-assign-members-confirm': 'randomlyAssignMembers',
    }

    this.prototype.els = {'input[name=group_by_section]': '$group_by_section'}
  }

  openAgain() {
    super.openAgain(...arguments)
    const groups = this.model.groups().models
    if (some(groups, group => group.usersCount() > 0 || !!group.get('max_membership'))) {
      return this.disableCheckbox(
        this.$group_by_section,
        I18n.t('Cannot restrict by section unless groups are empty and not limited in size')
      )
    } else if (ENV.student_section_count && ENV.student_section_count > groups.length) {
      return this.disableCheckbox(
        this.$group_by_section,
        I18n.t('Must have at least 1 group per section')
      )
    } else {
      return this.enableCheckbox(this.$group_by_section)
    }
  }

  randomlyAssignMembers(e) {
    e.preventDefault()
    e.stopPropagation()
    this.close()

    let groupHasSubmission = false
    for (const group of this.model.groups().models) {
      if (groupHasSubmissions(group)) {
        groupHasSubmission = true
        break
      }
    }
    if (groupHasSubmission) {
      this.cloneCategoryView = new GroupCategoryCloneView({
        model: this.model,
        openedFromCaution: true,
      })
      this.cloneCategoryView.open()
      return this.cloneCategoryView.on('close', () => {
        if (this.cloneCategoryView.cloneSuccess) {
          return window.location.reload()
        } else if (this.cloneCategoryView.changeGroups) {
          return this.model.assignUnassignedMembers()
        }
      })
    } else {
      return this.model.assignUnassignedMembers(this.getFormData().group_by_section === '1')
    }
  }

  disableCheckbox(box, message) {
    // shamelessly copypasted from assignments/EditView
    box
      .prop('checked', false)
      .prop('disabled', true)
      .parent()
      .attr('data-tooltip', 'top')
      .data('tooltip', {disabled: false})
      .attr('title', message)
    return this.checkboxAccessibleAdvisory(box).text(message)
  }

  enableCheckbox(box) {
    if (box.prop('disabled')) {
      box
        .removeProp('disabled')
        .parent()
        .timeoutTooltip()
        .timeoutTooltip('disable')
        .removeAttr('data-tooltip')
        .removeAttr('title')
      return this.checkboxAccessibleAdvisory(box).text('')
    }
  }

  checkboxAccessibleAdvisory(box) {
    const label = box.parent()
    let advisory = label.find('span.screenreader-only.accessible_label')
    if (!advisory.length)
      advisory = $('<span class="screenreader-only accessible_label"></span>').appendTo(label)
    return advisory
  }
}
RandomlyAssignMembersView.initClass()
