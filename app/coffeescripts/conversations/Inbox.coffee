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
  'str/htmlEscape'
  'compiled/conversations/introSlideshow'
  'compiled/widget/TokenInput'
  'compiled/str/TextHelper'
  'compiled/jquery/scrollIntoView'
  'jquery.ajaxJSON'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
  'jquery.instructure_jquery_patches'
  'jquery.instructure_misc_helpers'
  'jquery.disableWhileLoading'
  'jquery.rails_flash_notifications'
  'media_comments'
  'vendor/jquery.ba-hashchange'
  'vendor/jquery.elastic'
  'vendor/jquery.pageless'
  'jqueryui/position'
], (I18n, $, htmlEscape, introSlideshow, TokenInput, TextHelper) ->

  class
    constructor: (@options) ->
      @currentUser = @options.USER
      @contexts    = @options.CONTEXTS
      @scope       = @options.SCOPE
      @userCache   = {}
      @userCache[@currentUser.id] = @currentUser
      $ => @render()

    render: ->
      @$inbox = $('#inbox')
      @minHeight = parseInt @$inbox.css('min-height').replace('px', '')
      @$conversations = $('#conversations')
      @$conversationList = @$conversations.find("ul.conversations")
      @$messages = $('#messages')
      @$messageList = @$messages.find('ul.messages')
      @initializeHelp()
      @initializeForms()
      @initializeMenus()
      @initializeMessageActions()
      @initializeConversationActions()
      @initializeTemplates()
      @initializeTokenInputs()
      @initializeConversationsPane(@options.INITIAL_CONVERSATIONS)
      @initializeAutoResize()
      @initializeHashChange()
      if @options.SHOW_INTRO
        introSlideshow()

    showMessageForm: ->
      newMessage = !@$selectedConversation?
      @$form.find('#recipient_info').showIf newMessage
      @$form.find('#group_conversation_info').hide()
      $('#action_compose_message').toggleClass 'active', newMessage

      if newMessage
        @$form.find('.audience').html I18n.t('headings.new_message', 'New Message')
        @$form.addClass('new')
        @$form.find('#action_add_recipients').hide()
        @$form.attr action: '/conversations'
      else
        @buildFormAudience()
        @$form.removeClass('new')
        @$form.find('#action_add_recipients').showIf(!@$selectedConversation.hasClass('private'))
        @$form.attr action: @$selectedConversation.find('a.details_link').attr('add_url')
    
      @resetMessageForm()
      @$form.find('#user_note_info').hide().find('input').attr('checked', false)
      @$form.show().find(':input:visible:first').focus()

    resetMessageForm: ->
      @buildFormAudience() if @$selectedConversation?
      @$form.find('input[name!=authenticity_token], textarea').not(":checkbox").val('').change()
      @$form.find(".attachment:visible").remove()
      @$form.find(".media_comment").hide()
      @$form.find("#action_media_comment").show()
      @resize()

    buildFormAudience: ->
      $formAudience = @$form.find('.audience')
      $formAudience.html @$selectedConversation.find('.audience').html()
      # replace each <span data-url='...'>...</span> with an <a href='...'>...</a>
      $formAudience.find('em').attr('id', 'form_contexts')
      $context = $formAudience.find('.context')
      for elem in $context
        $elem = $(elem)
        $elem.replaceWith("<a href='#{htmlEscape($elem.data('url'))}'>#{htmlEscape($elem.html())}</a>")

    parseQueryString: (queryString = window.location.search.substr(1)) ->
      hash = {}
      for parts in queryString.split(/\&/)
        [key, value] = parts.split(/\=/, 2)
        hash[decodeURIComponent(key)] = decodeURIComponent(value)
      hash

    isSelected: ($conversation) ->
      @$selectedConversation && @$selectedConversation.attr('id') == $conversation?.attr('id')

    selectUnloadedConversation: (conversationId, params) ->
      $.ajaxJSON '/conversations/' + conversationId, 'GET', {}, (data) =>
        @addConversation data, true
        $("#conversation_" + conversationId).hide()
        @selectConversation $("#conversation_" + conversationId), $.extend(params, {data: data})

    noMessagesCheck: ->
      $('#no_messages').showIf !@$conversationList.find('li:not([id=conversations_loader])').length

    selectConversation: ($conversation, params={}) ->
      @toggleMessageActions(off)

      if @isSelected($conversation)
        @$selectedConversation.removeClass 'inactive'
        @$messageList.find('li.selected').removeClass 'selected'
        return

      @$messageList.removeClass('private').hide().html ''
      @$messageList.addClass('private') if $conversation?.hasClass('private')

      if @$selectedConversation
        @$selectedConversation.removeClass 'selected inactive'
        if @scope == 'unread'
          @$selectedConversation.fadeOut 'fast', (e) =>
            $(e.currentTarget).remove()
            @noMessagesCheck()
        @$selectedConversation = null
      if $conversation
        @$selectedConversation = $conversation.addClass('selected')

      if @$selectedConversation || $('#action_compose_message').length
        @showMessageForm()
        @$form.find('#body').val(params.message) if params.message
      else
        @$form.parent().hide()

      if @$selectedConversation
        @$selectedConversation.scrollIntoView()
      else
        if params.user_id
          $('#from_conversation_id').val(params.from_conversation_id)
          $('#recipients').data('token_input').selector.addByUserId(params.user_id, params.from_conversation_id)
        return

      $c = @$selectedConversation

      completion = (data) =>
        return unless @isSelected($c)
        for user in data.participants when !@userCache[user.id]?.avatar_url
          @userCache[user.id] = user
          user.htmlName = @htmlNameForUser(user)
        if data['private'] and user = (user for user in data.participants when user.id isnt @currentUser.id)[0] and @canAddNotesFor(user)
          @$form.find('#user_note_info').show()
        @resize()
        @$messages.show()
        @$messageList.append @buildMessage(message) for message in data.messages
        @$messageList.show()
        if @$selectedConversation.hasClass 'unread'
          # we've already done this server-side
          @setConversationState @$selectedConversation, 'read'

      if params.data
        completion params.data
      else
        url = @$selectedConversation.find('a.details_link').attr('href')
        @$messageList.show().disableWhileLoading $.ajaxJSON(url, 'GET', {}, completion)

    contextList: (contexts, withUrl=false, limit=2) ->
      compare = (contextA, contextB) ->
        strA = contextA.name.toLowerCase()
        strB = contextB.name.toLowerCase()
        if strA < strB then -1 else if strA > strB then 1 else 0

      formatContext = (context) ->
        if withUrl and context.type is "course"
          return "<span class='context' data-url='#{htmlEscape(context.url)}'>#{htmlEscape(context.name)}</span>"
        else
          return htmlEscape(context.name)

      sharedContexts = (course for id, roles of contexts.courses when course = @contexts.courses[id]).
                 concat(group for id, roles of contexts.groups when group = @contexts.groups[id]).
                 sort(compare)[0...limit]

      $.toSentence(formatContext(context) for context in sharedContexts)

    htmlNameForUser: (user, contexts = {courses: user.common_courses, groups: user.common_groups}) ->
      htmlEscape(user.name) + if contexts.courses?.length or contexts.groups?.length then " <em>" + htmlEscape(@contextList(contexts)) + "</em>" else ''

    canAddNotesFor: (user) ->
      return false unless @options.NOTES_ENABLED
      return true if user.can_add_notes
      for id, roles of user.common_courses
        return true if 'StudentEnrollment' in roles and (@options.CAN_ADD_NOTES_FOR_ACCOUNT or @contexts.courses[id]?.can_add_notes)
      false

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
      $message.find('.audience').html user?.htmlName || htmlEscape(userName)
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
        from_conversation_id: @$selectedConversation.data('id')
      $pmAction.attr('href', pmUrl).click (e) =>
        e.stopPropagation()
      if data.forwarded_messages?.length
        $ul = $('<ul class="messages"></ul>')
        for submessage in data.forwarded_messages
          $ul.append @buildMessage(submessage)
        $message.append $ul

      $ul = $message.find('ul.message_attachments').detach()
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
      $mediaObject.find('span.title').html htmlEscape(data.display_name)
      $mediaObject.find('span.media_comment_id').html htmlEscape(data.media_id)
      $mediaObject.find('.instructure_inline_media_comment').data('media_comment_type', data.media_type)
      $mediaObject

    buildAttachment: (blank, data) ->
      $attachment = blank.clone(true).attr('id', 'attachment_' + data.id)
      $attachment.data('id', data.id)
      $attachment.find('span.title').html htmlEscape(data.display_name)
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
      $header.find('.title').html htmlEscape(data.assignment.name)
      $header.find('span.date').text(if data.submitted_at
        $.parseFromISO(data.submitted_at).datetime_formatted
      else
        I18n.t('not_applicable', 'N/A')
      )
      $header.find('.audience').html user?.htmlName || htmlEscape(userName)
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
        $inlineMore.attr('title', htmlEscape(I18n.t('titles.expand_inline', "Show more comments")))
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
        $moreLink.attr('title', htmlEscape(I18n.t('titles.view_submission', "Open submission in new window.")))
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
      $comment.find('.audience').html user?.htmlName || htmlEscape(userName)
      $comment.find('span.date').text $.parseFromISO(data.created_at).datetime_formatted
      $comment.find('p').html htmlEscape(data.comment).replace(/\n/g, '<br />')
      $comment

    inboxActionUrlFor: ($action, $conversation) ->
      $.replaceTags $action.attr('href'), 'id', $conversation.data('id')

    inboxAction: ($action, options) ->
      $loadingNode = options.loadingNode ? $action.closest('ul.conversations li')
      $loadingNode = $('#conversation_actions').data('selectedConversation') unless $loadingNode.length
      defaults =
        loadingNode: $loadingNode
        url: @inboxActionUrlFor($action, $loadingNode)
        method: 'POST'
        data: {}
      options = $.extend(defaults, options)

      return unless options.before?(options.loadingNode, options) ? true
      ajaxRequest = $.ajaxJSON options.url, options.method, options.data
        , (data) =>
          options.success?(options.loadingNode, data)
        , (data) =>
          options.error?(options.loadingNode, data)
      options.loadingNode?.disableWhileLoading(ajaxRequest)

    addConversation: (data, append) ->
      $('#no_messages').hide()
      $conversation = $("#conversation_" + data.id)
      if $conversation.length
        $conversation.show()
      else
        $conversation = $("#conversation_blank").clone(true).attr('id', 'conversation_' + data.id)
      $conversation.data('id', data.id)
      if data.avatar_url
        $conversation.prepend $('<img />').attr('src', data.avatar_url).addClass('avatar')
      $conversation[if append then 'appendTo' else 'prependTo'](@$conversationList).click (e) =>
        e.preventDefault()
        @setHash '#/conversations/' + $(e.currentTarget).data('id')
      @updateConversation($conversation, data, null)
      $conversation.hide().slideDown('fast') unless append
      @$conversationList.append $("#conversations_loader")
      $conversation

    htmlAudienceForConversation: (conversation, cutoff=2) ->
      audience = conversation.audience

      return "<span>#{htmlEscape(I18n.t('notes_to_self', 'Monologue'))}</span>" if audience.length == 0
      context_info = "<em>#{@contextList(conversation.audience_contexts, true)}</em>"
      return "<span>#{htmlEscape(@userCache[audience[0]].name)}</span> #{context_info}" if audience.length == 1

      audience = audience[0...cutoff].concat([audience[cutoff...audience.length]]) if audience.length > cutoff
      $.toSentence(for idOrArray in audience
        if typeof idOrArray is 'number'
          "<span>#{htmlEscape(@userCache[idOrArray].name)}</span>"
        else
          """
          <span class='others'>
            #{htmlEscape(I18n.t('other', "other", count: idOrArray.length))}
            <span>
              <ul>
                #{("<li>#{htmlEscape(@userCache[id].name)}</li>" for id in idOrArray).join('')}
              </ul>
            </span>
          </span>
          """
      ) + " " + context_info

    lastMessageKey: ->
      if @scope is 'sent'
        'last_authored_message'
      else
        'last_message'

    lastMessageAtKey: ->
      "#{@lastMessageKey()}_at"

    updateConversation: ($conversation, data, move_mode='slide') ->
      timestampKey = @lastMessageAtKey()
      # just in case the conversation changed underneath us (e.g. someone sent
      # a message to an archived conversation, thus un-archiving it)
      if not data[timestampKey]
        return @removeConversation($conversation)

      @toggleMessageActions(off)

      $a = $conversation.find('a.details_link')
      $a.attr 'href', $.replaceTags($a.attr('href'), 'id', data.id)
      $a.attr 'add_url', $.replaceTags($a.attr('add_url'), 'id', data.id)
      if data.participants
        for user in data.participants when !@userCache[user.id]
          @userCache[user.id] = user

      if data.audience
        $conversation.data('audience', data.audience.concat([@currentUser.id]))
        $conversation.find('.audience').html @htmlAudienceForConversation(data)
        @buildFormAudience() if @isSelected($conversation)
      $conversation.find('.actions a').click (e) =>
        e.preventDefault()
        e.stopImmediatePropagation()
        @closeMenus()
        @openConversationMenu($(e.currentTarget))
      .focus () =>
        @closeMenus()
        @openConversationMenu($(e.currentTarget))

      if data.message_count?
        $conversation.find('.count').text data.message_count
        $conversation.find('.count').showIf data.message_count > 1
      $conversation.find('span.date').text $.friendlyDatetime($.parseFromISO(data[timestampKey]).datetime)
      moveDirection = if $conversation.data(timestampKey) > data[timestampKey] then 'down' else 'up'
      $conversation.data timestampKey, data[timestampKey]
      $conversation.data 'starred', data.starred
      $p = $conversation.find('p')
      $p.text data[@lastMessageKey()]
      ($conversation.addClass(property) for property in data.properties) if data.properties.length
      $conversation.addClass('private') if data['private']
      $conversation.addClass('starred') if data.starred
      $conversation.addClass('unsubscribed') unless data.subscribed
      @setConversationState $conversation, data.workflow_state
      @repositionConversation($conversation, moveDirection, move_mode) if move_mode

    repositionConversation: ($conversation, moveDirection, move_mode) ->
      $conversation.show()
      timestampKey = @lastMessageAtKey()
      lastMessageAt = $conversation.data(timestampKey)
      $n = $conversation
      if moveDirection == 'up'
        $n = $n.prev() while $n.prev() && $n.prev().data(timestampKey) < lastMessageAt
      else
        $n = $n.next() while $n.next() && $n.next().data(timestampKey) > lastMessageAt
      return if $n == $conversation
      if move_mode is 'immediate'
        $conversation.detach()[if moveDirection == 'up' then 'insertBefore' else 'insertAfter']($n)
      else
        $dummy_conversation = $conversation.clone().insertAfter($conversation)
        $conversation.detach()[if moveDirection == 'up' then 'insertBefore' else 'insertAfter']($n).animate({opacity: 'toggle', height: 'toggle'}, 0)
        $dummy_conversation.animate {opacity: 'toggle', height: 'toggle'}, 200, =>
          $dummy_conversation.remove()
        $conversation.animate {opacity: 'toggle', height: 'toggle'}, 200, =>
          $conversation.scrollIntoView()

    removeConversation: ($conversation) ->
      deselect = @isSelected($conversation)
      $conversation.fadeOut 'fast', =>
        $conversation.remove()
        @noMessagesCheck()
        @setHash '' if deselect

    setConversationState: ($conversation, state) ->
      $conversation.removeClass('read unread archived').addClass state

    openConversationMenu: ($node) ->
      # get elements
      elements =
        node         : $node
        container    : $('#conversation_actions')
        conversation : $node.closest 'li'
        parent       : $node.parent()
        lists        : $('#conversation_actions ul')
        listElements : $('#conversation_actions li')
        focusable    : $('a, input, select, textarea')
        actions      :
          markAsRead   : $('#action_mark_as_read').parent()
          markAsUnread : $('#action_mark_as_unread').parent()
          unstar       : $('#action_unstar').parent()
          star         : $('#action_star').parent()
          unsubscribe  : $('#action_unsubscribe').parent()
          subscribe    : $('#action_subscribe').parent()
          forward      : $('#action_forward').parent()
          archive      : $('#action_archive').parent()
          unarchive    : $('#action_unarchive').parent()
          delete       : $('#action_delete').parent()
          deleteAll    : $('#action_delete_all').parent()

      @activeActionMenu = elements.node

      # add selected classes
      elements.parent.addClass 'selected'
      elements.container.addClass 'selected'
      elements.conversation.addClass 'menu_active'

      $container    = elements.container
      $conversation = elements.conversation

      # prep action container
      elements.container.data 'selectedConversation', elements.conversation
      elements.lists.removeClass('first last').hide()
      elements.listElements.hide()

      # show/hide relevant links
      elements.actions.markAsRead.show() if elements.conversation.hasClass 'unread'
      elements.actions.markAsUnread.show() if elements.conversation.hasClass 'read'

      if elements.conversation.hasClass 'starred'
        elements.actions.unstar.show()
      else
        elements.actions.star.show()

      if elements.conversation.hasClass('private')
        elements.actions.subscribe.hide()
        elements.actions.unsubscribe.hide()
      else
        elements.actions.unsubscribe.show() unless elements.conversation.hasClass 'unsubscribed'
        elements.actions.subscribe.show() if elements.conversation.hasClass 'unsubscribed'

      elements.actions.forward.show()
      elements.actions.delete.show()
      elements.actions.deleteAll.show()
      if @scope is 'archived' then elements.actions.unarchive.show() else elements.actions.archive.show()

      $(window).one 'keydown', (e) =>
        return if e.keyCode isnt 9 or e.shiftKey

        elements.focusable.one 'focus.actions_menu', (e) =>
          @nextElement = $(e.target)
          elements.focusable.unbind '.actions_menu'
          elements.container.find('a:visible:first').focus()

          elements.container.find('a:visible:first').bind 'blur.actions_menu', (e), =>
            $(window).one 'keyup', (e) =>
              actionMenuActive = elements.container.find('a:focus').length
              unless actionMenuActive
                elements.container.find('a.visible').unbind '.actions_menu'
                @activeActionMenu.focus()
          elements.container.find('a:visible:last').bind 'blur.actions_menu', (e), =>
            $(window).one 'keyup', (e) =>
              actionMenuActive = elements.container.find('a:focus').length
              unless actionMenuActive
                elements.container.find('a.visible').unbind '.actions_menu'
                @nextElement.focus()
                @closeMenus()

      elements.container.find('li[style*="list-item"]').parent().show()
      elements.groups = elements.container.find('ul[style*="block"]')
      if elements.groups.length
        elements.groups.first().addClass 'first'
        elements.groups.last().addClass 'last'

      offset = elements.node.offset()
      elements.container.css {
        left: (offset.left + (elements.node.width() / 2) - elements.container.offsetParent().offset().left - (elements.container.width() / 2)),
        top : (offset.top + (elements.node.height() * 0.9) - elements.container.offsetParent().offset().top)
      }

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

    resize: ->
      availableHeight = $(window).height() - $('#header').outerHeight(true) - ($('#wrapper-container').outerHeight(true) - $('#wrapper-container').height()) - ($('#main').outerHeight(true) - $('#main').height()) - $('#breadcrumbs').outerHeight(true) - $('#footer').outerHeight(true)
      availableHeight = @minHeight if availableHeight < @minHeight
      $(document.body).toggleClass('too_small', availableHeight <= @minHeight)
      @$inbox.height(availableHeight)
      @$messageList.height(availableHeight - @$form.outerHeight(true))
      @$conversationList.height(availableHeight - $('#actions').outerHeight(true))

    toggleMessageActions: (state) ->
      if state?
        @$messageList.find('> li').removeClass('selected')
        @$messageList.find('> li :checkbox').attr('checked', false)
      else
        state = !!@$messageList.find('li.selected').length
      $('#action_forward').parent().showIf(state and @$messageList.find('li.selected.forwardable').length)
      if state then $("#message_actions").slideDown(100) else $("#message_actions").slideUp(100)
      @$form[if state then 'addClass' else 'removeClass']('disabled')

    setHash: (hash) ->
      if hash isnt location.hash
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
          for conversation in data
            $conversation = $('#conversation_' + conversation.id)
            if $conversation.length
              @buildMessage(conversation.messages[0]).prependTo(@$messageList).slideDown 'fast' if @isSelected($conversation)
              @updateConversation($conversation, conversation, if data.length == 1 then 'slide' else 'immediate')
            else if conversation[@lastMessageAtKey()]
              @addConversation(conversation)
            @setHash '#/conversations/' + conversation.id if data.length == 1
          $.flashMessage(if data.length > 1 then I18n.t('messages_sent', 'Messages Sent') else I18n.t('message_sent', 'Message Sent'))
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
          @updateConversation(@$selectedConversation, data)
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
          $conversation = $('#conversation_' + conversation.id)
          if $conversation.length
            @buildMessage(conversation.messages[0]).prependTo(@$messageList).slideDown 'fast' if @isSelected($conversation)
            @updateConversation($conversation, conversation)
          else
            @addConversation(conversation)
          @setHash '#/conversations/' + conversation.id
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
            @$selectedConversation?.addClass('inactive')
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

      $('#menu_views').parent().find('li a').click (e) =>
        @closeMenus()
        @lockUntilUserInput()
        $('#menu_views').text $(e.currentTarget).text()

      @$conversations.delegate '.actions a', 'blur', (e) =>
        $(window).one 'keyup', (e) =>
          @closeMenus() if e.shiftKey #or $('#conversation_actions a:focus').length == 0

    initializeMessageActions: ->
      $('#message_actions').find('a').click (e) =>
        e.preventDefault()

      $('#cancel_bulk_message_action').click =>
        @toggleMessageActions off

    initializeConversationActions: ->
      $('#conversation_actions').find('li a').click (e) =>
        e.preventDefault()
        @closeMenus()

      $('.action_mark_as_read').click (e) =>
        e.preventDefault()
        e.stopImmediatePropagation()
        @inboxAction $(e.currentTarget),
          method: 'PUT'
          before: ($node) =>
            @setConversationState $node, 'read' unless @scope == 'unread'
            true
          success: ($node) =>
            @removeConversation $node if @scope == 'unread'
          error: ($node) =>
            @setConversationState $node 'unread' unless @scope == 'unread'

      $('.action_mark_as_unread').click (e) =>
        e.preventDefault()
        e.stopImmediatePropagation()
        @inboxAction $(e.currentTarget),
          method: 'PUT'
          before: ($node) => @setConversationState $node, 'unread'
          error: ($node) => @setConversationState $node, 'read'

      $('.action_unstar').click (e) =>
        e.preventDefault()
        e.stopImmediatePropagation()
        starred = null
        @inboxAction $(e.currentTarget),
          method: 'PUT'
          before: ($node) =>
            starred = $node.data('starred')
            $node.removeClass('starred') if starred
            starred
          success: ($node, data) =>
            @updateConversation($node, data)
            @removeConversation $node if @scope == 'starred'
          error: ($node) =>
            $node.addClass('starred')

      $('.action_star').click (e) =>
        e.preventDefault()
        e.stopImmediatePropagation()
        starred = null
        @inboxAction $(e.currentTarget),
          method: 'PUT'
          before: ($node, options) =>
            starred = $node.data('starred')
            if !starred
              $node.addClass('starred')
            !starred
          success: ($node, data) =>
            @updateConversation($node, data)
          error: ($node) =>
            $node.removeClass('starred')

      $('#action_add_recipients').click (e) =>
        e.preventDefault()
        @$addForm
          .attr('action', @inboxActionUrlFor($(e.currentTarget), @$selectedConversation))
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
              tokenInput.baseExclude = @$selectedConversation.data('audience')
              @$addForm.find("input[name!=authenticity_token]").val('').change()
            close: =>
              $('#add_recipients').data('token_input').input.blur()

      $('#action_subscribe').click (e) =>
        @inboxAction $(e.currentTarget),
          method: 'PUT'
          data: {subscribed: 1}
          success: ($node) => $node.removeClass 'unsubscribed'

      $('#action_unsubscribe').click (e) =>
        @inboxAction $(e.currentTarget),
          method: 'PUT'
          data: {subscribed: 0}
          success: ($node) => $node.addClass 'unsubscribed'

      $('#action_archive, #action_unarchive').click (e) =>
        @inboxAction $(e.currentTarget),
          method: 'PUT'
          success: ($node) => @removeConversation($node)

      $('#action_delete_all').click (e) =>
        if confirm I18n.t('confirm.delete_conversation', "Are you sure you want to delete your copy of this conversation? This action cannot be undone.")
          @inboxAction $(e.currentTarget), { method: 'DELETE', success: ($node) => @removeConversation($node) }

      $('#action_delete').click (e) =>
        $selectedMessages = @$messageList.find('.selected')
        message = if $selectedMessages.length > 1
          I18n.t('confirm.delete_messages', "Are you sure you want to delete your copy of these messages? This action cannot be undone.")
        else
          I18n.t('confirm.delete_message', "Are you sure you want to delete your copy of this message? This action cannot be undone.")
        if confirm message
          $selectedMessages.fadeOut 'fast'
          @inboxAction $(e.currentTarget),
            loadingNode: @$selectedConversation
            data: {remove: ($(message).data('id') for message in $selectedMessages)}
            success: ($node, data) =>
              # TODO: once we've got infinite scroll hooked up, we should
              # have the response tell us the number of messages still in
              # the conversation, and key off of that to know if we should
              # delete the conversation (or possibly reload its messages)
              ignoreList = '.selected, .generated'
              ignoreList += ', .other' if @scope is 'sent' # once there are no more messages by self, hide the conversation
              if @$messageList.find('> li').not(ignoreList).length
                $selectedMessages.remove()
                @updateConversation($node, data)
              else
                @removeConversation($node)
            error: =>
              $selectedMessages.show()

      $('#action_forward').click (e) =>
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
            {
              text: I18n.t('buttons.send_message', 'Send')
              click: -> $(this).submit()
            }
            {
              text: I18n.t('#buttons.cancel', 'Cancel')
              click: -> $(this).dialog('close')
            }
          ]
          close: =>
            $('#forward_recipients').data('token_input').input.blur()

    initializeTemplates: ->
      $('#conversation_blank .audience, #create_message_form .audience').click (e) =>
        if ($others = $(e.target).closest('span.others').find('> span')).length
          if not $(e.target).closest('span.others > span').length
            $('span.others > span').not($others).hide()
            $others.toggle()
            $others.css('left', $others.parent().position().left)
            $others.css('top', $others.parent().height() + $others.parent().position().top)
          e.preventDefault()
          return false

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

    # a little gimmick until we implement real ajax loading for filters. we
    # disable the inbox when a filter is changed (via dropdown or search).
    # that way it's more obvious stuff is loading and the user doesn't try
    # to do something else only to have the page change underneath them
    lockUntilUserInput: ->
      setTimeout =>
        @$inbox.disableWhileLoading @untilUserInput()

    untilUserInput: ->
      d = $.Deferred()
      $('body').one 'keydown click', d.resolve
      d.promise()

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
            $span.text(@contextList(courses: data.common_courses, groups: data.common_groups))
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
        if @currentFilter isnt tokenValues[0]
          # TODO: fragment hash fu + ajax
          newUrl = location.href.replace(/[\?#].*|/g, '')
          newUrl += '?filter=' + tokenValues[0] if tokenValues[0]
          filterInput.$input.blur()
          @lockUntilUserInput()
          location.href = newUrl
      if filter = @options.INITIAL_FILTER
        @currentFilter = filter.id
        filterInput.addToken
          value: filter.id
          text: filter.name
          data: $.extend(true, {}, filter)

    initializeConversationsPane: (conversations) ->
      for conversation in conversations
        @addConversation conversation, true
      @noMessagesCheck()

      setTimeout () =>
        @$conversationList.pageless
          totalPages: Math.ceil(@options.CONVERSATIONS_COUNT / @options.CONVERSATIONS_PER_PAGE)
          container: @$conversationList
          params:
            format: 'json'
            per_page: @options.CONVERSATIONS_PER_PAGE
          loader: $("#conversations_loader")
          scrape: (data) =>
            if typeof(data) == 'string'
              try
                data = $.parseJSON(data) || []
              catch error
                data = []
              for conversation in data
                @addConversation conversation, true
            @$conversationList.append $("#conversations_loader")
            false
        , 1

    initializeAutoResize: ->
      $(window).resize => @resize()
      setTimeout => @resize()

    initializeHashChange: ->
      $(window).bind 'hashchange', =>
        hash = location.hash
        if match = hash.match(/^#\/conversations\/(\d+)(\?(.*))?/)
          params = if match[3] then @parseQueryString(match[3]) else {}
          if ($c = $('#conversation_' + match[1])) and $c.length
            @selectConversation($c, params)
          else
            @selectUnloadedConversation(match[1], params)
        else
          params = {}
          if match = hash.match(/^#\/conversations\?(.*)$/)
            params = @parseQueryString(match[1])
          @selectConversation(null, params)
      .triggerHandler('hashchange')
