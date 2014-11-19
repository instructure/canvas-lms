define [
  'i18n!discussion_topics'
  'compiled/views/ValidatedFormView'
  'compiled/views/assignments/AssignmentGroupSelector'
  'compiled/views/assignments/GradingTypeSelector'
  'compiled/views/assignments/GroupCategorySelector'
  'compiled/views/assignments/PeerReviewsSelector'
  'compiled/views/assignments/PostToSisSelector'
  'underscore'
  'jst/DiscussionTopics/EditView'
  'wikiSidebar'
  'str/htmlEscape'
  'compiled/models/DiscussionTopic'
  'compiled/models/Announcement'
  'compiled/models/Assignment'
  'jquery'
  'compiled/fn/preventDefault'
  'compiled/views/calendar/MissingDateDialogView'
  'compiled/views/editor/KeyboardShortcuts'
  'compiled/tinymce'
  'tinymce.editor_box'
  'jquery.instructure_misc_helpers' # $.scrollSidebar
  'compiled/jquery.rails_flash_notifications' #flashMessage
], (I18n, ValidatedFormView, AssignmentGroupSelector, GradingTypeSelector,
GroupCategorySelector, PeerReviewsSelector, PostToSisSelector, _, template, wikiSidebar,
htmlEscape, DiscussionTopic, Announcement, Assignment, $, preventDefault, MissingDateDialog, KeyboardShortcuts) ->

  class EditView extends ValidatedFormView

    template: template

    tagName: 'form'

    className: 'form-horizontal no-margin'

    dontRenableAfterSaveSuccess: true

    els:
      '#availability_options': '$availabilityOptions'
      '#use_for_grading': '$useForGrading'

    events: _.extend(@::events,
      'click .removeAttachment' : 'removeAttachment'
      'change #use_for_grading' : 'toggleAvailabilityOptions'
    )

    messages:
      group_category_section_label: I18n.t('group_discussion_title', 'Group Discussion')
      group_category_field_label: I18n.t('this_is_a_group_discussion', 'This is a Group Discussion')
      group_locked_message: I18n.t('group_discussion_locked', 'Students have already submitted to this discussion, so group settings cannot be changed.')

    @optionProperty 'permissions'

    initialize: (options) ->
      @assignment = @model.get("assignment")
      @dueDateOverrideView = options.views['js-assignment-overrides']
      @model.on 'sync', =>
        @unwatchUnload()
        window.location = @model.get 'html_url'
      super

    isTopic: => @model.constructor is DiscussionTopic

    isAnnouncement: => @model.constructor is Announcement

    toJSON: ->
      data = super
      json = _.extend data, @options,
        showAssignment: !!@assignmentGroupCollection
        useForGrading: @model.get('assignment')?
        isTopic: @isTopic()
        isAnnouncement: @isAnnouncement()
        contextIsCourse: @options.contextType is 'courses'
        canAttach: @permissions.CAN_ATTACH
        canModerate: @permissions.CAN_MODERATE
        isLargeRoster: ENV?.IS_LARGE_ROSTER || false
        threaded: data.discussion_type is "threaded"
        draftStateEnabled: ENV.DRAFT_STATE && ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE
        differentiatedAssignmentsEnabled: @model.differentiatedAssignmentsEnabled()
      json.assignment = json.assignment.toView()
      json

    render: =>
      super

      unless wikiSidebar.inited
        wikiSidebar.init()
        $.scrollSidebar()
      $textarea = @$('textarea[name=message]').attr('id', _.uniqueId('discussion-topic-message'))
      _.defer ->
        $textarea.editorBox()
        $('.rte_switch_views_link').click (event) ->
          event.preventDefault()
          event.stopPropagation()
          $textarea.editorBox 'toggle'
          # hide the clicked link, and show the other toggle link.
          # todo: replace .andSelf with .addBack when JQuery is upgraded.
          $(event.currentTarget).siblings('.rte_switch_views_link').andSelf().toggle()
      wikiSidebar.attachToEditor $textarea

      wikiSidebar.show()

      if @assignmentGroupCollection
        (@assignmentGroupFetchDfd ||= @assignmentGroupCollection.fetch()).done @renderAssignmentGroupOptions

      _.defer(@renderGradingTypeOptions)
      _.defer(@renderGroupCategoryOptions)
      _.defer(@renderPeerReviewOptions)
      _.defer(@renderPostToSisOptions) if ENV.POST_GRADES
      _.defer(@watchUnload)
      _.defer(@attachKeyboardShortcuts)

      @$(".datetime_field").datetime_field()

      this

    attachKeyboardShortcuts: =>
        $('.rte_switch_views_link').first().before((new KeyboardShortcuts()).render().$el)

    renderAssignmentGroupOptions: =>
      @assignmentGroupSelector = new AssignmentGroupSelector
        el: '#assignment_group_options'
        assignmentGroups: @assignmentGroupCollection.toJSON()
        parentModel: @assignment
        nested: true

      @assignmentGroupSelector.render()

    renderGradingTypeOptions: =>
      @gradingTypeSelector = new GradingTypeSelector
        el: '#grading_type_options'
        parentModel: @assignment
        nested: true
        preventNotGraded: true

      @gradingTypeSelector.render()

    renderGroupCategoryOptions: =>
      @groupCategorySelector = new GroupCategorySelector
        el: '#group_category_options'
        parentModel: @model
        groupCategories: ENV.GROUP_CATEGORIES
        hideGradeIndividually: true
        sectionLabel: @messages.group_category_section_label
        fieldLabel: @messages.group_category_field_label
        lockedMessage: @messages.group_locked_message

      @groupCategorySelector.render()

    renderPeerReviewOptions: =>
      @peerReviewSelector = new PeerReviewsSelector
        el: '#peer_review_options'
        parentModel: @assignment
        nested: true

      @peerReviewSelector.render()

    renderPostToSisOptions: =>
      @postToSisSelector = new PostToSisSelector
        el: '#post_to_sis_options'
        parentModel: @assignment
        nested: true

      @postToSisSelector.render()

    getFormData: ->
      data = super
      data.title ||= I18n.t 'default_discussion_title', 'No Title'
      data.discussion_type = if data.threaded is '1' then 'threaded' else 'side_comment'
      data.podcast_has_student_posts = false unless data.podcast_enabled is '1'
      unless ENV?.IS_LARGE_ROSTER
        data = @groupCategorySelector.filterFormData data

      assign_data = data.assignment
      delete data.assignment

      if assign_data?.set_assignment is '1'
        data.set_assignment = '1'
        data.assignment = @updateAssignment(assign_data)
        data.delayed_post_at = ''
        data.lock_at = ''
      else
        # Announcements don't have assignments.
        # DiscussionTopics get a model created for them in their
        # constructor. Delete it so the API doesn't automatically
        # create assignments unless the user checked "Use for Grading".
        # The controller checks for set_assignment on the assignment model,
        # so we can't make it undefined here for the case of discussion topics.
        data.assignment = @model.createAssignment(set_assignment: '0')

      # these options get passed to Backbone.sync in ValidatedFormView
      @saveOpts = multipart: !!data.attachment, proxyAttachment: true

      data

    updateAssignment: (data) =>
      @dueDateOverrideView.updateOverrides()
      defaultDate = @dueDateOverrideView.getDefaultDueDate()
      data.lock_at = defaultDate?.get('lock_at') or null
      data.unlock_at = defaultDate?.get('unlock_at') or null
      data.due_at = defaultDate?.get('due_at') or null
      data.assignment_overrides = @dueDateOverrideView.getOverrides()
      if ENV?.DIFFERENTIATED_ASSIGNMENTS_ENABLED
        data.only_visible_to_overrides = @dueDateOverrideView.containsSectionsWithoutOverrides()

      assignment = @model.get('assignment')
      assignment or= @model.createAssignment()
      assignment.set(data)

    removeAttachment: ->
      @model.set 'attachments', []
      @$el.append '<input type="hidden" name="remove_attachment" >'
      @$('.attachmentRow').remove()
      @$('[name="attachment"]').show()

    submit: (event) =>
      event.preventDefault()
      event.stopPropagation()
      if @dueDateOverrideView.containsSectionsWithoutOverrides()
        sections = @dueDateOverrideView.sectionsWithoutOverrides()
        missingDateDialog = new MissingDateDialog
          validationFn: -> sections
          labelFn: (section) -> section.get 'name'
          da_enabled: ENV?.DIFFERENTIATED_ASSIGNMENTS_ENABLED
          success: =>
            missingDateDialog.$dialog.dialog('close').remove()
            @model.get('assignment')?.setNullDates()
            ValidatedFormView::submit.call(this)
        missingDateDialog.cancel = (e) ->
          missingDateDialog.$dialog.dialog('close').remove()

        missingDateDialog.render()
      else
        super

    fieldSelectors: _.extend({},
      AssignmentGroupSelector::fieldSelectors,
      GroupCategorySelector::fieldSelectors
    )

    validateBeforeSave: (data, errors) =>
      if data.delay_posting == "0"
        data.delayed_post_at = null
      if @isTopic() && data.set_assignment is '1'
        if @assignmentGroupSelector?
          errors = @assignmentGroupSelector.validateBeforeSave(data, errors)
        unless ENV?.IS_LARGE_ROSTER
          errors = @groupCategorySelector.validateBeforeSave(data, errors)
        data2 =
          assignment_overrides: @dueDateOverrideView.getAllDates(data.assignment.toJSON())
        errors = @dueDateOverrideView.validateBeforeSave(data2, errors)
        errors = @_validatePointsPossible(data, errors)
      else
        @model.set 'assignment', @model.createAssignment(set_assignment: false)
      errors

    _validatePointsPossible: (data, errors) =>
      assign = data.assignment
      frozenPoints = _.contains(assign.frozenAttributes(), "points_possible")

      if !frozenPoints and assign.pointsPossible() and isNaN(parseFloat(assign.pointsPossible()))
        errors["assignment[points_possible]"] = [
          message: I18n.t 'points_possible_number', 'Points possible must be a number'
        ]
      errors

    showErrors: (errors) ->
      # override view handles displaying override errors, remove them
      # before calling super
      # see getFormValues in DueDateView.coffee
      delete errors.assignmentOverrides
      super(errors)

    toggleAvailabilityOptions: ->
      if @$useForGrading.is(':checked')
        @$availabilityOptions.hide()
      else
        @$availabilityOptions.show()
