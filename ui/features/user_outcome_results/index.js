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

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('outcomes.user_outcome_results')

$(document).ready(() => {
  const showAllArtifacts = $('#show_all_artifacts_link')
  const hideOutcomeBtn = $('#hide_unassessed_outcomes_link')
  showAllArtifacts.click(event => {
    event.preventDefault()
    $('tr.artifact_details').toggle()
    if (showAllArtifacts.text() === I18n.t('Show All Artifacts')) {
      showAllArtifacts.text(I18n.t('Hide All Artifacts'))
    } else {
      showAllArtifacts.text(I18n.t('Show All Artifacts'))
    }
  })
  hideOutcomeBtn.click(e => {
    e.preventDefault()
    $('tr.js_unassessed_outcome').toggle('slow')
    if (hideOutcomeBtn.text() === I18n.t('Hide Unassessed Outcomes'))
      hideOutcomeBtn.text(I18n.t('Show Unassessed Outcomes'))
    else hideOutcomeBtn.text(I18n.t('Hide Unassessed Outcomes'))
  })
})
