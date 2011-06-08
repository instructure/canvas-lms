$conversations = []
$conversation_list = []
$messages = []
$message_list = []
$form = []
$selected_conversation = null
$scope = null
MessageInbox = {}

I18n.scoped 'conversations', (I18n) ->
  show_message_form = ->
    newMessage = !$selected_conversation?
    $form.find('#recipient_info').showIf newMessage
    $('#action_compose_message').toggleClass 'active', newMessage

    if newMessage
      $form.find('.audience').html I18n.t('headings.new_message', 'New Message')
      $form.attr action: '/messages'
    else
      $form.find('.audience').html $selected_conversation.find('.audience').html()
      $form.attr action: $selected_conversation.find('a').attr('add_url')

    reset_message_form()
    unless $form.is ':visible'
      $form.parent().show()
      $form.hide().slideDown 'fast', ->
        $form.find('#recipients').focus()

  reset_message_form = ->
    $form.find('input, textarea').val('')

  select_conversation = ($conversation) ->
    if $selected_conversation && $selected_conversation.attr('id') == $conversation?.attr('id')
      $selected_conversation.removeClass 'inactive'
      $message_list.find('li.selected').removeClass 'selected'
      return

    $message_list.hide().html ''
    if $selected_conversation
      $selected_conversation.removeClass 'selected inactive'
      if $scope == 'unread'
        $selected_conversation.fadeOut 'fast', ->
          $(this).remove()
          $('#no_messages').showIf !$conversation_list.find('li').length
      $selected_conversation = null
    if $conversation
      $selected_conversation = $conversation.addClass('selected')

    if $selected_conversation || $('#action_compose_message').length
      show_message_form()
    else
      $form.parent().hide()

    $('#menu_actions').triggerHandler('prepare_menu')
    $('#menu_actions').toggleClass 'disabled',
      !$('#menu_actions').parent().find('ul[style*="block"]').length

    if $selected_conversation
      location.hash = $selected_conversation.attr('id').replace('conversation_', '/messages/')
    else
      location.hash = ''
      return

    $form.loadingImage()
    $c = $selected_conversation
    $.ajaxJSON $selected_conversation.find('a').attr('href'), 'GET', {}, (data) ->
      return unless $c == $selected_conversation
      for user in data.participants when !MessageInbox.user_cache[user.id]
        MessageInbox.user_cache[user.id] = user
        user.html_name = html_name_for_user(user)
      $messages.show()
      for message in data.messages
        $message_list.append build_message(message.conversation_message)
      $form.loadingImage 'remove'
      $message_list.hide().slideDown 'fast'
      if $selected_conversation.hasClass 'unread'
        # we've already done this server-side
        set_conversation_state $selected_conversation, 'read'
    , ->
      $form.loadingImage('remove')

  html_name_for_user = (user) ->
    shared_contexts = (course.name for course_id in user.course_ids when course = MessageInbox.contexts.courses[course_id]).
                concat(group.name for group_id in user.group_ids when group = MessageInbox.contexts.groups[group_id])
    $.htmlEscape(user.name) + if shared_contexts.length then " <em>" + $.htmlEscape(shared_contexts.join(", ")) + "</em>"

  build_message = (data) ->
    $message = $("#message_blank").clone(true).attr('id', 'message_' + data.id)
    user = MessageInbox.user_cache[data.author_id]
    if avatar = user?.avatar
      $message.prepend $('<img />').attr('src', avatar).addClass('avatar')
    user.html_name ?= html_name_for_user(user) if user
    $message.find('.audience').html user?.html_name || I18n.t('unknown_user', 'Unknown user')
    $message.find('span.date').text $.parseFromISO(data.created_at).datetime_formatted
    $message.find('p').text data.body
    $message

  inbox_action_url_for = ($action) ->
    $.replaceTags $action.attr('href'), 'id', $selected_conversation.attr('id').replace('conversation_', '')

  inbox_action = ($action, options) ->
    defaults =
      loading_node: $selected_conversation
      url: inbox_action_url_for($action)
      method: 'POST'
      data: {}
    options = $.extend(defaults, options)

    options.before?(options.loading_node)
    options.loading_node?.loadingImage()
    $.ajaxJSON options.url,
      options.method,
      options.data,
      (data) ->
        options.loading_node?.loadingImage 'remove'
        options.success?(options.loading_node, data)
      , (data) ->
        options.loading_node?.loadingImage 'remove'
        options.error?(options.loading_node, data)

  add_conversation = (data, no_move) ->
    $conversation = $("#conversation_blank").clone(true).attr('id', 'conversation_' + data.id)
    if data.avatar_url
      $conversation.prepend $('<img />').attr('src', data.avatar_url).addClass('avatar')
    update_conversation($conversation, data, no_move)
    $conversation.appendTo($conversation_list).click (e) ->
      e.preventDefault()
      select_conversation $(this)

  update_conversation = ($conversation, data, no_move) ->
    $a = $conversation.find('a')
    $a.attr 'href', $.replaceTags($a.attr('href'), 'id', data.id)
    $a.attr 'add_url', $.replaceTags($a.attr('add_url'), 'id', data.id)
    $conversation.find('.audience').html data.audience if data.audience
    $conversation.find('span.date').text $.parseFromISO(data.last_message_at).datetime_formatted
    move_direction = if $conversation.data('last_message_at') < data.last_message_at then 'up' else 'down'
    $conversation.data 'last_message_at', data.last_message_at
    $p = $conversation.find('p')
    $p.text data.last_message
    $p.prepend ("<i class=\"flag_" + flag + "\"></i> " for flag in data.flags).join('') if data.flags.length
    $conversation.addClass('private') if data['private']
    $conversation.addClass('unsubscribed') unless data.subscribed
    $conversation.addClass(data.workflow_state)
    reposition_conversation($conversation, move_direction) unless no_move

  reposition_conversation = ($conversation, move_direction) ->
    last_message = $conversation.data('last_message_at')
    $n = $conversation
    if move_direction == 'up'
      $n = $n.prev() while $n.prev() && $n.prev().data('last_message_at') < last_message
    else
      $n = $n.next() while $n.next() && $n.next().data('last_message_at') > last_message
    return if $n == $conversation
    $dummy_conversation = $conversation.clone().insertAfter($conversation)
    $conversation.detach()[if move_direction == 'up' then 'insertBefore' else 'insertAfter']($n).animate({opacity: 'toggle', height: 'toggle'}, 0)
    $dummy_conversation.animate {opacity: 'toggle', height: 'toggle'}, 200, ->
      $(this).remove()
    $conversation.animate {opacity: 'toggle', height: 'toggle'}, 200

  remove_conversation = ($conversation) ->
    select_conversation()
    $conversation.fadeOut 'fast', ->
      $(this).remove()
      $('#no_messages').showIf !$conversation_list.find('li').length

  set_conversation_state = ($conversation, state) ->
    $conversation.removeClass('read unread archived').addClass state

  close_menus = () ->
    $('#actions .menus > li').removeClass('selected')

  open_menu = ($menu) ->
    close_menus()
    unless $menu.hasClass('disabled')
      $div = $menu.parent('li').addClass('selected').find('div')
      $menu.triggerHandler 'prepare_menu'
      $div.css 'margin-left', '-' + ($div.width() / 2) + 'px'

  $.extend window,
    MessageInbox: MessageInbox

  $(document).ready () ->
    $conversations = $('#conversations')
    $conversation_list = $conversations.find("ul")
    $messages = $('#messages')
    $message_list = $messages.find('ul').last()
    $form = $('#create_message_form')
    $scope = $('#menu_views').attr('class')

    $form.find("textarea").elastic()

    $form.formSubmit
      beforeSubmit: ->
        $(this).loadingImage()
      success: (data) ->
        $(this).loadingImage 'remove'
        build_message(data.message.conversation_message).prependTo($message_list).slideDown 'fast'
        $conversation = $('#conversation_' + data.conversation.id)
        if $conversation.length
          update_conversation($conversation, data.conversation)
        else
          add_conversation(data.conversation)
        reset_message_form()
      error: ->
        $(this).loadingImage 'remove'

    $message_list.click (e) ->
      $message = $(e.target).closest('li')
      $selected_conversation.addClass('inactive')
      $message.toggleClass('selected')

    $('#action_compose_message').click ->
      select_conversation()

    $('#actions .menus > li > a').click (e) ->
      e.preventDefault()
      open_menu $(this)
    .focus () ->
      open_menu $(this)

    $(document).bind 'mousedown', (e) ->
      unless $(e.target).closest("span.others").find('ul').length
        $('span.others ul').hide()
      close_menus() unless $(e.target).closest(".menus > li").length

    $('#menu_views').parent().find('li a').click (e) ->
      close_menus()
      $('#menu_views').text $(this).text()

    $('#menu_actions').bind 'prepare_menu', ->
      $container = $('#menu_actions').parent().find('div')
      $container.find('ul').removeClass('first last').hide()
      $container.find('li').hide()
      if $selected_conversation
        $('#action_mark_as_read').parent().showIf $selected_conversation.hasClass('unread')
        $('#action_mark_as_unread').parent().showIf $selected_conversation.hasClass('read')
        if $selected_conversation.hasClass('private')
          $('#action_add_recipients, #action_subscribe, #action_unsubscribe').parent().hide()
        else
          $('#action_unsubscribe').parent().showIf !$selected_conversation.hasClass('unsubscribed')
          $('#action_subscribe').parent().showIf $selected_conversation.hasClass('unsubscribed')
        $('#action_forward').parent().show()
        $('#action_archive').parent().showIf $scope != 'archived'
        $('#action_unarchive').parent().showIf $scope == 'archived'
        $('#action_delete').parent().showIf $selected_conversation.hasClass('inactive') && $message_list.find('.selected').length
        $('#action_delete_all').parent().showIf !$selected_conversation.hasClass('inactive') || !$message_list.find('.selected').length
      $('#action_mark_all_as_read').parent().showIf $scope == 'unread' && $conversation_list.find('.unread').length

      $container.find('li[style*="list-item"]').parent().show()
      $groups = $container.find('ul[style*="block"]')
      if $groups.length
        $($groups[0]).addClass 'first'
        $($groups[$groups.length - 1]).addClass 'last'
    .parent().find('li a').click (e) ->
      e.preventDefault()
      close_menus()

    $('#action_mark_as_read').click ->
      inbox_action $(this),
        before: ($node) ->
          set_conversation_state $node, 'read' unless $scope == 'unread'
        success: ($node) ->
          remove_conversation $node if $scope == 'unread'
        error: ($node) ->
          set_conversation_state $node 'unread' unless $scope == 'unread'

    $('#action_mark_all_as_read').click ->
      inbox_action $(this),
        url: $(this).attr('href'),
        success: ->
          $conversations.fadeOut 'fast', ->
            $(this).find('li').remove()
            $(this).show()
            $('#no_messages').show()
            select_conversation()

    $('#action_mark_as_unread').click ->
      inbox_action $(this),
        before: ($node) -> set_conversation_state $node, 'unread'
        error: ($node) -> set_conversation_state $node, 'read'

    $('#action_subscribe').click ->
      inbox_action $(this),
        method: 'PUT'
        data: {subscribed: 1}
        success: ($node) -> $node.removeClass 'unsubscribed'

    $('#action_unsubscribe').click ->
      inbox_action $(this),
        method: 'PUT'
        data: {subscribed: 0}
        success: ($node) -> $node.addClass 'unsubscribed'

    $('#action_archive, #action_unarchive').click ->
      inbox_action $(this), { success: remove_conversation }

    $('#action_delete_all').click ->
      if confirm I18n.t('confirm.delete_conversation', "Are you sure you want to delete your copy of this conversation? This action cannot be undone.")
        inbox_action $(this), { method: 'DELETE', success: remove_conversation }

    $('#action_delete').click ->
      $selected_messages = $message_list.find('.selected')
      message = if $selected_messages.length > 1
        I18n.t('confirm.delete_messages', "Are you sure you want to delete your copy of these messages? This action cannot be undone.")
      else
        I18n.t('confirm.delete_message', "Are you sure you want to delete your copy of this message? This action cannot be undone.")
      if confirm message
        $selected_messages.fadeOut 'fast'
        inbox_action $(this),
          data: {remove: (parseInt message.id.replace(/message_/, '') for message in $selected_messages)}
          success: ($node, data) ->
            # TODO: once we've got infinite scroll hooked up, we should
            # have the response tell us the number of messages still in
            # the conversation, and key off of that to know if we should
            # delete the conversation (or possibly reload its messages)
            if $message_list.find('li').not('.selected, .generated').length
              update_conversation($node, data)
              $selected_messages.remove()
            else
              remove_conversation($node)
          error: ->
            $selected_messages.show()

    $('#conversation_blank .audience, #create_message_form .audience').click (e) ->
      if ($others = $(e.target).closest('span.others').find('ul')).length
        if not $(e.target).closest('span.others ul').length
          $('span.others ul').not($others).hide()
          $others.toggle()
          $others.css('left', $others.parent().position().left)
        e.preventDefault()
        return false

    for conversation in MessageInbox.initial_conversations
      add_conversation conversation, true

    if match = location.hash.match(/^#\/messages\/(\d+)$/)
      $('#conversation_' + match[1]).click()
    else
      $('#action_compose_message').click()
