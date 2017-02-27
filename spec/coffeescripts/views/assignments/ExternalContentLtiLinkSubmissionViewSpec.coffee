define [
  'Backbone'
  'compiled/views/assignments/ExternalContentLtiLinkSubmissionView'
  'jquery'
  'helpers/fakeENV'
], (Backbone, ExternalContentLtiLinkSubmissionView, $, fakeENV) ->
  contentItem:
    '@type': 'LtiLinkItem'
    url: 'http://lti.example.com/content/launch/42'
    comment: 'Foo all the bars!'

  QUnit.module 'ExternalContentLtiLinkSubmissionView',
    setup: ->
      fakeENV.setup()
      window.ENV.COURSE_ID = 42
      window.ENV.SUBMIT_ASSIGNMENT =
        ID: 24
      @model = new Backbone.Model(@contentItem)
      @view = new ExternalContentLtiLinkSubmissionView
        externalTool: {}
        model: @model

    teardown: ->
      fakeENV.teardown()
      $('#fixtures').empty()

  test "buildSubmission must return an object with submission_type set to 'basic_lti_launch'", ->
    equal @view.buildSubmission().submission_type, 'basic_lti_launch'

  test "buildSubmission must return an object with url set to the value from the supplied model", ->
    equal @view.buildSubmission().url, @model.get('url')

  test "extractComment must return an object with the model's comment field", ->
    equal @view.extractComment().text_comment, @model.get('comment')

  test "submissionURL() must return a url with the correct shape", ->
    equal @view.submissionURL(), '/api/v1/courses/42/assignments/24/submissions'
