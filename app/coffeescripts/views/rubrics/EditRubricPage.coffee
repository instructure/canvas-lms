define [
  'i18n!outcomes'
  'jquery'
  'compiled/models/OutcomeGroup'
  'compiled/views/outcomes/FindDialog'
  'edit_rubric'
], (I18n, $, OutcomeGroup, FindDialog, rubricEditing) ->

  class EditRubricPage
    $els: {}

    translations:
      findOutcome: I18n.t('titles.find_outcomes', 'Find Outcomes')

    constructor: ->
      @rootOutcomeGroup = new OutcomeGroup(ENV.ROOT_OUTCOME_GROUP)
      @attachInitialEvent()
      @dialogCreated = false

    attachInitialEvent: ->
      @$els.rubricWrapper = $('#rubrics')
      @$els.rubricWrapper.on('click', 'a.find_outcome_link', @onFindOutcome)

    createDialog: ->
      @$els.dialog = new FindDialog
        title: @translations.findOutcome
        selectedGroup: @rootOutcomeGroup
        useForScoring: true
        shouldImport: false
        disableGroupImport: true
        rootOutcomeGroup: @rootOutcomeGroup
      @$els.dialog.on('import', @onOutcomeImport)
      @dialogCreated = true

    onFindOutcome: (e) =>
      e.preventDefault()
      @createDialog() unless @dialogCreated
      @$els.dialog.show()
      @$els.dialog.$el.find('.alert').focus()

    onOutcomeImport: (model) ->
      rubricEditing.onFindOutcome(model)
