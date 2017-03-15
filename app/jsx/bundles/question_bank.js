#
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require [
  'i18n!outcomes'
  'jquery'
  'underscore'
  'compiled/models/OutcomeGroup'
  'compiled/views/outcomes/FindDialog'
  'compiled/views/outcomes/FindDirectoryView'
  'question_bank'
  'jst/quiz/move_question'
], (I18n, $, {map}, OutcomeGroup, FindDialog, FindDirectoryView, {updateAlignments, attachPageEvents}) ->
  class QuestionBankPage
    $els: {}

    translations:
      findOutcome: I18n.t('titles.find_outcomes', 'Find Outcomes')

    constructor: ->
      @rootOutcomeGroup = new OutcomeGroup(ENV.ROOT_OUTCOME_GROUP)
      @cacheElements()
      @attachEvents()

    cacheElements: ->
      @$els.addOutcome = $('.add_outcome_link')
      @$els.dialog = new FindDialog
        title: @translations.findOutcome
        selectedGroup: @rootOutcomeGroup
        setQuizMastery: true
        shouldImport: false
        disableGroupImport: true
        rootOutcomeGroup: @rootOutcomeGroup

    attachEvents: ->
      @$els.addOutcome.on('click', @onAddOutcome)
      @$els.dialog.on('import', @onOutcomeImport)

    onAddOutcome: (e) =>
      e.preventDefault()
      @$els.dialog.show()

    onOutcomeImport: (outcome) ->
      mastery = (outcome.quizMasteryLevel / 100.0) or 1.0
      alignments = map $('#aligned_outcomes_list .outcome:not(.blank)'), (o) ->
        $outcome = $(o)
        [id, percent] = [$outcome.data('id'), ($outcome.getTemplateData(textValues: ['mastery_threshold']).mastery_threshold) / 100.0]
        if id isnt outcome.get('id') then [id, percent] else null
      alignments.push([outcome.get('id'), mastery])
      updateAlignments(alignments)


  $(document).ready ->
    new QuestionBankPage
    attachPageEvents()

