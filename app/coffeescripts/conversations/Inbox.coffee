#
# Copyright (C) 2012 Instructure, Inc.
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
#

define [
  'i18n!conversations'
  'underscore'
  'str/htmlEscape'
  'compiled/conversations/introSlideshow'
  'compiled/conversations/ConversationsPane'
  'compiled/conversations/audienceList'
  'compiled/conversations/contextList'
  'compiled/widget/TokenInput'
  'compiled/str/TextHelper'
  'jquery.ajaxJSON'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
  'jqueryui/dialog'
  'jquery.instructure_misc_helpers'
  'jquery.disableWhileLoading'
  'jquery.rails_flash_notifications'
  'media_comments'
  'vendor/jquery.ba-hashchange'
  'vendor/jquery.elastic'
  'jqueryui/position'
], (I18n, _, h, introSlideshow, ConversationsPane, audienceList, contextList, TokenInput, TextHelper) ->

  class
    constructor: (@options) ->
      @currentUser = @options.USER
      @contexts    = @options.CONTEXTS
      @userCache   = {}
      @userCache[@currentUser.id] = @currentUser
      $ @render

    render: =>
      @$inbox = $('#inbox')
      @minHeight = parseInt @$inbox.css('min-height').replace('px', '')
      @$conversations = $('#conversations')
      @$messages = $('#messages')
      @$messageList = @$messages.find('ul.messages')
      @initializeHelp()
      @initializeForms()
      @initializeMenus()
      @initializeMessageActions()
      @initializeConversationActions()
      @initializeTemplates()
      @initializeTokenInputs()
      @initializeConversationsPane()
      @initializeAutoResize()
      @initializeHashChange()
      if @options.SHOW_INTRO
        introSlideshow()

    showMessageForm: ->
      conversation = @conversations.active()
      newMessage = !conversation?
      @$form.find('#recipient_info').showIf newMessage
      @$form.find('#group_conversation_info').hide()
      $('#action_compose_message').toggleClass 'active', newMessage

      if newMessage
        @$form.addClass('new')
        @$form.find('#action_add_recipients').hide()
        @$form.attr action: '/conversations?' + $.param(@conversations?.baseData() ? {})
      else
        @$form.removeClass('new')
        @$form.find('#action_add_recipients').showIf(!conversation.get('private'))
        @$form.attr action: conversation.url('add_message')

      @resetMessageForm()
      @$form.find('#user_note_info').hide().find('input').attr('checked', false)
      @$form.show().find(':input:visible:first').focus()

    resetMessageForm: (resetFields = true) ->
      @$form.find('.audience').html(if c = @conversations.active()
          @htmlAudience(c.attributes, linkToContexts: true, highlightFilters: true)
        else
          h(I18n.t('headings.new_message', 'New Message'))
      )
      if resetFields
        @$form.find('input[name!=authenticity_token], textarea').not(":checkbox").val('').change()
        @$form.find(".attachment:visible").remove()
        @$form.find(".media_comment").hide()
        @$form.find("#action_media_comment").show()
      @resize()

    filters: ->
      @conversations.baseData().filter ? []

    htmlAudience: (conversation, options = {}) ->
      filters = options.filters = if options.highlightFilters then @filters() else []
      audience = for id in conversation.audience
        {
          id: id
          name: @userCache[id].name
          activeFilter: _.include(filters, "user_#{id}")
        }

      ret = audienceList(audience, options)
      if audience.length
        ret += " <em>" + @htmlContextList(conversation.audience_contexts, options) + "</em>"
      ret

    htmlContextList: (contexts, options = {}) ->
      filters = options.filters ? []
      contexts = (course for id, roles of contexts.courses when course = @contexts.courses[id]).
           concat(group for id, roles of contexts.groups when group = @contexts.groups[id])
      contexts = for context in contexts
        context = _.clone(context)
        context.activeFilter = _.include(filters, "#{context.type}_#{context.id}")
        context
      contextList(contexts, options)

    htmlNameForUser: (user, contexts = {courses: user.common_courses, groups: user.common_groups}) ->
      h(user.name) + if contexts.courses?.length or contexts.groups?.length then " <em>" + @htmlContextList(contexts) + "</em>" else ''

    canAddNotesFor: (user) ->
      return false unless @options.NOTES_ENABLED
      return true if user.can_add_notes
      for id, roles of user.common_courses
        return true if 'StudentEnrollment' in roles and (@options.CAN_ADD_NOTES_FOR_ACCOUNT or @contexts.courses[id]?.can_add_notes)
      false

    loadConversation: (conversation, $node, cb) ->
      @toggleMessageActions(off)
      @$messageList.removeClass('private').hide().html ''
      @$messageList.addClass('private') if $conversation?.hasClass('private')
      @showMessageForm()

      params = @currentHashData()
      @$form.find('#body').val(params.message) if params.message
      unless conversation?
        if params.user_id
          $('#from_conversation_id').val(params.from_conversation_id)
          $('#recipients').data('token_input').selector.addByUserId(params.user_id, params.from_conversation_id)
        return cb()

      url = conversation.url()
      @$messageList.show().disableWhileLoading $.ajaxJSON url, 'GET', {}, (data) =>
        @conversations.updateItems [data]
        return unless @conversations.isActive(data.id)
        for user in data.participants when !@userCache[user.id]?.avatar_url
          @userCache[user.id] = user
          user.htmlName = @htmlNameForUser(user)
        if data['private'] and user = (user for user in data.participants when user.id isnt @currentUser.id)[0] and @canAddNotesFor(user)
          @$form.find('#user_note_info').show()
        @resize()
        @$messages.show()
        @$messageList.append @buildMessage(message) for message in data.messages
        @$messageList.show()
        cb()

    deselectMessages: ->
      @$messageList.find('li.selected').removeClass 'selected'

    addMessage: (message) ->
      @toggleMessageActions(off)
      @buildMessage(message).prependTo(@$messageList).slideDown 'fast'

    buildMessage: (data) ->
      return @buildSubmission(data) if data.submission
      $message = $("#message_blank").clone(true).attr('id', 'message_' + data.id)
      $message.data('id', data.id)
      $message.addClass(if data.generated
        'generated'
      else if data.author_id is @currentUser.id
        'self'
      else
        'other'
      )
      $message.addClass('forwardable')
      user = @userCache[data.author_id]
      if avatar = user?.avatar_url
        $message.prepend $('<img />').attr('src', avatar).addClass('avatar')
      user.htmlName ?= @htmlNameForUser(user) if user
      userName = user?.name ? I18n.t('unknown_user', 'Unknown user')
      $message.find('.audience').html user?.htmlName || h(userName)
      $message.find('span.date').text $.parseFromISO(data.created_at).datetime_formatted
      $message.find('p').html TextHelper.formatMessage(data.body)
      $message.find("a.show_quoted_text_link").click (e) =>
        $target = $(e.currentTarget)
        $text = $target.parents(".quoted_text_holder").children(".quoted_text")
        if $text.length
          event.stopPropagation()
          event.preventDefault()
          $text.show()
          $target.hide()
      $pmAction = $message.find('a.send_private_message')
      pmUrl = $.replaceTags $pmAction.attr('href'),
        user_id: data.author_id
        user_name: encodeURIComponent(userName)
        from_conversation_id: @conversations.active?().id
      $pmAction.attr('href', pmUrl).click (e) =>
        e.stopPropagation()
      if data.forwarded_messages?.length
        $ul = $('<ul class="messages"></ul>')
        for submessage in data.forwarded_messages
          $ul.append @buildMessage(submessage)
        $message.append $ul

      $ul = $message.find('ul.message_attachments').first().detach()
      $mediaObjectBlank = $ul.find('.media_object_blank').detach()
      $attachmentBlank = $ul.find('.attachment_blank').detach()
      if data.media_comment? or data.attachments?.length
        $message.append $ul
        if data.media_comment?
          $ul.append @buildMediaObject($mediaObjectBlank, data.media_comment)
        if data.attachments?
          for attachment in data.attachments
            $ul.append @buildAttachment($attachmentBlank, attachment)

      $message

    buildMediaObject: (blank, data) ->
      $mediaObject = blank.clone(true).attr('id', 'media_comment_' + data.media_id)
      $mediaObject.find('span.title').html h(data.display_name)
      $mediaObject.find('span.media_comment_id').html h(data.media_id)
      $mediaObject.find('.instructure_inline_media_comment').data('media_comment_type', data.media_type)
      $mediaObject

    buildAttachment: (blank, data) ->
      $attachment = blank.clone(true).attr('id', 'attachment_' + data.id)
      $attachment.data('id', data.id)
      $attachment.find('span.title').html h(data.display_name)
      $link = $attachment.find('a')
      $link.attr('href', data.url)
      $link.click (e) =>
        e.stopPropagation()
      $attachment

    buildSubmission: (data) ->
      $submission = $("#submission_blank").clone(true).attr('id', data.id)
      $submission.data('id', data.id)
      data = data.submission
      $ul = $submission.find('ul')
      $header = $ul.find('li.header')
      href = $.replaceTags($header.find('a').attr('href'), course_id: data.assignment.course_id, assignment_id: data.assignment_id, id: data.user_id)
      $header.find('a').attr('href', href)
      user = @userCache[data.user_id]
      user.htmlName ?= @htmlNameForUser(user) if user
      userName = user?.name ? I18n.t('unknown_user', 'Unknown user')
      $header.find('.title').html h(data.assignment.name)
      $header.find('span.date').text(if data.submitted_at
        $.parseFromISO(data.submitted_at).datetime_formatted
      else
        I18n.t('not_applicable', 'N/A')
      )
      $header.find('.audience').html user?.htmlName || h(userName)
      if data.score && data.assignment.points_possible
        score = "#{data.score} / #{data.assignment.points_possible}"
      else
        score = data.score ? I18n.t('not_scored', 'no score')
      $header.find('.score').html(score)
      $commentBlank = $ul.find('.comment').detach()
      index = 0
      initiallyShown = 4
      for idx in [data.submission_comments.length - 1 .. 0] by -1
        comment = data.submission_comments[idx]
        break if index >= 10
        index++
        $comment = @buildSubmissionComment($commentBlank, comment)
        $comment.hide() if index > initiallyShown
        $ul.append $comment
      $moreLink = $ul.find('.more').detach()
      # the submission response isn't yet paginating/limiting the number of
      # comments returned, but we don't want to display more than 10 here, so we
      # artificially limit it.
      if index > initiallyShown
        $inlineMore = $moreLink.clone(true)
        $inlineMore.find('.hidden').text(index - initiallyShown)
        $inlineMore.attr('title', h(I18n.t('titles.expand_inline', "Show more comments")))
        $inlineMore.click (e) =>
          $target = $(e.currentTarget)
          $submission = $target.closest('.submission')
          $submission.find('.more:hidden').show()
          $target.hide()
          $submission.find('.comment:hidden').slideDown('fast')
          @resize()
          return false
        $ul.append $inlineMore
      if data.submission_comments.length > index
        $moreLink.find('a').attr('href', href).attr('target', '_blank')
        $moreLink.find('.hidden').text(data.submission_comments.length - index)
        $moreLink.attr('title', h(I18n.t('titles.view_submission', "Open submission in new window.")))
        $moreLink.hide() if data.submission_comments.length > initiallyShown
        $ul.append $moreLink
      $submission

    buildSubmissionComment: (blank, data) ->
      $comment = blank.clone(true)
      user = @userCache[data.author_id]
      if avatar = user?.avatar_url
        $comment.prepend $('<img />').attr('src', avatar).addClass('avatar')
      user.htmlName ?= @htmlNameForUser(user) if user
      userName = user?.name ? I18n.t('unknown_user', 'Unknown user')
      $comment.find('.audience').html user?.htmlName || h(userName)
      $comment.find('span.date').text $.parseFromISO(data.created_at).datetime_formatted
      $comment.find('p').html h(data.comment).replace(/\n/g, '<br />')
      $comment

    closeMenus: () ->
      $('#actions .menus > li, #conversation_actions, #conversations .actions').removeClass('selected')
      $('#conversations li.menu_active').removeClass('menu_active')

    openMenu: ($menu) ->
      @closeMenus()
      unless $menu.hasClass('disabled')
        $div = $menu.parent('li, span').addClass('selected').find('div')
        # TODO: move this out in the DOM so we can center it and not have it get clipped
        offset = -($div.parent().position().left + $div.parent().outerWidth() / 2) + 6 # for box shadow
        offset = -($div.outerWidth() / 2) if offset < -($div.outerWidth() / 2)
        $div.css 'margin-left', offset + 'px'

    resize: (delay=0) ->
      clearTimeout @resizeCb if @resizeCb
      @resizeCb = setTimeout =>
        delete @resizeCb
        availableHeight = $(window).height() - $('#header').outerHeight(true) - ($('#wrapper-container').outerHeight(true) - $('#wrapper-container').height()) - ($('#main').outerHeight(true) - $('#main').height()) - $('#breadcrumbs').outerHeight(true) - $('#footer').outerHeight(true)
        availableHeight = @minHeight if availableHeight < @minHeight
        $(document.body).toggleClass('too_small', availableHeight <= @minHeight)
        @$inbox.height(availableHeight)
        @$messageList.height(availableHeight - @$form.outerHeight(true))
        @conversations.resize(availableHeight)
      , delay

    toggleMessageActions: (state) ->
      if state?
        @$messageList.find('> li').removeClass('selected')
        @$messageList.find('> li :checkbox').attr('checked', false)
      else
        state = !!@$messageList.find('li.selected').length
      $('#action_forward').parent().showIf(state and @$messageList.find('li.selected.forwardable').length)
      if state then $("#message_actions").slideDown(100) else $("#message_actions").slideUp(100)
      @$form[if state then 'addClass' else 'removeClass']('disabled')

    updateHashData: (changes) ->
      data = $.extend(@currentHashData(), changes)
      hash = $.encodeToHex(JSON.stringify(data))
      if hash isnt location.hash.substring(1)
        location.hash = hash
        $(document).triggerHandler('document_fragment_change', hash)

    initializeHelp: ->
      $('#help_crumb').click (e) =>
        e.preventDefault()
        introSlideshow()

    initializeForms: ->
      $('#create_message_form, #forward_message_form').find('textarea').elastic().keypress (e) =>
        if e.which is 13 and e.shiftKey
          e.preventDefault()
          $(e.target).closest('form').submit()
          false

      @$form = $('#create_message_form')
      @$addForm = $('#add_recipients_form')
      @$forwardForm = $('#forward_message_form')

      @$form.submit (e) =>
        valid = !!(@$form.find('#body').val() and (@$form.find('#recipient_info').filter(':visible').length is 0 or @$form.find('.token_input li').length > 0))
        e.stopImmediatePropagation() unless valid
        valid
      @$form.formSubmit
        fileUpload: =>
          return @$form.find(".file_input:visible").length > 0
        preparedFileUpload: true
        context_code: "user_" + $("#identity .user_id").text()
        folder_id: @options.FOLDER_ID
        intent: 'message'
        formDataTarget: 'url'
        handle_files: (attachments, data) ->
          data.attachment_ids = (a.attachment.id for a in attachments)
          data
        disableWhileLoading: true
        success: (data) =>
          data = [data] unless data.length?
          @conversations.updateItems data
          if data.length == 1
            conversation = data[0]
            if @conversations.isActive(conversation.id)
              @buildMessage(conversation.messages[0]).prependTo(@$messageList).slideDown 'fast'
            if conversation.visible
              @updateHashData id: conversation.id
            $.flashMessage I18n.t('message_sent', 'Message Sent')
          else
            $.flashMessage I18n.t('messages_sent', 'Messages Sent')
          @resetMessageForm()
        error: (data) =>
          return if data.isRejected?() # e.g. refreshed the page, thus aborting the request
          error = data[0]
          if error?.attribute is 'body'
            @$form.find('#body').errorBox I18n.t('message_blank_error', 'No message was specified')
          else
            errorText = (if error?.attribute is 'recipients'
              if error.message is 'blank'
                I18n.t('recipient_blank_error', 'No recipients were specified')
              else
                I18n.t('recipient_error', 'The course or group you have selected has no valid recipients')
            else
              I18n.t('unspecified_error', 'An unexpected error occurred, please try again')
            )
            @$form.find('.token_input').errorBox(errorText)
          $('.error_box').filter(':visible').css('z-index', 10) # TODO: figure out why this is necessary
      @$form.click =>
        @toggleMessageActions off

      @$addForm.submit (e) =>
        valid = !!(@$addForm.find('.token_input li').length)
        e.stopImmediatePropagation() unless valid
        valid
      @$addForm.formSubmit
        disableWhileLoading: true,
        success: (data) =>
          @buildMessage(data.messages[0]).prependTo(@$messageList).slideDown 'fast'
          @conversations.updateItems [data]
          @resetMessageForm()
          @$addForm.dialog('close')
        error: (data) =>
          @$addForm.dialog('close')

      @$forwardForm.submit (e) =>
        valid = !!(@$forwardForm.find('#forward_body').val() and @$forwardForm.find('.token_input li').length)
        e.stopImmediatePropagation() unless valid
        valid
      @$forwardForm.formSubmit
        disableWhileLoading: true,
        success: (data) =>
          conversation = data[0]
          @conversations.updateItems [conversation]
          @updateHashData id: conversation.id
          @resetMessageForm()
          @$forwardForm.dialog('close')
        error: (data) =>
          @$forwardForm.dialog('close')


      @$messageList.click (e) =>
        if $(e.target).closest('a.instructure_inline_media_comment').length
          # a.instructure_inline_media_comment clicks have to propagate to the
          # top due to "live" handling; if it's one of those, it's not really
          # intended for us, just let it go
        else
          $message = $(e.target).closest('#messages > ul > li')
          unless $message.hasClass('generated')
            $message.toggleClass('selected')
            $message.find('> :checkbox').attr('checked', $message.hasClass('selected'))
          @toggleMessageActions()

    initializeMenus: =>
      $('.menus > li > a').click (e) =>
        e.preventDefault(e)
        @openMenu $(e.currentTarget)
      .focus (e) =>
        @openMenu $(e.currentTarget)

      $(document).bind 'mousedown', (e) =>
        unless $(e.target).closest("span.others").find('> span').length
          $('span.others > span').hide()
        @closeMenus() unless $(e.target).closest(".menus > li, #conversation_actions, #conversations .actions").length

      @$menuViews = $('#menu_views')
      @$menuViewsList = @$menuViews.parent()
      @$menuViewsList.find('li a').click (e) =>
        @closeMenus()
        if scope = $(e.target).closest('li').data('scope')
          e.preventDefault()
          @updateHashData scope: scope

      $('#conversations ul, #create_message_form').delegate '.audience', 'click', (e) =>
        if ($others = $(e.target).closest('span.others').find('> span')).length
          if not $(e.target).closest('span.others > span').length
            $('span.others > span').not($others).hide()
            $others.toggle()
            $others.css('left', $others.parent().position().left)
            $others.css('top', $others.parent().height() + $others.parent().position().top)
          return false

    setScope: (scope) ->
      $items = @$menuViewsList.find('li')
      $items.removeClass('checked')
      $item = $items.filter("[data-scope=#{scope}]")
      $item = $items.filter("[data-scope=inbox]") unless $item.length
      $item.addClass('checked')
      @$menuViews.text $item.text()

    initializeMessageActions: ->
      $('#message_actions').find('a').click (e) =>
        e.preventDefault()

      $('#cancel_bulk_message_action').click =>
        @toggleMessageActions off

      $('#action_delete').click (e) =>
        active = @conversations.active()
        return unless active?
        $selectedMessages = @$messageList.find('.selected')
        message = if $selectedMessages.length > 1
          I18n.t('confirm.delete_messages', "Are you sure you want to delete your copy of these messages? This action cannot be undone.")
        else
          I18n.t('confirm.delete_message', "Are you sure you want to delete your copy of this message? This action cannot be undone.")
        if confirm message
          $selectedMessages.fadeOut 'fast'
          @conversations.action $(e.currentTarget),
            conversationId: active.id
            data: {remove: ($(message).data('id') for message in $selectedMessages)}
            success: => @toggleMessageActions(off)
            error: => $selectedMessages.show()

      $('#action_forward').click (e) =>
        return unless @conversations.active()?
        @$forwardForm.find("input[name!=authenticity_token], textarea").val('').change()
        $preview = @$forwardForm.find('ul.messages').first()
        $preview.html('')
        $preview.html(@$messageList.find('> li.selected.forwardable').clone(true).removeAttr('id').removeClass('self'))
        $preview.find('> li')
          .removeClass('selected odd')
          .find('> :checkbox')
          .attr('checked', true)
          .attr('name', 'forwarded_message_ids[]')
          .val ->
            $(this).closest('li').data('id')
        $preview.find('> li').last().addClass('last')
        @$forwardForm.css('max-height', ($(window).height() - 300) + 'px')
        .dialog('close').dialog
          position: 'center'
          height: 'auto'
          width: 510
          title: I18n.t('title.forward_messages', 'Forward Messages')
          buttons: [
            text: I18n.t('#buttons.cancel', 'Cancel')
            click: -> $(this).dialog('close')
          ,
            text: I18n.t('buttons.send_message', 'Send')
            click: -> $(this).submit()
            class: 'btn-primary'
          ]
          open: =>
            @$forwardForm.attr action: '/conversations?' + $.param(@conversations.baseData())
          close: =>
            $('#forward_recipients').data('token_input').$input.blur()


    initializeConversationActions: ->
      $('#action_compose_message').click (e) =>
        e.preventDefault()
        @updateHashData id: null

      $('#action_add_recipients').click (e) =>
        e.preventDefault()
        return unless @conversations.active()?
        @$addForm
          .attr('action', @conversations.actionUrlFor($(e.currentTarget)))
          .dialog('close').dialog
            width: 420
            title: I18n.t('title.add_recipients', 'Add Recipients')
            buttons: [
              {
                text: I18n.t('buttons.add_people', 'Add People')
                click: => @$addForm.submit()
              }
              {
                text: I18n.t('#buttons.cancel', 'Cancel')
                click: => @$addForm.dialog('close')
              }
            ]
            open: =>
              tokenInput = $('#add_recipients').data('token_input')
              tokenInput.baseExclude = @conversations.active().get('audience')
              @$addForm.find("input[name!=authenticity_token]").val('').change()
            close: =>
              $('#add_recipients').data('token_input').$input.blur()

    initializeTemplates: ->
      nextAttachmentIndex = 0
      $('#action_add_attachment').click (e) =>
        e.preventDefault()
        $attachment = $("#attachment_blank").clone(true)
        $attachment.attr('id', null)
        $attachment.find("input[type='file']").attr('name', 'attachments[' + (nextAttachmentIndex++) + ']')
        $('#attachment_list').append($attachment)
        $attachment.slideDown "fast", =>
          @resize()
        return false

      $("#attachment_blank a.remove_link").click (e) =>
        e.preventDefault()
        $attachment = $(e.currentTarget).closest(".attachment")
        $attachment.slideUp "fast", =>
          @resize()
          $attachment.remove()
        return false

      $('#action_media_comment').click (e) =>
        e.preventDefault()
        $("#create_message_form .media_comment").mediaComment 'create', 'any', (id, type) =>
          $("#media_comment_id").val(id)
          $("#media_comment_type").val(type)
          $("#create_message_form .media_comment").show()
          $("#action_media_comment").hide()

      $('#create_message_form .media_comment a.remove_link').click (e) =>
        e.preventDefault()
        $("#media_comment_id").val('')
        $("#media_comment_type").val('')
        $("#create_message_form .media_comment").hide()
        $("#action_media_comment").show()

    buildContextInfo: (data) ->
      match = data.id.match(/^(course|section)_(\d+)$/)
      termInfo = @contexts["#{match[1]}s"][match[2]] if match

      contextInfo = data.context_name or ''
      contextInfo = if contextInfo.length < 40 then contextInfo else contextInfo.substr(0, 40) + '...'
      if termInfo?.term
        contextInfo = if contextInfo
          "#{contextInfo} - #{termInfo.term}"
        else
          termInfo.term

      if contextInfo
        $('<span />', class: 'context_info').text("(#{contextInfo})")
      else
        ''
    initializeTokenInputs: ->
      buildPopulator = (pOptions={}) =>
        (selector, $node, data, options={}) =>
          data.id = "#{data.id}"
          if data.avatar_url
            $img = $('<img class="avatar" />')
            $img.attr('src', data.avatar_url)
            $node.append($img)
          $b = $('<b />')
          $b.text(data.name)
          $name = $('<span />', class: 'name')
          $contextInfo = @buildContextInfo(data) unless options.parent
          $name.append($b, $contextInfo)
          $span = $('<span />', class: 'details')
          if data.common_courses?
            $span.html(@htmlContextList({courses: data.common_courses, groups: data.common_groups}, hardCutoff: 2))
          else if data.type and data.user_count?
            $span.text(I18n.t('people_count', 'person', {count: data.user_count}))
          else if data.item_count?
            if data.id.match(/_groups$/)
              $span.text(I18n.t('groups_count', 'group', {count: data.item_count}))
            else if data.id.match(/_sections$/)
              $span.text(I18n.t('sections_count', 'section', {count: data.item_count}))
          else if data.subText
            $span.text(data.subText)
          $node.append($name, $span)
          $node.attr('title', data.name)
          text = data.name
          if options.parent
            if data.selectAll and data.noExpand # "Select All", e.g. course_123_all -> "Spanish 101: Everyone"
              text = options.parent.data('text')
            else if data.id.match(/_\d+_/) # e.g. course_123_teachers -> "Spanish 101: Teachers"
              text = I18n.beforeLabel(options.parent.data('text')) + " " + text
          $node.data('text', text)
          $node.data('id', if data.type is 'context' or not pOptions.prefixUserIds then data.id else "user_#{data.id}")
          data.rootId = options.ancestors[0]
          $node.data('user_data', data)
          $node.addClass(if data.type then data.type else 'user')
          if options.level > 0 and selector.options.showToggles
            $node.prepend('<a class="toggle"><i></i></a>')
            $node.addClass('toggleable') unless data.item_count # can't toggle certain synthetic contexts, e.g. "Student Groups"
          if data.type == 'context' and not data.noExpand
            $node.prepend('<a class="expand"><i></i></a>')
            $node.addClass('expandable')

      placeholderText =  I18n.t('recipient_field_placeholder', "Enter a name, course, or group")
      noResultsText = I18n.t('no_results', 'No results found')
      everyoneText  = I18n.t('enrollments_everyone', "Everyone")
      selectAllText = I18n.t('select_all', "Select All")

      $('.recipients').tokenInput
        placeholder: placeholderText
        added: (data, $token, newToken) =>
          data.id = "#{data.id}"
          if newToken and data.rootId
            $token.append("<input type='hidden' name='tags[]' value='#{data.rootId}'>")
          if newToken and data.type
            $token.addClass(data.type)
            if data.user_count?
              $token.addClass('details')
              $details = $('<span />')
              $details.text(I18n.t('people_count', 'person', {count: data.user_count}))
              $token.append($details)
          unless data.id.match(/^(course|group)_/)
            data = $.extend({}, data)
            delete data.avatar_url # since it's the wrong size and possibly a blank image
            currentData = @userCache[data.id] ? {}
            @userCache[data.id] = $.extend(currentData, data)
        selector:
          messages: {noResults: noResultsText}
          populator: buildPopulator()
          limiter: (options) =>
            if options.level > 0 then -1 else 5
          showToggles: true
          preparer: (postData, data, parent) =>
            context = postData.context
            if not postData.search and context and data.length > 1
              if context.match(/^(course|section)_\d+$/)
                # i.e. we are listing synthetic contexts under a course or section
                data.unshift
                  id: "#{context}_all"
                  name: everyoneText
                  user_count: parent.data('user_data').user_count
                  type: 'context'
                  avatar_url: parent.data('user_data').avatar_url
                  selectAll: true
              else if context.match(/^((course|section)_\d+_.*|group_\d+)$/) and not context.match(/^course_\d+_(groups|sections)$/)
                # i.e. we are listing all users in a group or synthetic context
                data.unshift
                  id: context
                  name: selectAllText
                  user_count: parent.data('user_data').user_count
                  type: 'context'
                  avatar_url: parent.data('user_data').avatar_url
                  selectAll: true
                  noExpand: true # just a magic select-all checkbox, you can't drill into it
          baseData:
            synthetic_contexts: 1
          browser:
            data:
              per_page: -1
              type: 'context'

      tokenInput = $('#recipients').data('token_input')
      # since it doesn't infer percentage widths, just whatever the current pixels are
      tokenInput.$fakeInput.css('width', '100%')
      tokenInput.change = (tokens) =>
        if tokens.length > 1 or tokens[0]?.match(/^(course|group)_/)
          @$form.find('#group_conversation').attr('checked', false) if !@$form.find('#group_conversation_info').is(':visible')
          @$form.find('#group_conversation_info').show()
          @$form.find('#user_note_info').hide()
        else
          @$form.find('#group_conversation').attr('checked', false)
          @$form.find('#group_conversation_info').hide()
          @$form.find('#user_note_info').showIf((user = @userCache[tokens[0]]) and @canAddNotesFor(user))
        @resize()

      @filterNameMap = {}
      $('#context_tags').tokenInput
        placeholder: placeholderText
        added: (data, $token, newToken) =>
          $token.prevAll().remove()
        tokenWrapBuffer: 80
        selector:
          messages: {noResults: noResultsText}
          populator: buildPopulator(prefixUserIds: true)
          limiter: (options) => 5
          preparer: (postData, data, parent) =>
            context = postData.context
            if not postData.search and context and data.length > 0 and context.match(/^(course|group)_\d+$/)
              if data.length > 1 and context.match(/^course_/)
                data.unshift
                  id: "#{context}_all"
                  name: everyoneText
                  user_count: parent.data('user_data').user_count
                  type: 'context'
                  avatar_url: parent.data('user_data').avatar_url
              filterText = if context.match(/^course/)
                I18n.t('filter_by_course', 'Fiter by this course')
              else
                I18n.t('filter_by_group', 'Fiter by this group')
              data.unshift
                id: context
                name: parent.data('text')
                type: 'context'
                avatar_url: parent.data('user_data').avatar_url
                subText: filterText
                noExpand: true
          baseData:
            synthetic_contexts: 1
            types: ['course', 'user', 'group']
            include_inactive: true
          browser:
            data:
              per_page: -1
              types: ['context']
      filterInput = $('#context_tags').data('token_input')
      filterInput.change = (tokenValues) =>
        filters = for pair in filterInput.tokenPairs()
          @filterNameMap[pair[0]] = pair[1]
          pair[0]
        @updateHashData filter: filters

    initializeConversationsPane: () ->
      @conversations = new ConversationsPane this, @$conversations

    initializeAutoResize: ->
      $(window).resize => @resize(50)
      @resize()

    currentHashData: ->
      try
        data = $.parseJSON($.decodeFromHex(location.hash.substring(1))) || {}
      catch e
        data = {}
      data

    initializeHashChange: ->
      $(window).bind 'hashchange', =>
        hash = location.hash
        data = @currentHashData()
        if data.filter
          data.filter = (id for id in data.filter when @filterNameMap[id])
          return @updateHashData(filter: null) if not data.filter.length
        @setScope(data.scope)
        @conversations.updateView(data)
      .triggerHandler('hashchange')
