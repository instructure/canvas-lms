define [
  'i18n!discussion_topics'
  'compiled/views/ValidatedFormView'
  'compiled/views/assignments/AssignmentGroupSelector'
  'compiled/views/assignments/GradingTypeSelector'
  'compiled/views/assignments/GroupCategorySelector'
  'compiled/views/assignments/PeerReviewsSelector'
  'underscore'
  'jst/DiscussionTopics/EditView'
  'wikiSidebar'
  'str/htmlEscape'
  'compiled/models/DiscussionTopic'
  'compiled/models/Assignment'
  'jquery'
  'compiled/fn/preventDefault'
  'compiled/tinymce'
  'tinymce.editor_box'
  'jquery.instructure_misc_helpers' # $.scrollSidebar
  'compiled/jquery.rails_flash_notifications' #flashMessage
], (I18n, ValidatedFormView, AssignmentGroupSelector, GradingTypeSelector,
GroupCategorySelector, PeerReviewsSelector, _, template, wikiSidebar,
htmlEscape, DiscussionTopic, Assignment, $, preventDefault) ->

  class EditView extends ValidatedFormView

    template: template

    tagName: 'form'

    className: 'form-horizontal no-margin'

    dontRenableAfterSaveSuccess: true

    events: _.extend(@::events,
      'click .removeAttachment' : 'removeAttachment'
    )

    initialize: ->
      @permissions = @options.permissions
      @model.on 'sync', -> window.location = @get 'html_url'
      @assignment = new Assignment(@model.get('assignment') or {})
      super

    isTopic: => @model.constructor is DiscussionTopic

    toJSON: ->
      _.extend super, @options,
        showAssignment: !!@assignmentGroupCollection
        useForGrading: @model.get('assignment')?
        isTopic: @isTopic()
        contextIsCourse: @options.contextType is 'courses'
        canAttach: @permissions.CAN_ATTACH
        canModerate: @permissions.CAN_MODERATE
        isLargeRoster: ENV?.IS_LARGE_ROSTER || false

    render: =>
      super

      unless wikiSidebar.inited
        wikiSidebar.init()
        $.scrollSidebar()
      $textarea = @$('textarea[name=message]').attr('id', _.uniqueId('discussion-topic-message'))
      _.defer ->
        $textarea.editorBox()
        $('.rte_switch_views_link').click preventDefault -> $textarea.editorBox('toggle')
      wikiSidebar.attachToEditor $textarea

      wikiSidebar.show()

      if @assignmentGroupCollection
        (@assignmentGroupFetchDfd ||= @assignmentGroupCollection.fetch()).done @renderAssignmentGroupOptions

      _.defer(@renderGradingTypeOptions)
      _.defer(@renderGroupCategoryOptions)
      _.defer(@renderPeerReviewOptions)

      @$(".datetime_field").datetime_field()

      this

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
        parentModel: @assignment
        groupCategories: ENV.GROUP_CATEGORIES
        nested: true

      @groupCategorySelector.render()

    renderPeerReviewOptions: =>
      @peerReviewSelector = new PeerReviewsSelector
        el: '#peer_review_options'
        parentModel: @assignment
        nested: true

      @peerReviewSelector.render()

    getFormData: ->
      data = super
      data.title ||= I18n.t 'default_discussion_title', 'No Title'
      data.delayed_post_at = '' unless data.delay_posting
      data.discussion_type = if data.threaded then 'threaded' else 'side_comment'
      delete data.assignment unless data.assignment?.set_assignment?
      data.podcast_has_student_posts = false unless data.podcast_enabled
      if @isTopic() and not ENV?.IS_LARGE_ROSTER
        data.assignment = @groupCategorySelector.filterFormData data.assignment

      # these options get passed to Backbone.sync in ValidatedFormView
      @saveOpts = multipart: !!data.attachment

      data

    removeAttachment: ->
      @model.set 'attachments', []
      @$el.append '<input type="hidden" name="remove_attachment" >'
      @$('.attachmentRow').remove()
      @$('[name="attachment"]').show()

    validateBeforeSave: (data, errors) =>
      if @isTopic()
        errors = @assignmentGroupSelector.validateBeforeSave(data, errors)
        unless ENV?.IS_LARGE_ROSTER
          errors = @groupCategorySelector.validateBeforeSave(data, errors)
      errors
