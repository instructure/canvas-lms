/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
import {map} from 'lodash'
import OutcomeGroup from '@canvas/outcomes/backbone/models/OutcomeGroup'
import FindDialog from '@canvas/outcomes/backbone/views/FindDialog'
import {updateAlignments, attachPageEvents} from './jquery/index'
import './jst/move_question.handlebars'

const I18n = useI18nScope('bundles_quesiton_bank')

class QuestionBankPage {
  static initClass() {
    this.prototype.$els = {}

    this.prototype.translations = {findOutcome: I18n.t('titles.find_outcomes', 'Find Outcomes')}
  }

  constructor() {
    this.rootOutcomeGroup = new OutcomeGroup(ENV.ROOT_OUTCOME_GROUP)
    this.attachEvents()
  }

  createDialog() {
    this.$els.dialog = new FindDialog({
      title: this.translations.findOutcome,
      selectedGroup: this.rootOutcomeGroup,
      setQuizMastery: true,
      shouldImport: false,
      disableGroupImport: true,
      rootOutcomeGroup: this.rootOutcomeGroup,
    })
    this.$els.dialog.on('import', this.onOutcomeImport)
  }

  attachEvents() {
    $('.add_outcome_link').on('click', this.onAddOutcome)
  }

  onAddOutcome = e => {
    e.preventDefault()
    if (!this.$els.dialog) {
      this.createDialog()
    }
    this.$els.dialog.show()
  }

  onOutcomeImport(outcome) {
    const mastery = outcome.quizMasteryLevel / 100.0 || 1.0
    const alignments = map($('#aligned_outcomes_list .outcome:not(.blank)'), o => {
      const $outcome = $(o)
      const [id, percent] = Array.from([
        $outcome.data('id'),
        $outcome.getTemplateData({textValues: ['mastery_threshold']}).mastery_threshold / 100.0,
      ])
      if (id !== outcome.get('id')) {
        return [id, percent]
      }
      return null
    })
    alignments.push([outcome.get('id'), mastery])
    updateAlignments(alignments)
  }
}
QuestionBankPage.initClass()

$(document).ready(() => {
  new QuestionBankPage()
  attachPageEvents()
})
