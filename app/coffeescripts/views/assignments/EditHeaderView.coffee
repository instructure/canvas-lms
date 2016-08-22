define [
  'i18n!assignments'
  'Backbone'
  'jquery'
  'jsx/shared/conditional_release/ConditionalRelease'
  'jst/assignments/EditHeaderView'
  'jquery.disableWhileLoading'
], (I18n, Backbone, $, ConditionalRelease, template) ->

  class EditHeaderView extends Backbone.View

    template: template

    events:
      'click .delete_assignment_link': 'onDelete'
      'change #grading_type_selector': 'onGradingTypeUpdate'
      'tabsbeforeactivate': 'onTabChange'


    messages:
      confirm: I18n.t('confirms.delete_assignment', 'Are you sure you want to delete this assignment?')

    els:
      '#edit-assignment-header-tabs': '$headerTabs'
      '#edit-assignment-header-cr-tabs': '$headerTabsCr'

    initialize: (options) ->
      super
      @editView = options.views['edit_assignment_form']
      @editView.on 'show-errors', @onShowErrors

    afterRender: ->
      # doubled for conditional release
      @$headerTabs.tabs()
      @$headerTabsCr.tabs()
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        @toggleConditionalReleaseTab(@model.gradingType())

    onDelete: (e) =>
      e.preventDefault()
      @delete() if confirm(@messages.confirm)

    delete: ->
      disablingDfd = new $.Deferred()
      if destroyDfd = @model.destroy()
        destroyDfd.then(@onSaveSuccess)
        destroyDfd.fail -> disablingDfd.reject()
        $('#content').disableWhileLoading disablingDfd
      else
        # .destroy() returns false if model isNew
        @onDeleteSuccess()

    onDeleteSuccess: ->
      location.href = ENV.ASSIGNMENT_INDEX_URL

    onGradingTypeUpdate: (e) =>
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        @toggleConditionalReleaseTab(e.target.value)

    toggleConditionalReleaseTab: (gradingType) ->
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        if gradingType == 'not_graded'
          @$headerTabsCr.tabs("option", "disabled", [1])
        else
          @$headerTabsCr.tabs("option", "disabled", false)

    onTabChange: ->
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        @editView.updateConditionalRelease()
      true

    onShowErrors: (errors) =>
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        if errors['conditional_release']
          @$headerTabsCr.tabs("option", "active", 1)
          @editView.$conditionalReleaseTarget.get(0).scrollIntoView()
        else
          @$headerTabsCr.tabs("option", "active", 0)

    toJSON: ->
      json = @model.toView()
      json['CONDITIONAL_RELEASE_SERVICE_ENABLED'] = ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
      json
