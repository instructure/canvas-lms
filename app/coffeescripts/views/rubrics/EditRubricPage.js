//
// Copyright (C) 2015 - present Instructure, Inc.
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

import I18n from 'i18n!outcomes'
import $ from 'jquery'
import OutcomeGroup from '../../models/OutcomeGroup'
import FindDialog from '../outcomes/FindDialog'
import rubricEditing from 'edit_rubric'

export default class EditRubricPage {
  static initClass() {
    this.prototype.$els = {}

    this.prototype.translations = {findOutcome: I18n.t('titles.find_outcomes', 'Find Outcomes')}
  }

  constructor() {
    this.onFindOutcome = this.onFindOutcome.bind(this)
    this.rootOutcomeGroup = new OutcomeGroup(ENV.ROOT_OUTCOME_GROUP)
    this.attachInitialEvent()
    this.dialogCreated = false
  }

  attachInitialEvent() {
    this.$els.rubricWrapper = $('#rubrics')
    return this.$els.rubricWrapper.on('click', 'a.find_outcome_link', this.onFindOutcome)
  }

  createDialog() {
    this.$els.dialog = new FindDialog({
      title: this.translations.findOutcome,
      selectedGroup: this.rootOutcomeGroup,
      useForScoring: true,
      shouldImport: false,
      disableGroupImport: true,
      rootOutcomeGroup: this.rootOutcomeGroup
    })
    this.$els.dialog.on('import', this.onOutcomeImport)
    return (this.dialogCreated = true)
  }

  onFindOutcome(e) {
    e.preventDefault()
    if (!this.dialogCreated) {
      this.createDialog()
    }
    this.$els.dialog.show()
    return this.$els.dialog.$el.find('.alert').focus()
  }

  onOutcomeImport(model) {
    return rubricEditing.onFindOutcome(model)
  }
}
EditRubricPage.initClass()
