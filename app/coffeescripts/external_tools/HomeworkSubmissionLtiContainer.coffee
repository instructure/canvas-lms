define [
  'Backbone'
  'i18n!assignments'
  'jquery'
  'underscore'
  'jst/assignments/homework_submission_tool'
  'compiled/views/ExternalTools/ExternalContentReturnView',
  'compiled/external_tools/ExternalToolCollection'
  'compiled/views/assignments/ExternalContentHomeworkSubmissionView'
  'jquery.disableWhileLoading'
], ( Backbone, I18n, $, _, homeworkSubmissionTool, ExternalContentReturnView, 
     ExternalToolCollection, ExternalContentHomeworkSubmissionView ) ->

  class HomeworkSubmissionLtiContainer

    constructor: (toolsFormSelector) ->
      @renderedViews = {}
      @toolsForm = $(toolsFormSelector)
      @externalToolCollection = new ExternalToolCollection
      @externalToolCollection.add(ENV.EXTERNAL_TOOLS)

    # load external tools and populate 'More' tab with the returned tools
    loadExternalTools: ->
      if @externalToolCollection.length > 0
        $(".submit_from_external_tool_option").parent().show() # display the 'More' tab
        @toolsForm.find("ul.tools").empty()
        @externalToolCollection.forEach (tool) =>
          @addToolToMoreList(tool)
      else
        @toolsForm.find("ul.tools li").text I18n.t("no_tools_found", "No tools found")

    # embed the LTI iframe into the tab contents
    embedLtiLaunch: (toolId) ->
      tool = @externalToolCollection.findWhere({ id: toolId.toString(10) })
      @cleanupViewsForTool(tool)
      returnView = @createReturnView(tool)
      $('#submit_from_external_tool_form_' + toolId).append(returnView.el)
      returnView.render()
      @renderedViews[toolId.toString(10)].push(returnView)

    # private methods below ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    cleanupViewsForTool: (tool) ->
      if _.has @renderedViews, tool.get('id')
        views = @renderedViews[tool.get('id')]
        views.forEach (v) =>
          v.remove()
      @renderedViews[tool.get('id')] = []

    cancelSubmission: ->
      $('#submit_assignment').hide()
      $('.submit_assignment_link').show()

    addToolToMoreList: (tool) ->
      tool.attributes.display_text = tool.get('homework_submission').label
      html = homeworkSubmissionTool(tool.attributes)
      $li = $(html).data('tool', tool)
      @toolsForm.find("ul.tools").append $li

    createReturnView: (tool) ->
      returnView = new ExternalContentReturnView
        model: tool
        launchType: 'homework_submission'
        launchParams: { assignment_id: ENV.SUBMIT_ASSIGNMENT.ID }
        displayAsModal: false

      returnView.on 'ready', (data) =>
        tool = `this.model` # this will return the model from returnView
        homeworkSubmissionView = @createHomeworkSubmissionView(tool, data)
        homeworkSubmissionView.parentView = this
        `this.remove()`
        $('#submit_from_external_tool_form_' + tool.get('id')).append(homeworkSubmissionView.el)

        @cleanupViewsForTool(tool)
        @renderedViews[tool.get('id')].push(homeworkSubmissionView)
        homeworkSubmissionView.render()

      returnView.on 'cancel', (data) ->
        return

      return returnView

    createHomeworkSubmissionView: (tool, data) ->
      homeworkSubmissionView = new ExternalContentHomeworkSubmissionView
        externalTool: tool
        model: new Backbone.Model(data)

      homeworkSubmissionView.on 'relaunchTool', (tool, model) ->
        @remove()
        @parentView.embedLtiLaunch(tool.get('id'))

      homeworkSubmissionView.on 'submit', (tool, model) =>
        @uploadFileFromUrl(tool, model)

      homeworkSubmissionView.on 'cancel', (tool, model) ->
        @parentView.cancelSubmission()

      return homeworkSubmissionView

    checkFileStatus: (url, callback, error) =>
      $.ajaxJSON url, "GET", {}, ((data) =>
        if data.upload_status is "ready"
          callback data.attachment
        else if data.upload_status is "errored"
          error data.message
        else
          setTimeout (=>
            @checkFileStatus url, callback, error
            return
          ), 2500
        return
      ), (data) ->
        error data.message

    redirectSuccessfulAssignment: (responseData) =>
      window.onbeforeunload = -> # remove alert message from being triggered
      window.location.reload()
      @loaderPromise.resolve()
      return

    disableLoader: =>
      @loaderPromise.resolve()

    submitAssignment: (fileData) =>
      data =
        submission:
          submission_type: "online_upload"
          file_ids: [ fileData.id ]
        comment:
          text_comment: @assignmentSubmission.get('comment')

      submissionUrl = "/api/v1/courses/" + ENV.COURSE_ID + "/assignments/" + ENV.SUBMIT_ASSIGNMENT.ID + "/submissions"
      $.ajaxJSON submissionUrl, "POST", data, @redirectSuccessfulAssignment, @disableLoader

      return

    submissionFailure: (message) =>
      @loaderPromise.resolve()
      thisForm.find(".submit_button").text I18n.t("file_retrieval_error", "Retrieving File Failed")
      $.flashError I18n.t("invalid_file_retrieval", "There was a problem retrieving the file sent from this tool.")

    uploadSuccess: (data) =>
      @checkFileStatus data.status_url, @submitAssignment, @submissionFailure
      return

    uploadFailure: (data) =>
      @loaderPromise.resolve()
      thisForm.find(".submit_button").text I18n.t("file_retrieval_error", "Retrieving File Failed")
      return

    uploadFileFromUrl: (tool, modelData) ->
      @loaderPromise = $.Deferred()
      thisForm = $('#submit_from_external_tool_form_' + tool.get('id'));

      @assignmentSubmission = modelData
      # build the params for submitting the assignment
      fileParams =
        url: @assignmentSubmission.get('url')
        name: @assignmentSubmission.get('text')
        content_type: ''

      fileUploadUrl = "/api/v1/courses/" + ENV.COURSE_ID + "/assignments/" + ENV.SUBMIT_ASSIGNMENT.ID + "/submissions/" + ENV.current_user_id + "/files"
      $.ajaxJSON fileUploadUrl, "POST", fileParams, @uploadSuccess, @uploadFailure

      thisForm.disableWhileLoading @loaderPromise,
        buttons:
          ".submit_button": I18n.t("getting_file", "Retrieving File...")

      return
