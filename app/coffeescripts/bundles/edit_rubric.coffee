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
  'compiled/models/OutcomeGroup'
  'compiled/views/outcomes/FindDialog'
  'compiled/views/outcomes/FindDirectoryView'
  'edit_rubric'
], (I18n, $, OutcomeGroup, FindDialog, FindDirectoryView, rubricEditing) ->

  class EditRubricPage
    $els: {}

    translations:
      findOutcome: I18n.t('titles.find_outcomes', 'Find Outcomes')

    constructor: ->
      @rootOutcomeGroup = new OutcomeGroup(ENV.ROOT_OUTCOME_GROUP)
      @cacheElements()
      @attachEvents()

    cacheElements: ->
      @$els.rubricWrapper = $('#rubrics')
      @$els.dialog = new FindDialog
        title: @translations.findOutcome
        selectedGroup: @rootOutcomeGroup
        useForScoring: true
        shouldImport: false
        disableGroupImport: true
        rootOutcomeGroup: @rootOutcomeGroup

    attachEvents: ->
      @$els.rubricWrapper.on('click', 'a.find_outcome_link', @onFindOutcome)
      @$els.dialog.on('import', @onOutcomeImport)

    onFindOutcome: (e) =>
      e.preventDefault()
      @$els.dialog.show()
      @$els.dialog.$el.find('.alert').focus()

    onOutcomeImport: (model) ->
      rubricEditing.onFindOutcome(model)

  initEditRubricPage = ->
    new EditRubricPage
    rubricEditing.init()

  if $.isReady
    initEditRubricPage()
  else
    $(document).ready ->
      initEditRubricPage()
