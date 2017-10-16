#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define ['submit_assignment_helper','jquery'], ({submitContentItem, recordEulaAgreement}, $) ->
  formHtml = """
            <div id="form-container">
            <form accept-charset="UTF-8" action="/courses/2/assignments/1/submissions" id="submit_online_url_form" method="post">
              <input name="utf8" type="hidden" value="✓">
              <input name="authenticity_token" type="hidden" value="auth_token"></div>
              <input id="submission_submission_type" name="submission[submission_type]" type="hidden" value="online_url">
              <input id="submission_url" name="submission[url]" style="min-width: 250px;" type="text">
              <textarea class="submission_comment_textarea" id="submission_comment" name="submission[comment]"></textarea>
            </form>
            <form id="submit_form_external_tool_form">
              <input id="external_tool_submission_type" name="submission[submission_type]" type="hidden" value="online_url">
              <input id="external_tool_filename" name="submission[filename]" type="hidden">
              <input id="external_tool_file_id" name="submission[attachment_ids]" type="hidden">
              <input id="external_tool_url" name="submission[url]" type="hidden">
              <input id="external_tool_content_type" name="submission[content_type]" type="hidden">
              <span class="bad_ext_msg"></span>
            </form>
            <form accept-charset="UTF-8" action="/action" id="submit_online_upload_form" method="post">
              <input name="utf8" type="hidden" value="✓"><input name="authenticity_token" type="hidden" value="token">
              <input id="submission_submission_type" name="submission[submission_type]" type="hidden" value="online_upload">
              <input id="submission_attachment_ids" name="submission[attachment_ids]" type="hidden" value=">
              <input aria-labelledby="attachmentLabel" type="file" name="attachments[0][uploaded_data]" class="input-file">
              <input aria-labelledby="attachmentLabel" type="file" name="attachments[-1][uploaded_data]" class="input-file">
            </form>
          </div>
          """


  url = 'https://lti-tool-provider-example.herokuapp.com/messages/blti'
  fileUrl = 'https://lti-tool-provider-example.herokuapp.com/test_file.txt'
  contentItem = null
  originalEnv = null

  QUnit.module "SubmitAssignmentHelper",
    setup: ->
      $('#fixtures').append(formHtml)
      contentItem =
        'ext_canvas_visibility': 'users': [
          '86157096483e6b3a50bfedc6bac902c0b20a824f'
        ]
        'updateUrl': 'https://lti-tool-provider-example.herokuapp.com/messages/content-item'
        'windowTarget': ''
        'text': 'Arch Linux'
        'title': 'It\'s amazing'
        'url': url
        'thumbnail':
          'height': 128
          'width': 128
          '@id': 'http://www.runeaudio.com/assets/img/banner-archlinux.png'
        'custom': 'What\'s black and white and red all over?': 'A sunburnt panda'
        'placementAdvice':
          'displayHeight': 600
          'displayWidth': 800
          'presentationDocumentTarget': 'iframe'
        'mediaType': 'application/vnd.ims.lti.v1.ltilink'
        '@type': 'LtiLinkItem'
        '@id': 'https://lti-tool-provider-example.herokuapp.com/messages/blti'
        'canvasURL': '/courses/2/external_tools/retrieve?display=borderless&url=https%3A%2F%2Flti-tool-provider-example.herokuapp.com%2Fmessages%2Fblti'

      originalEnv = ENV

      ENV.SUBMIT_ASSIGNMENT = ALLOWED_EXTENSIONS: [
        'txt'
      ]

    teardown: ->
      $("#fixtures").html("")
      ENV = originalEnv

  test "correctly populates form values for LtiLinkItem", ->
    submitContentItem(contentItem)
    equal $("#external_tool_url").val(), url
    equal $("#external_tool_submission_type").val(), 'basic_lti_launch'

  test "correctly populates form values for FileItem", ->
    fileItem = contentItem
    fileItem['@type'] = 'FileItem'
    fileItem['@id'] = fileUrl
    fileItem.url = fileUrl
    submitContentItem(fileItem)
    equal $("#external_tool_url").val(), fileUrl
    equal $("#external_tool_submission_type").val(), "online_url_to_file"

  test "rejects unsupported file types", ->
    unsupportedItem = contentItem
    unsupportedItem['@type'] = 'FileItem'
    unsupportedItem.url = 'https://lti-tool-provider-example.herokuapp.com/test_file.jpg'

    result = submitContentItem(unsupportedItem)
    equal result, false

  test "accepts supported file types", ->
    supportedItem = contentItem
    supportedItem['@type'] = 'FileItem'
    supportedItem.url = fileUrl

    result = submitContentItem(supportedItem)
    equal result, true

  test "correctly populates form values for FileItem", ->
    unsupportedItem = contentItem
    unsupportedItem['@type'] = 'UnsupportedType'
    result = submitContentItem(unsupportedItem)
    equal result, false

  test "returns false if not given an item", ->
    result = submitContentItem(undefined)
    equal result, false

  test "Sets the input value to the current time if checked is true", ->
    now = new Date();
    clock = sinon.useFakeTimers(now.getTime());
    inputHtml = "<input type='checkbox' name='test' id='checkbox-test'></input>"
    $('#fixtures').append(inputHtml)
    input = document.querySelector('#checkbox-test')
    recordEulaAgreement(input, true)
    equal document.querySelector('#checkbox-test').value, now.getTime()
    clock.restore();
