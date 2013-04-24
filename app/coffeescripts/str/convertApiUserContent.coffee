define [
  'jquery'
  'underscore'
], ($, _) ->

  # use this method to process any user content fields returned in api responses
  # this is important to handle object/embed tags safely, and to properly display audio/video tags
  convertApiUserContent = (html, options = {}) ->
    $dummy = $('<div />').html(html)
    # finds any <video/audio class="instructure_inline_media_comment"> and turns them into media comment thumbnails
    $dummy.find('video.instructure_inline_media_comment,audio.instructure_inline_media_comment').replaceWith ->
      $node = $("<a id='media_comment_#{$(this).data('media_comment_id')}'
            data-media_comment_type='#{$(this).data('media_comment_type')}'
            class='instructure_inline_media_comment #{this.nodeName.toLowerCase()}_comment' />")
      $node.html $(this).html()
      $node

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
        $form = $("<form action='#{action}' method='post' class='user_content_post_form' target='#{uuid}' id='form-#{uuid}' />")
        $form.append($("<input type='hidden'/>").attr({name: 'object_data', value: $this.data('uc_snippet')}))
        $form.append($("<input type='hidden'/>").attr({name: 's', value: $this.data('uc_sig')}))
        $('body').append($form)
        setTimeout((-> $form.submit()), 0)
        $("<iframe class='user_content_iframe' name='#{uuid}' style='width: #{$this.data('uc_width')}; height: #{$this.data('uc_height')};' frameborder='0' />")

    $dummy.html()
