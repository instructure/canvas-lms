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

import $ from 'jquery'
import CollectionView from '../CollectionView'
import SectionView from './SectionView'
import OutcomeDetailView from './OutcomeDetailView'

export default class OutcomeSummaryView extends CollectionView {
  static initClass() {
    this.optionProperty('toggles')

    this.prototype.itemView = SectionView
  }

  initialize() {
    super.initialize(...arguments)
    this.outcomeDetailView = new OutcomeDetailView()
    return this.bindToggles()
  }

  show(path) {
    this.fetch()
    if (path) {
      const outcome_id = parseInt(path)
      const outcome = this.collection.outcomeCache.get(outcome_id)
      if (outcome) return this.outcomeDetailView.show(outcome)
    } else {
      return this.outcomeDetailView.close()
    }
  }

  fetch() {
    this.fetch = $.noop
    return this.collection.fetch()
  }

  bindToggles() {
    const $collapseToggle = $('div.outcome-toggles a.icon-collapse')
    const $expandToggle = $('div.outcome-toggles a.icon-expand')
    this.toggles.find('.icon-expand').click(() => {
      this.$('li.group').addClass('expanded')
      this.$('div.group-description').attr('aria-expanded', 'true')
      $expandToggle.attr('disabled', 'disabled')
      $expandToggle.attr('aria-disabled', 'true')
      $collapseToggle.removeAttr('disabled')
      $collapseToggle.attr('aria-disabled', 'false')
      $('div.groups').focus()
    })
    return this.toggles.find('.icon-collapse').click(() => {
      this.$('li.group').removeClass('expanded')
      this.$('div.group-description').attr('aria-expanded', 'false')
      $collapseToggle.attr('disabled', 'disabled')
      $collapseToggle.attr('aria-disabled', 'true')
      $expandToggle.removeAttr('disabled')
      return $expandToggle.attr('aria-disabled', 'false')
    })
  }
}
OutcomeSummaryView.initClass()
