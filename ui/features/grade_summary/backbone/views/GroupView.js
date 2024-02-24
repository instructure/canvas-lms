//
// Copyright (C) 2014 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {View} from '@canvas/backbone'
import CollectionView from '@canvas/backbone-collection-view'
import OutcomeView from './OutcomeView'
import template from '../../jst/group.handlebars'

const I18n = useI18nScope('grade_summaryGroupView')

class GroupView extends View {
  render() {
    super.render(...arguments)
    const outcomesView = new CollectionView({
      el: this.$outcomes,
      collection: this.model.get('outcomes'),
      itemView: OutcomeView,
    })
    return outcomesView.render()
  }

  expand() {
    this.$el.toggleClass('expanded')
    if (this.$el.hasClass('expanded')) {
      this.$el.children('div.group-description').attr('aria-expanded', 'true')
    } else {
      this.$el.children('div.group-description').attr('aria-expanded', 'false')
    }

    const $collapseToggle = $('div.outcome-toggles a.icon-collapse')
    if ($('li.group.expanded').length === 0) {
      // disabled attribute on <a> is invalid per the HTML spec
      $collapseToggle.attr('disabled', 'disabled')
      $collapseToggle.attr('aria-disabled', 'true')
    } else {
      $collapseToggle.removeAttr('disabled')
      $collapseToggle.attr('aria-disabled', 'false')
    }

    const $expandToggle = $('div.outcome-toggles a.icon-expand')
    if ($('li.group:not(.expanded)').length === 0) {
      // disabled attribute on <a> is invalid per the HTML spec
      $expandToggle.attr('disabled', 'disabled')
      return $expandToggle.attr('aria-disabled', 'true')
    } else {
      $expandToggle.removeAttr('disabled')
      return $expandToggle.attr('aria-disabled', 'false')
    }
  }

  statusTooltip() {
    switch (this.model.status()) {
      case 'undefined':
        return I18n.t('Unstarted')
      case 'remedial':
        return I18n.t('Well Below Mastery')
      case 'near':
        return I18n.t('Near Mastery')
      case 'mastery':
        return I18n.t('Meets Mastery')
      case 'exceeds':
        return I18n.t('Exceeds Mastery')
    }
  }

  toJSON() {
    return {
      ...super.toJSON(...arguments),
      statusTooltip: this.statusTooltip(),
    }
  }
}

GroupView.prototype.template = template
GroupView.prototype.tagName = 'li'
GroupView.prototype.className = 'group'
GroupView.prototype.els = {'.outcomes': '$outcomes'}
GroupView.prototype.events = {
  'click .group-description': 'expand',
  'keyclick .group-description': 'expand',
}

export default GroupView
