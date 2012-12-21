define [
  'i18n!discussion_topics'
  'compiled/views/ValidatedFormView'
  'underscore'
  'jst/DiscussionTopics/EditView'
  'wikiSidebar'
  'str/htmlEscape'
  'compiled/models/DiscussionTopic'
  'jquery'
  'compiled/fn/preventDefault'
  'compiled/tinymce'
  'tinymce.editor_box'
  'jquery.instructure_misc_helpers' # $.scrollSidebar
  'compiled/jquery.rails_flash_notifications' #flashMessage
], (I18n, ValidatedFormView, _, template, wikiSidebar, htmlEscape, DiscussionTopic, $, preventDefault) ->

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
      super

    toJSON: ->
      _.extend super, @options,
        showAssignment: !!@assignmentGroupCollection
        useForGrading: @model.get('assignment')?
        isTopic: @model.constructor is DiscussionTopic
        contextIsCourse: @options.contextType is 'courses'
        canAttach: @permissions.CAN_ATTACH
        canModerate: @permissions.CAN_MODERATE

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

      @$(".datetime_field").datetime_field()

      this

    # I am sad that this code even had to be written, we should abstract away
    # handling a 'remoteSelect' for a collection
    renderAssignmentGroupOptions: =>
      html = @assignmentGroupCollection.map (ag) ->
        "<option value='#{ag.id}'>#{htmlEscape ag.get('name')}</option>"
      .join('')

      @$('[name="assignment[assignment_group_id]"]')
        .html(html)
        .prop('disabled', false)
        .val @model.get('assignment')?.assignment_group_id

    getFormData: ->
      data = super
      data.title ||= I18n.t 'default_discussion_title', 'No Title'
      data.delayed_post_at = '' unless data.delay_posting
      data.discussion_type = if data.threaded then 'threaded' else 'side_comment'
      delete data.assignment unless data.assignment?.set_assignment?
      data.podcast_has_student_posts = false unless data.podcast_enabled

      # these options get passed to Backbone.sync in ValidatedFormView
      @saveOpts = multipart: !!data.attachment

      data

    removeAttachment: ->
      @model.set 'attachments', []
      @$el.append '<input type="hidden" name="remove_attachment" >'
      @$('.attachmentRow').remove()
      @$('[name="attachment"]').show()
