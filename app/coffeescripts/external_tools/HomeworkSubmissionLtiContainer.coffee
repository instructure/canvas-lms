define [
  'Backbone'
  'i18n!assignments'
  'jquery'
  'underscore'
  'jst/assignments/homework_submission_tool'
  'compiled/views/ExternalTools/ExternalContentReturnView',
  'compiled/external_tools/ExternalToolCollection'
  'compiled/views/assignments/ExternalContentFileSubmissionView'
  'compiled/views/assignments/ExternalContentUrlSubmissionView'
  'compiled/views/assignments/ExternalContentLtiLinkSubmissionView'
  'jquery.disableWhileLoading'
], ( Backbone, I18n, $, _, homeworkSubmissionTool, ExternalContentReturnView,
     ExternalToolCollection, ExternalContentFileSubmissionView,
     ExternalContentUrlSubmissionView, ExternalContentLtiLinkSubmissionView) ->

  class HomeworkSubmissionLtiContainer
    @homeworkSubmissionViewMap:
      FileItem: ExternalContentFileSubmissionView
      LtiLinkItem: ExternalContentLtiLinkSubmissionView

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
      item = data.contentItems[0]
      viewClass = HomeworkSubmissionLtiContainer.homeworkSubmissionViewMap[item['@type']] || ExternalContentUrlSubmissionView

      homeworkSubmissionView = new viewClass
        externalTool: tool
        model: new Backbone.Model(item)

      homeworkSubmissionView.on 'relaunchTool', (tool, model) ->
        @remove()
        @parentView.embedLtiLaunch(tool.get('id'))

      homeworkSubmissionView.on 'cancel', (tool, model) ->
        @parentView.cancelSubmission()

      return homeworkSubmissionView
