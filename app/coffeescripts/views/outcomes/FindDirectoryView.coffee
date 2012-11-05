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

define [
  'i18n!outcomes'
  'jquery'
  'underscore'
  'compiled/views/outcomes/OutcomesDirectoryView'
  'compiled/views/outcomes/AccountDirectoryView'
  'compiled/views/outcomes/StateStandardsDirectoryView'
  'compiled/models/OutcomeGroup'
  'compiled/collections/OutcomeCollection'
  'compiled/collections/OutcomeGroupCollection'
  'jquery.disableWhileLoading'
], (I18n, $, _, OutcomesDirectoryView, AccountDirectoryView, StateStandardsDirectoryView, OutcomeGroup, OutcomeCollection, OutcomeGroupCollection) ->

  # Used in the FindDialog.
  class FindDirectoryView extends OutcomesDirectoryView

    initialize: (opts) ->
      @readOnly = true

      account = new OutcomeGroup
        dontImport: true
        id: -1 # trick to think it's not new
        title: I18n.t('account_standards', 'Account Standards')
        description: I18n.t('account_standards_description', "To the left you'll notice the standards your institution has created for you to use in your courses.")
        directoryClass: AccountDirectoryView
      if ENV.STATE_STANDARDS_URL
        state = new OutcomeGroup
          dontImport: true
          title: I18n.t('state_standards', 'State Standards')
          description: I18n.t('state_standards_description', "To the left you'll see a folder for each state with their updated state standards. This allows for you to painlessly include state standards for grading within your course.")
          directoryClass: StateStandardsDirectoryView
        state.url = ENV.STATE_STANDARDS_URL
      if ENV.COMMON_CORE_GROUP_URL
        core = new OutcomeGroup
          dontImport: true
          title: I18n.t('common_core', 'Common Core Standards')
          description: I18n.t('common_core_description', "To the left is the familiar outcomes folder structure for each grouping of the Common Core State Standards. This will allow you to effortlessly include any of the Common Core Standards for grading within your course.")
        core.url = ENV.COMMON_CORE_GROUP_URL
      course = opts.courseGroup if opts.courseGroup

      @outcomes = new OutcomeCollection # empty - not needed
      @groups = new OutcomeGroupCollection _.compact([account, state, core, course])

      dfds = for g in _.compact([state, core])
        g.on 'change', @revertTitle
        g.fetch()

      # When there is no State or Core (account context), there are no deferreds to
      # wait for. This adds a 'setTimeout' which calls reset that fixes display
      # issues and hooks up the click handlers to the sidebar.
      @$el.disableWhileLoading $.when(dfds...).done =>
        setTimeout =>
          @reset()
          @$el.find('[tabindex=0]:first').focus()

      # super call not needed

    revertTitle: (group) ->
      group.set {
        title: group.previous 'title'
        description: group.previous 'description'
      }, silent: true
