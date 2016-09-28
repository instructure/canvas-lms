define [
  'i18n!assignments'
  'compiled/views/KeyboardNavDialog'
  'jst/KeyboardNavDialog'
  'jquery'
  'underscore'
  'Backbone'
  'jst/assignments/IndexView'
  'jst/assignments/NoAssignmentsSearch'
  'compiled/views/assignments/AssignmentKeyBindingsMixin'
  'compiled/userSettings'
  'compiled/api/gradingPeriodsApi'
  'compiled/jquery.rails_flash_notifications'
], (I18n, KeyboardNavDialog, keyboardNavTemplate, $, _, Backbone, template, NoAssignments, AssignmentKeyBindingsMixin, userSettings, GradingPeriodsAPI) ->

  class IndexView extends Backbone.View
    @mixin AssignmentKeyBindingsMixin

    template: template
    el: '#content'

    @child 'assignmentGroupsView', '[data-view=assignmentGroups]'
    @child 'createGroupView', '[data-view=createGroup]'
    @child 'assignmentSettingsView', '[data-view=assignmentSettings]'
    @child 'showByView', '[data-view=showBy]'

    events:
      'keyup #search_term': 'search'
      'change #grading_period_selector': 'filterResults'

    els:
      '#addGroup': '$addGroupButton'
      '#assignmentSettingsCog': '$assignmentSettingsButton'

    initialize: ->
      super
      @collection.once 'reset', @enableSearch, @
      @collection.on 'cancelSearch', @clearSearch, @

    toJSON: ->
      json = super
      json.course_home = ENV.COURSE_HOME
      json

    afterRender: ->
      # need to hide child views and set trigger manually

      if @createGroupView
        @createGroupView.hide()
        @createGroupView.setTrigger @$addGroupButton

      if @assignmentSettingsView
        @assignmentSettingsView.hide()
        @assignmentSettingsView.setTrigger @$assignmentSettingsButton

      @filterKeyBindings() if !@canManage()

      @ensureContentStyle()

      @kbDialog = new KeyboardNavDialog().render(keyboardNavTemplate({keyBindings:@keyBindings}))
      window.onkeydown = @focusOnAssignments

      @selectGradingPeriod()

    enableSearch: ->
      @$('#search_term').prop 'disabled', false

    clearSearch: ->
      @$('#search_term').val('')
      @filterResults()

    search: _.debounce ->
      @filterResults()
    , 200

    gradingPeriods: GradingPeriodsAPI.deserializePeriods(ENV.active_grading_periods)

    filterResults: =>
      term = $('#search_term').val()
      gradingPeriod = null
      if ENV.MULTIPLE_GRADING_PERIODS_ENABLED
        gradingPeriodIndex = $("#grading_period_selector").val()
        gradingPeriod = @gradingPeriods[parseInt(gradingPeriodIndex)] if gradingPeriodIndex != "all"
        @saveSelectedGradingPeriod(gradingPeriod)
      if term == "" && _.isNull(gradingPeriod)
        #show all
        @collection.each (group) =>
          group.groupView.endSearch()

        #remove noAssignments placeholder
        if @noAssignments?
          @noAssignments.remove()
          @noAssignments = null
      else
        regex = new RegExp(@cleanSearchTerm(term), 'ig')
        #search
        matchingAssignmentCount = @collection.reduce( (runningTotal, group) ->
          additionalCount = group.groupView.search(regex, gradingPeriod)
          runningTotal + additionalCount
        , 0)

        atleastoneGroup = matchingAssignmentCount > 0
        @alertForMatchingGroups(matchingAssignmentCount)

        #add noAssignments placeholder
        if !atleastoneGroup
          unless @noAssignments
            @noAssignments = new Backbone.View
              template: NoAssignments
              tagName: "li"
              className: "item-group-condensed"
            ul = @assignmentGroupsView.$el.children(".collectionViewItems")
            ul.append(@noAssignments.render().el)
        else
          #remove noAssignments placeholder
          if @noAssignments?
            @noAssignments.remove()
            @noAssignments = null

    alertForMatchingGroups: (numAssignments) ->
      msg = I18n.t({
          one: "1 assignment found."
          other: "%{count} assignments found."
          zero: "No matching assignments found."
        }, count: numAssignments
      )
      $.screenReaderFlashMessageExclusive(msg)

    cleanSearchTerm: (text) ->
      text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")

    focusOnAssignments: (e) =>
      if 74 == e.keyCode
        unless($(e.target).is("input"))
          $(".assignment_group").filter(":visible").first().attr("tabindex",-1).focus()

    canManage: ->
      ENV.PERMISSIONS.manage

    ensureContentStyle: ->
      # when loaded from homepage, need to change content style
      if !@canManage() && window.location.href.indexOf('assignments') == -1
        $("#content").css("padding", "0em")

    filterKeyBindings: =>
      @keyBindings = @keyBindings.filter (binding) ->
        ! _.contains([69,68,65], binding.keyCode)

    selectGradingPeriod: ->
      gradingPeriodId = userSettings.contextGet('assignments_current_grading_period')
      unless _.isNull(gradingPeriodId)
        for i of @gradingPeriods
          if @gradingPeriods[i].id == gradingPeriodId
            $("#grading_period_selector").val(i)
            break

    saveSelectedGradingPeriod: (gradingPeriod) ->
      userSettings.contextSet('assignments_current_grading_period', gradingPeriod && gradingPeriod.id)
