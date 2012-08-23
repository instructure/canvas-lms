define [
  'i18n!discussion_topics'
  'compiled/views/ValidatedFormView'
  'underscore'
  'jst/DiscussionTopics/EditView'
  'wikiSidebar'
  'str/htmlEscape'
  'compiled/models/Announcement'
  'jquery'
  'compiled/tinymce'
  'tinymce.editor_box'
  'jquery.instructure_misc_helpers' # $.scrollSidebar
  'compiled/jquery.rails_flash_notifications' #flashMessage
], (I18n, ValidatedFormView, _, template, wikiSidebar, htmlEscape, Announcement, $) ->

  class EditView extends ValidatedFormView

    template: template

    tagName: 'form'

    className: 'form-horizontal bootstrap-form'

    dontRenableAfterSaveSuccess: true

    events: _.extend(@::events,
      'click .removeAttachment' : 'removeAttachment'
    )

    initialize: ->
      @model.on 'sync', -> window.location = @get 'html_url'
      super

    toJSON: ->
      _.extend super, @options,
        showAssignment: !!@assignmentGroupCollection
        isAnnouncement: @model.constructor is Announcement

    render: =>
      super

      unless wikiSidebar.inited
        wikiSidebar.init()
        $.scrollSidebar()
      wikiSidebar.attachToEditor @$('textarea[name=message]').attr('id', _.uniqueId('discussion-topic-message')).editorBox()
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
      data.delay_posting_at = data.delay_posting && data.delay_posting_at
      data.discussion_type = if data.threaded then 'threaded' else 'side_comment'
      delete data.assignment unless data.assignment?.set_assignment

      # these options get passed to Backbone.sync in ValidatedFormView
      @saveOpts = multipart: !!data.attachment

      data

    removeAttachment: ->
      @model.set 'attachments', []
      @$el.append '<input type="hidden" name="remove_attachment" >'
      @$('.attachmentRow').remove()
      @$('[name="attachment"]').show()
