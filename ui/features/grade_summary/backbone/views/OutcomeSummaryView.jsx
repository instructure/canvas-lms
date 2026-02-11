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
import CollectionView from '@canvas/backbone-collection-view'
import SectionView from './SectionView'
import OutcomeDetailModal from '../../react/OutcomeDetailModal'
import {render, rerender} from '@canvas/react'
import {queryClient} from '@canvas/query'
import {QueryClientProvider} from '@tanstack/react-query'

export default class OutcomeSummaryView extends CollectionView {
  static initClass() {
    this.optionProperty('toggles')

    this.prototype.itemView = SectionView
  }

  initialize() {
    super.initialize(...arguments)
    return this.bindToggles()
  }

  onClose() {
    window.location.hash = 'tab-outcomes'
    rerender(this.outcomeDetailViewRoot, null)
  }

  createOutcomeDetailModal(outcome) {
    return (
      <QueryClientProvider client={queryClient}>
        <OutcomeDetailModal
          outcome={outcome.attributes}
          courseId={this.collection.course_id}
          courseName={ENV.current_context.name}
          userId={this.collection.user_id}
          onClose={() => this.onClose()}
        />
      </QueryClientProvider>
    )
  }

  async show(path) {
    this.fetch()

    if (!path) {
      return
    }

    const outcome_id = parseInt(path, 10)
    const outcome = this.collection.outcomeCache.get(outcome_id)

    if (!outcome) {
      return
    }

    if (this.outcomeDetailViewRoot) {
      rerender(this.outcomeDetailViewRoot, this.createOutcomeDetailModal(outcome))
    } else {
      this.outcomeDetailViewRoot = render(
        this.createOutcomeDetailModal(outcome),
        document.getElementById('outcome-detail-view-mount-point'),
      )
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
      // disabled attribute on <a> is invalid per the HTML spec
      $expandToggle.attr('disabled', 'disabled')
      $expandToggle.attr('aria-disabled', 'true')
      $collapseToggle.removeAttr('disabled')
      $collapseToggle.attr('aria-disabled', 'false')
      $('div.groups').focus()
    })
    return this.toggles.find('.icon-collapse').click(() => {
      this.$('li.group').removeClass('expanded')
      this.$('div.group-description').attr('aria-expanded', 'false')
      // disabled attribute on <a> is invalid per the HTML spec
      $collapseToggle.attr('disabled', 'disabled')
      $collapseToggle.attr('aria-disabled', 'true')
      $expandToggle.removeAttr('disabled')
      return $expandToggle.attr('aria-disabled', 'false')
    })
  }
}
OutcomeSummaryView.initClass()
