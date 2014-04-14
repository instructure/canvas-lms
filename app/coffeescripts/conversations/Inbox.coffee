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
  'jquery'
  'underscore'
  'str/htmlEscape'
  'compiled/conversations/introSlideshow'
  'compiled/conversations/ConversationsPane'
  'compiled/conversations/MessageFormPane'
  'compiled/conversations/audienceList'
  'compiled/util/contextList'
  'compiled/widget/ContextSearch'
  'compiled/str/TextHelper'
  'jst/_avatar'
  'jquery.ajaxJSON'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
  'jqueryui/dialog'
  'jquery.instructure_misc_helpers'
  'jquery.disableWhileLoading'
  'compiled/jquery.rails_flash_notifications'
  'compiled/jquery/offsetFrom'
  'media_comments'
  'vendor/jquery.ba-hashchange'
  'vendor/jquery.elastic'
  'jqueryui/position'
], (I18n, $, _, h, introSlideshow, ConversationsPane, MessageFormPane, audienceList, contextList, TokenInput, TextHelper, avatarPartial) ->

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
      @$others = $('<div class="others" id="others_popup" />')
      @initializeHelp()
      @initializeForms()
      @initializeMenus()
      @initializeMessageActions()
      @initializeTokenInputs()
      @initializeConversationsPane()
      @initializeMessageFormPane()
      @initializeAutoResize()
      @initializeHashChange()
      if @options.SHOW_INTRO
        introSlideshow()

    filters: ->
      @conversations.baseData().filter ? []

    htmlAudience: (conversation, options = {}) ->
      conversation ?= @conversations.active()?.attributes
      unless conversation?
        return h(I18n.t('headings.new_message', 'New Message'))

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
      contexts = {courses: _.keys(contexts.courses), groups: _.keys(contexts.groups)}
      contextList(contexts, @contexts, options)

    htmlNameForUser: (user, contexts = {courses: user.common_courses, groups: user.common_groups}) ->
      h(user.name) + if contexts.courses?.length or contexts.groups?.length then " <em>" + @htmlContextList(contexts) + "</em>" else ''

    canAddNotesFor: (userOrId) =>
      return false unless @options.NOTES_ENABLED
      user = if typeof userOrId is 'object' then userOrId else @userCache[userOrId]
      return false unless user?
      for id, roles of user.common_courses
        return true if 'StudentEnrollment' in roles and (@options.CAN_ADD_NOTES_FOR_ACCOUNT or @contexts.courses[id]?.permissions?.manage_user_notes)
      false

    loadConversation: (conversation, $node, cb) ->
      @$messageList.removeClass('private').hide().html ''
      @$messageList.addClass('private') if $conversation?.hasClass('private')

      @resetMessageForm(conversation)
      @toggleMessageActions(off)

      return cb() unless conversation?

      url = "#{conversation.url()}&include_beta=1"
      @$messageList.show().disableWhileLoading $.ajaxJSON url, 'GET', {}, (data) =>
        @conversations.updateItems [data]
        return unless @conversations.isActive(data.id)
        for user in data.participants when !@userCache[user.id]?.avatar_url
          @userCache[user.id] = user
          user.htmlName = @htmlNameForUser(user)
        if data['private'] and user = (user for user in data.participants when user.id isnt @currentUser.id)[0]
          @formPane.resetForParticipant(user)
        @resize()
        @$messages.show()
        @currentConversation = data
        @$messageList.append @buildMessage(message) for message in data.messages
        @$messageList.show()
        @formPane.form.setAuthor(data.messages, data.participants)
        cb()

    resetMessageForm: (conversation) ->
      $('#action_compose_message').toggleClass 'active', !conversation?
      baseData = @conversations.baseData()
      @formPane.reset(_.extend({}, @currentHashData(),
                       conversation: conversation
                       audience: @htmlAudience(null, linkToContexts: true, highlightFilters: true)
                       addRecipientsEnabled: conversation? and !conversation.get('private')
                       mediaCommentsEnabled: @options.MEDIA_COMMENTS_ENABLED
                       filter: baseData.filter
                       scope: baseData.scope
                    ))

    updatedConversation: (data) ->
      @formPane.refresh @htmlAudience(null, linkToContexts: true, highlightFilters: true)
      return unless data.length

      @conversations.updateItems data
      if data.length is 1
        conversation = data[0]
        if @conversations.isActive(conversation.id)
          @buildMessage(conversation.messages[0]).prependTo(@$messageList).slideDown 'fast'
        if conversation.visible
          @updateHashData id: conversation.id

    deselectMessages: ->
      @$messageList.find('li.selected').removeClass 'selected'

    addMessage: (message) ->
      @toggleMessageActions(off)
      @buildMessage(message).prependTo(@$messageList).slideDown 'fast'

    UNKNOWN_USER_NAMES: [I18n.t('unknown_user', 'Unknown user'), h(I18n.t('unknown_user', 'Unknown user'))]
    # Returns [userName, htmlName]
    userNames: (user) ->
      return @UNKNOWN_USER_NAMES unless user
      user.htmlName ?= @htmlNameForUser(user)
      [user.name, user.htmlName]

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
      [userName, htmlName] = @userNames user
      $message.prepend avatarPartial avatar_url: user.avatar_url, display_name: userName if user
      $message.find('.audience').html htmlName
      $message.find('span.date').text $.datetimeString(data.created_at)
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
      $pmAction.on 'click', (e) =>
        e.preventDefault()
        e.stopPropagation()
        user = @userCache[data.author_id]
        # Click the "New Message" button and after a short delay,
        # add the clicked user's token to the input.
        $('#action_compose_message').trigger('click')
        clearTimeout @addUserTokenCb if @addUserTokenCb
        @addUserTokenCb = setTimeout =>
          delete @addUserTokenCb
          @formPane.form.addToken
            value: user.id
            text: user.name
            data: user
        ,
          100
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
      [userName, htmlName] = @userNames user
      $header.find('.title').html h(data.assignment.name)
      $header.find('span.date').text(if data.submitted_at
        $.datetimeString(data.submitted_at)
      else
        I18n.t('not_applicable', 'N/A')
      )
      $header.find('.audience').html htmlName
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
      [userName, htmlName] = @userNames user
      $comment.prepend avatarPartial avatar_url: user.avatar_url, display_name: userName if user
      $comment.find('.audience').html htmlName
      $comment.find('span.date').text $.datetimeString(data.created_at)
      $comment.find('p').html h(data.comment).replace(/\n/g, '<br />')
      $comment

    closeMenus: () ->
      $('#actions .menus > li, #conversation_actions, #conversations .actions').removeClass('selected')

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
        @$messageList.height(availableHeight - @formPane.height())
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
      @formPane.toggle(state)

    updateHashData: (changes) ->
      data = $.extend(@currentHashData(), changes)
      hash = $.encodeToHex(JSON.stringify(data))
      if hash isnt location.hash.substring(1)
        location.hash = hash
        $(document).triggerHandler('document_fragment_change', hash)

    initializeHelp: ->
      $('#conversations-intro-menu-item, #conversations-intro-btn').click (e) =>
        e.preventDefault()
        introSlideshow()

    prepareTextareas: ($nodes) ->
      $nodes.elastic()
      $nodes.keypress (e) =>
        if e.which is 13 and e.shiftKey
          $(e.target).closest('form').submit()
          false

    initializeForms: ->
      @$addForm = $('#add_recipients_form')
      @$forwardForm = $('#forward_message_form')
      @prepareTextareas(@$forwardForm.find('textarea'))

      @$addForm.submit (e) =>
        valid = !!(@$addForm.find('.token_input li').length)
        e.stopImmediatePropagation() unless valid
        valid
      @$addForm.formSubmit
        disableWhileLoading: true,
        success: (data) =>
          @updatedConversation(data)
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
          @updatedConversation(data)
          @$forwardForm.dialog('close')
        error: (data) =>
          @$forwardForm.dialog('close')


      @$messageList.click (e) =>
        if $(e.target).closest('a.instructure_inline_media_comment, .mejs-container').length
          # a.instructure_inline_media_comment clicks have to propagate to the
          # top due to "live" handling; if it's one of those, it's not really
          # intended for us, just let it go
          # also, dont catch clicks on mediaelementjs videos.  that is for play/pause
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
        unless $(e.target).closest("#others_popup").length
          @$others.hide()
        @closeMenus() unless $(e.target).closest(".menus > li, #conversation_actions, #conversations .actions").length

      @$menuViews = $('#menu_views')
      @$menuViewsList = @$menuViews.parent()
      @$menuViewsList.find('li a').click (e) =>
        @closeMenus()
        if scope = $(e.target).closest('li').data('scope')
          e.preventDefault()
          @updateHashData scope: scope

      $('#conversations ul, #create_message_form').on 'click', '.others', (e) =>
        $this = $(e.currentTarget)
        $container = $this.closest('li').offsetParent()
        offset = $this.offsetFrom($container)
        @$others.empty().append($this.find('> span').clone()).css
          left: offset.left
          top: offset.top + $this.height() + $container.scrollTop()
          fontSize: $this.css('fontSize')
        $container.append(@$others.show())
        return false # i.e. don't select conversation

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
        .dialog
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

      $('#action_compose_message').click (e) =>
        e.preventDefault()
        @updateHashData id: null

    addRecipients: ($node) ->
      return unless @conversations.active()?
      @$addForm
        .attr('action', $node.prop('href'))
        .dialog
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

    initializeTokenInputs: ($scope) ->
      everyoneText  = I18n.t('enrollments_everyone', "Everyone")
      selectAllText = I18n.t('select_all', "Select All")

      ($scope ? $(document)).find('.recipients').contextSearch
        contexts: @contexts
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
              $token.data('user_count', data.user_count)
          unless data.id.match(/^(course|group)_/)
            data = $.extend({}, data)
            delete data.avatar_url # since it's the wrong size and possibly a blank image
            currentData = @userCache[data.id] ? {}
            @userCache[data.id] = $.extend(currentData, data)
        canToggle: (data) ->
          data.type is 'user' or data.permissions?.send_messages_all
        selector:
          showToggles: true
          includeEveryoneOption: (postData, parent) =>
            # i.e. we are listing synthetic contexts under a course or section
            if postData.context?.match(/^(course|section)_\d+$/)
              everyoneText
          includeSelectAllOption: (postData, parent) =>
            # i.e. we are listing all users in a group or synthetic context
            if postData.context?.match(/^((course|section)_\d+_.*|group_\d+)$/) and not postData.context?.match(/^(course|section)_\d+$/) and not postData.context?.match(/^course_\d+_(groups|sections)$/) and parent.data('user_data').permissions.send_messages_all
              selectAllText
          baseData:
            permissions: ["send_messages_all"]
            messageable_only: true

      return if $scope

      @filterNameMap = {}
      $('#context_tags').contextSearch
        contexts: @contexts
        prefixUserIds: true
        added: (data, $token, newToken) =>
          $token.prevAll().remove() # only one token at a time
        tokenWrapBuffer: 80
        selector:
          includeEveryoneOption: (postData, parent) =>
            if postData.context?.match(/^course_\d+$/)
              everyoneText
          includeFilterOption: (postData) =>
            if postData.context?.match(/^course_\d+$/)
              I18n.t('filter_by_course', 'Filter by this course')
            else if postData.context?.match(/^group_\d+$/)
              I18n.t('filter_by_group', 'Filter by this group')
          baseData:
            synthetic_contexts: 1
            types: ['course', 'user', 'group']
            include_inactive: true
            blank_avatar_fallback: false
      filterInput = $('#context_tags').data('token_input')
      filterInput.change = (tokenValues) =>
        filters = for pair in filterInput.tokenPairs()
          @filterNameMap[pair[0]] = pair[1]
          pair[0]
        @updateHashData filter: filters

    initializeConversationsPane: () ->
      @conversations = new ConversationsPane this, @$conversations

    initializeMessageFormPane: () ->
      @formPane = new MessageFormPane(this, folderId: @options.FOLDER_ID)

    addedMessageForm: ($form) ->
      @prepareTextareas($form.find('textarea'))
      @initializeTokenInputs($form)

    initializeAutoResize: ->
      $(window).resize => @resize(50)
      @resize()

    currentHashData: ->
      try
        data = $.parseJSON($.decodeFromHex(location.hash.substring(1))) || {}
      catch e
        data = {}
      data

    updateView: (force = false) =>
      hash = location.hash
      data = @currentHashData()
      data.force = force
      if data.filter
        data.filter = (id for id in data.filter when @filterNameMap[id])
        return @updateHashData(filter: null) if not data.filter.length
      @setScope(data.scope)
      @conversations.updateView(data)

    initializeHashChange: ->
      $(window).bind('hashchange', => @updateView()).triggerHandler('hashchange')
