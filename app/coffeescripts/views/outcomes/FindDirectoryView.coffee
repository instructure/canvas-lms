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

      @outcomes = new OutcomeCollection # empty - not needed
      @groups = new OutcomeGroupCollection _.compact([account, state, core])

      dfds = for g in _.compact([state, core])
        g.on 'change', @revertTitle
        g.fetch()

      @$el.disableWhileLoading $.when(dfds...).done @reset

      # super call not needed

    revertTitle: (group) ->
      group.set {
        title: group.previous 'title'
        description: group.previous 'description'
      }, silent: true