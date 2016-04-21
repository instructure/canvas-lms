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
      'change' : 'onChange'

    messages:
      confirm: I18n.t('confirms.delete_assignment', 'Are you sure you want to delete this assignment?')

    els:
      '#edit-assignment-header-tabs': '$headerTabs'
      '#edit-assignment-header-cr-tabs': '$headerTabsCr'
      '#conditional-release-target': '$conditionalReleaseTarget'

    afterRender: ->
      # doubled for conditional release
      @$headerTabs.tabs()
      @$headerTabsCr.tabs()

      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        @toggleConditionalReleaseTab(@model.gradingType())
        @conditionalReleaseEditor = ConditionalRelease.attach(
          @$conditionalReleaseTarget.get(0),
          I18n.t('assignment'),
          ENV.CONDITIONAL_RELEASE_ENV)

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

    toJSON: ->
      json = @model.toView()
      json['CONDITIONAL_RELEASE_SERVICE_ENABLED'] = ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
      json

    onChange: ->
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED && !@assignmentDirty
        @assignmentDirty = true
        @conditionalReleaseEditor.setProps({ assignmentDirty: true })
