#
# Copyright (C) 2015 - present Instructure, Inc.
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

define [
  'jquery'
  'underscore'
  'str/htmlEscape'
  'i18n!user_content'
], ($, _, htmlEscape, I18n) ->

  apiUserContent = {

    ###
    xsslint safeString.identifier mathml
    ###
    translateMathmlForScreenreaders: ($equationImage)->
      mathml = $("<div/>").html($equationImage.data("mathml")).html()
      mathmlSpan = $("<span class=\"hidden-readable\"></span>")
      mathmlSpan.html(mathml)
      return mathmlSpan

    toMediaCommentLink: (node)->
      $link = $("<a id='media_comment_#{htmlEscape($(node).data('media_comment_id'))}'
            data-media_comment_type='#{htmlEscape($(node).data('media_comment_type'))}'
            class='instructure_inline_media_comment #{htmlEscape(node.nodeName.toLowerCase())}_comment' />")
      $link.html $(node).html()
      return $link

    ###
    xsslint safeString.identifier mathmlSpan
    ###
    # use this method to process any user content fields returned in api responses
    # this is important to handle object/embed tags safely, and to properly display audio/video tags
    convert: (html, options = {}) ->
      $dummy = $('<div />').html(html)
      # finds any <video/audio class="instructure_inline_media_comment"> and turns them into media comment thumbnails
      $dummy.find('video.instructure_inline_media_comment,audio.instructure_inline_media_comment').replaceWith ->
        apiUserContent.toMediaCommentLink(this)

      # remove any embed tags inside an object tag, to avoid repeated translations
      $dummy.find('object.instructure_user_content embed').remove()

      # if we aren't actually displaying this content but are instead putting
      # it into a RTE, we want to preserve the object/embed tags
      unless options.forEditing
        # find all object/embed tags and convert them into an iframe that posts
        # to safefiles to display the content (to avoid javascript attacks)
        #
        # see the corresponding code in lib/user_content.rb for non-api user
        # content handling
        $dummy.find('object.instructure_user_content,embed.instructure_user_content').replaceWith ->
          $this = $(this)
          if !$this.data('uc_snippet') || !$this.data('uc_sig')
            return this

          uuid = _.uniqueId("uc_")
          action = "/object_snippet"
          action = "//#{ENV.files_domain}#{action}" if ENV.files_domain
          $form = $("<form action='#{htmlEscape(action)}' method='post' class='user_content_post_form' target='#{htmlEscape(uuid)}' id='form-#{htmlEscape(uuid)}' />")
          $form.append($("<input type='hidden'/>").attr({name: 'object_data', value: $this.data('uc_snippet')}))
          $form.append($("<input type='hidden'/>").attr({name: 's', value: $this.data('uc_sig')}))
          $('body').append($form)
          setTimeout((-> $form.submit()), 0)
          $("<iframe class='user_content_iframe' name='#{htmlEscape(uuid)}' style='width: #{htmlEscape($this.data('uc_width'))}; height: #{htmlEscape($this.data('uc_height'))};' frameborder='0' title='#{htmlEscape(I18n.t 'User Content')}' />")

        $dummy.find('img.equation_image').each((index, equationImage)->
          $equationImage = $(equationImage)
          mathmlSpan = apiUserContent.translateMathmlForScreenreaders($equationImage)
          $equationImage.removeAttr('data-mathml')
          $equationImage.after(mathmlSpan)
        )
      $dummy.html()
  }

  return apiUserContent
