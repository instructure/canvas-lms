$conversations = []
$conversation_list = []
$messages = []
$message_list = []
$form = []
$selected_conversation = null
$last_label = null
page = {}
MessageInbox = {}

class TokenInput
  constructor: (@node, @options) ->
    @node.data('token_input', this)
    @fake_input = $('<div />')
      .css('font-family', @node.css('font-family'))
      .insertAfter(@node)
      .addClass('token_input')
      .click => @input.focus()
    @node_name = @node.attr('name')
    @node.removeAttr('name').hide().change =>
      @tokens.html('')
      @change?(@token_values())

    @added = @options.added

    @placeholder = $('<span />')
    @placeholder.text(@options.placeholder)
    @placeholder.appendTo(@fake_input) if @options.placeholder

    @tokens = $('<ul />')
      .appendTo(@fake_input)
    @tokens.click (e) =>
      if $token = $(e.target).closest('li')
        $close = $(e.target).closest('a')
        if $close.length
          $token.remove()
          @change?(@token_values())

    @tokens.maxTokenWidth = =>
      (parseInt(@tokens.css('width').replace('px', '')) - 150) + 'px'
    @tokens.resizeTokens = (tokens) =>
      tokens.find('div.ellipsis').css('max-width', @tokens.maxTokenWidth())
    $(window).resize =>
      @tokens.resizeTokens(@tokens)

    # key capture input
    @input = $('<input />')
      .appendTo(@fake_input)
      .css('width', '20px')
      .css('font-size', @fake_input.css('font-size'))
      .autoGrowInput({comfortZone: 20})
      .focus =>
        @placeholder.hide()
        @active = true
        @fake_input.addClass('active')
      .blur =>
        @active = false
        setTimeout =>
          if not @active
            @fake_input.removeClass('active')
            @placeholder.showIf @val() is '' and not @tokens.find('li').length
            @selector?.blur?()
        , 50
      .keydown (e) =>
        @input_keydown(e)
      .keyup (e) =>
        @input_keyup(e)

    if @options.selector
      type = @options.selector.type ? TokenSelector
      delete @options.selector.type
      if @browser = @options.selector.browser
        delete @options.selector.browser
        $('<a class="browser">browse</a>')
          .click =>
            if @selector.browse(@browser.data)
              @fake_input.addClass('browse')
          .prependTo(@fake_input)
      @selector = new type(this, @node.attr('finder_url'), @options.selector)

    @base_exclude = []

    @resize()

  resize: () ->
    @fake_input.css('width', @node.css('width'))

  add_token: (data) ->
    val = data?.value ? @val()
    id = 'token_' + val
    $token = @tokens.find('#' + id)
    new_token = ($token.length is 0)
    if new_token
      $token = $('<li />')
      text = data?.text ? @val()
      $token.attr('id', id)
      $text = $('<div />').addClass('ellipsis')
      $text.attr('title', text)
      $text.text(text)
      $token.append($text)
      $close = $('<a />')
      $token.append($close)
      $token.append($('<input />')
        .attr('type', 'hidden')
        .attr('name', @node_name + '[]')
        .val(val)
      )
      # has to happen before append, so that its unlimited width doesn't make
      # @tokens grow (which would then keep us from limiting it)
      @tokens.resizeTokens($token)
      @tokens.append($token)
    @val('') unless data?.no_clear
    @placeholder.hide()
    @added?(data.data, $token, new_token) if data
    @change?(@token_values())
    @selector?.reposition()

  has_token: (data) ->
    @tokens.find('#token_' + (data?.value ? data)).length > 0

  remove_token: (data) ->
    id = 'token_' + (data?.value ? data)
    @tokens.find('#' + id).remove()
    @change?(@token_values())
    @selector?.reposition()

  remove_last_token: (data) ->
    @tokens.find('li').last().remove()
    @change?(@token_values())
    @selector?.reposition()

  input_keydown: (e) ->
    @keyup_action = false
    if @selector
      if @selector?.capture_keydown(e)
        e.preventDefault()
        return false
      else # as soon as we start typing, we are no longer in browse mode
        @fake_input.removeClass('browse')
    else if e.which in @delimiters ? []
      @keyup_action = @add_token
      e.preventDefault()
      return false
    true

  token_values: ->
    input.value for input in @tokens.find('input')

  input_keyup: (e) ->
    @keyup_action?()

  bottom_offset: ->
    offset = @fake_input.offset()
    offset.top += @fake_input.height() + 2
    offset

  focus: ->
    @input.focus()

  val: (val) ->
    if val?
      if val isnt @input.val()
        @input.val(val).change()
        @selector?.reposition()
    else
      @input.val()

  caret: ->
    if @input[0].selectionStart?
      start = @input[0].selectionStart
      end = @input[0].selectionEnd
    else
      val = @val()
      range = document.selection.createRange().duplicate()
      range.moveEnd "character", val.length
      start = if range.text == "" then val.length else val.lastIndexOf(range.text)

      range = document.selection.createRange().duplicate()
      range.moveStart "character", -val.length
      end = range.text.length
    if start == end
      start
    else
      -1

   selector_closed: ->
     @fake_input.removeClass('browse')

$.fn.tokenInput = (options) ->
  @each ->
    new TokenInput $(this), $.extend(true, {}, options)

class TokenSelector

  constructor: (@input, @url, @options={}) ->
    @stack = []
    @query_cache = {}
    @container = $('<div />').addClass('autocomplete_menu')
    @menu = $('<div />').append(@list = @new_list())
    @container.append($('<div />').append(@menu))
    @container.css('top', 0).css('left', 0)
    @mode = 'input'
    $('body').append(@container)

    @reposition = =>
      offset = @input.bottom_offset()
      @container.css('top', offset.top)
      @container.css('left', offset.left)
    $(window).resize @reposition
    @close()

  browse: (data) ->
    unless @ui_locked
      @input.val('')
      @close()
      @fetch_list(data: data)
      true

  new_list: ->
    $list = $('<div class="list"><ul class="heading"></ul><ul></ul></div>')
    $list.find('ul')
      .mousemove (e) =>
        return if @ui_locked
        $li = $(e.target).closest('li')
        $li = null unless $li.hasClass('selectable')
        @select($li)
      .mousedown (e) =>
        # sooper hacky... prevent the menu closing on scrollbar drag
        setTimeout =>
          @input.focus()
        , 0
      .click (e) =>
        return if @ui_locked
        $li = $(e.target).closest('li')
        $li = null unless $li.hasClass('selectable')
        @select($li)
        if @selection
          if $(e.target).closest('a.expand').length
            if @selection_expanded()
              @collapse()
            else
              @expand_selection()
          else if @selection_toggleable() and $(e.target).closest('a.toggle').length
            @toggle_selection()
          else
            if @selection_expanded()
              @collapse()
            else if @selection_expandable()
              @expand_selection()
            else
              @toggle_selection(on)
              @clear()
              @close()
        @input.focus()
    $list.body = $list.find('ul').last()
    $list

  capture_keydown: (e) ->
    return true if @ui_locked
    switch e.originalEvent?.keyIdentifier ? e.which
      when 'Backspace', 'U+0008', 8
        if @input.val() is ''
          if @list_expanded()
            @collapse()
          else if @menu.is(":visible")
            @close()
          else
            @input.remove_last_token()
          return true
      when 'Tab', 'U+0009', 9
        if @selection and (@selection_toggleable() or not @selection_expandable())
          @toggle_selection(on)
        @clear()
        @close()
        return true if @selection
      when 'Enter', 13
        if @selection_expanded()
          @collapse()
          return true
        else if @selection_expandable() and not @selection_toggleable()
          @expand_selection()
          return true
        else if @selection
          @toggle_selection(on)
          @clear()
        @close()
        return true
      when 'Shift', 16 # noop, but we don't want to set the mode to input
        return false
      when 'Esc', 'U+001B', 27
        if @menu.is(":visible")
          @close()
          return true
        else
          return false
      when 'U+0020', 32 # space
        if @selection_toggleable() and @mode is 'menu'
          @toggle_selection()
          return true
      when 'Left', 37
        if @list_expanded() and @input.caret() is 0
          if @selection_expanded() or @input.val() is ''
            @collapse()
          else
            @select(@list.find('li').first())
          return true
      when 'Up', 38
        @select_prev()
        return true
      when 'Right', 39
        return true if @input.caret() is @input.val().length and @expand_selection()
      when 'Down', 40
        @select_next()
        return true
      when 'U+002B', 187, 107 # plus
        if @selection_toggleable() and @mode is 'menu'
          @toggle_selection(on)
          return true
      when 'U+002D', 189, 109 # minus
        if @selection_toggleable() and @mode is 'menu'
          @toggle_selection(off)
          return true
    @mode = 'input'
    @fetch_list()
    false

  fetch_list: (options={}, @ui_locked=false) ->
    clearTimeout @timeout if @timeout?
    @timeout = setTimeout =>
      delete @timeout
      post_data = @prepare_post(options.data ? {})
      this_query = JSON.stringify(post_data)
      if post_data.search is '' and not @list_expanded() and not options.data
        @ui_locked = false
        @close()
        return
      if this_query is @last_applied_query
        @ui_locked = false
        return
      else if @query_cache[this_query]
        @last_applied_query = this_query
        @last_search = post_data.search
        @clear_loading()
        @render_list(@query_cache[this_query], options, post_data)
        return

      @set_loading()
      $.ajaxJSON @url, 'POST', $.extend({}, post_data),
        (data) =>
          @query_cache[this_query] = data
          @clear_loading()
          if JSON.stringify(@prepare_post(options.data ? {})) is this_query # i.e. only if it hasn't subsequently changed (and thus triggered another call)
            @last_applied_query = this_query
            @last_search = post_data.search
            @render_list(data, options, post_data) if @menu.is(":visible")
          else
            @ui_locked=false
        ,
        (data) =>
          @ui_locked=false
          @clear_loading()
    , 100

  add_by_user_id: (user_id, from_conversation_id) ->
    @set_loading()
    $.ajaxJSON @url, 'POST', { user_id: user_id, from_conversation_id: from_conversation_id },
      (data) =>
        @clear_loading()
        @close()
        user = data[0]
        if user
          @input.add_token
            value: user.id
            text: user.name
            data: user
      ,
      (data) =>
        @clear_loading()
        @close()

  open: ->
    @container.show()
    @reposition()

  close: ->
    @ui_locked = false
    @container.hide()
    delete @last_applied_query
    for [$selection, $list, query, search], i in @stack
      @list.remove()
      @list = $list.css('height', 'auto')
    @list.find('ul').html('')
    @stack = []
    @menu.css('left', 0)
    @select(null)
    @input.selector_closed()

  clear: ->
    @input.val('')

  blur: ->
    @close()

  list_expanded: ->
    if @stack.length then true else false

  selection_expanded: ->
    @selection?.hasClass('expanded') ? false

  selection_expandable: ->
    @selection?.hasClass('expandable') ? false

  selection_toggleable: ($node=@selection) ->
    ($node?.hasClass('toggleable') ? false) and not @selection_expanded()

  expand_selection: ->
    return false unless @selection_expandable() and not @selection_expanded()
    @stack.push [@selection, @list, @last_applied_query, @last_search]
    @clear()
    @menu.css('width', ((@stack.length + 1) * 100) + '%')
    @fetch_list({expand: true}, true)

  collapse: ->
    return false unless @list_expanded()
    [$selection, $list, @last_applied_query, @last_search] = @stack.pop()
    @ui_locked = true
    $list.css('height', 'auto')
    @menu.animate {left: '+=' + @menu.parent().css('width')}, 'fast', =>
      @input.val(@last_search)
      @list.remove()
      @list = $list
      @select $selection
      @ui_locked = false

  toggle_selection: (state, $node=@selection, toggle_only=false) ->
    return false unless state? or @selection_toggleable($node)
    id = $node.data('id')
    state = !$node.hasClass('on') unless state?
    if state
      $node.addClass('on') if @selection_toggleable($node) and not toggle_only
      @input.add_token
        value: id
        text: $node.data('text') ? $node.text()
        no_clear: true
        data: $node.data('user_data')
    else
      $node.removeClass('on') unless toggle_only
      @input.remove_token value: id
    @update_select_all($node) unless toggle_only

  update_select_all: ($node, offset=0) ->
    select_all_toggled = $node.data('user_data').select_all
    $list = if offset then @stack[@stack.length - offset][1] else @list
    $select_all = $list.select_all
    return unless $select_all
    $nodes = $list.body.find('li.toggleable').not($select_all)
    if select_all_toggled
      if $select_all.hasClass('on')
        $nodes.addClass('on').each (i, node) =>
          @toggle_selection off, $(node), true
      else
        $nodes.removeClass('on').each (i, node) =>
          @toggle_selection off, $(node), true
    else
      $on_nodes = $nodes.filter('.on')
      if $on_nodes.length < $nodes.length and $select_all.hasClass('on')
        $select_all.removeClass('on')
        @toggle_selection off, $select_all, true
        $on_nodes.each (i, node) =>
          @toggle_selection on, $(node), true
      else if $on_nodes.length == $nodes.length and not $select_all.hasClass('on')
        $select_all.addClass('on')
        @toggle_selection on, $select_all, true
        $on_nodes.each (i, node) =>
          @toggle_selection off, $(node), true
    if offset < @stack.length
      offset++
      $parent_node = @stack[@stack.length - offset][0]
      if @selection_toggleable($parent_node)
        if $select_all.hasClass('on')
          $parent_node.addClass('on')
        else
          $parent_node.removeClass('on')
        @update_select_all($parent_node, offset)

  select: ($node, preserve_mode = false) ->
    return if $node?[0] is @selection?[0]
    @selection?.removeClass('active')
    @selection = if $node?.length
      $node.addClass('active')
      $node.scrollIntoView(ignore: {border: on})
      $node
    else
      null
    @mode = (if $node then 'menu' else 'input') unless preserve_mode

  select_next: (preserve_mode = false) ->
    @select(if @selection
      if @selection.next().length
        @selection.next()
      else if @selection.parent('ul').next().length
        @selection.parent('ul').next().find('li').first()
      else
        null
    else
      @list.find('li:first')
    , preserve_mode)
    @select_next(preserve_mode) if @selection?.hasClass('message')

  select_prev: ->
    @select(if @selection
      if @selection?.prev().length
        @selection.prev()
      else if @selection.parent('ul').prev().length
        @selection.parent('ul').prev().find('li').last()
      else
        null
    else
      @list.find('li:last')
    )
    @select_prev() if @selection?.hasClass('message')

  populate_row: ($node, data, options={}) ->
    if @options.populator
      @options.populator($node, data, options)
    else
      $node.data('id', data.text)
      $node.text(data.text)
    $node.addClass('first') if options.first
    $node.addClass('last') if options.last

  set_loading: ->
    unless @menu.is(":visible")
      @open()
      @list.find('ul').last().append($('<li class="message first last"></li>'))
    @list.find('li').first().loadingImage()

  clear_loading: ->
    @list.find('li').first().loadingImage('remove')

  render_list: (data, options={}, post_data={}) ->
    @open()

    if options.expand
      $list = @new_list()
    else
      $list = @list
    $list.select_all = null

    @selection = null
    $uls = $list.find('ul')
    $uls.html('')
    $heading = $uls.first()
    $body = $uls.last()
    if data.length
      parent = if @stack.length then @stack[@stack.length - 1][0] else null
      unless data.prepared
        @options.preparer?(post_data, data, parent)
        data.prepared = true

      for row, i in data
        $li = $('<li />').addClass('selectable')
        @populate_row($li, row, level: @stack.length, first: (i is 0), last: (i is data.length - 1), parent: parent)
        $list.select_all = $li if row.select_all
        $li.addClass('on') if $li.hasClass('toggleable') and @input.has_token($li.data('id'))
        $body.append($li)
      $list.body.find('li.toggleable').addClass('on') if $list.select_all?.hasClass?('on') or @stack.length and @stack[@stack.length - 1][0].hasClass?('on')
    else
      $message = $('<li class="message first last"></li>')
      $message.text(@options.messages?.no_results ? '')
      $body.append($message)

    if @list_expanded()
      $li = @stack[@stack.length - 1][0].clone()
      $li.addClass('expanded').removeClass('active first last')
      $heading.append($li).show()
    else
      $heading.hide()

    if options.expand
      $list.insertAfter(@list)
      @menu.animate {left: '-=' + @menu.parent().css('width')}, 'fast', =>
        @list.animate height: '1px', 'fast', =>
          @ui_locked = false
        @list = $list
        @select_next(true)
    else
      @select_next(true) unless options.loading
      @ui_locked = false

  prepare_post: (data) ->
    post_data = $.extend(data, {search: @input.val()}, @options.base_data ? {})
    post_data.exclude = @input.base_exclude.concat(if @stack.length then [] else @input.token_values())
    post_data.context = @stack[@stack.length - 1][0].data('id') if @list_expanded()
    post_data.per_page ?= @options.limiter?(level: @stack.length)
    post_data

# depends on the scrollable ancestor being the first positioned
# ancestor. if it's not, it won't work
$.fn.scrollIntoView = (options = {}) ->
  $container = @offsetParent()
  containerTop = $container.scrollTop()
  containerBottom = containerTop + $container.height()
  elemTop = this[0].offsetTop
  elemBottom = elemTop + $(this[0]).outerHeight()
  if options.ignore?.border
    elemTop += parseInt($(this[0]).css('border-top-width').replace('px', ''))
    elemBottom -= parseInt($(this[0]).css('border-bottom-width').replace('px', ''))
  if elemTop < containerTop
    $container.scrollTop(elemTop)
  else if elemBottom > containerBottom
    $container.scrollTop(elemBottom - $container.height())

I18n.scoped 'conversations', (I18n) ->
  show_message_form = ->
    newMessage = !$selected_conversation?
    $form.find('#recipient_info').showIf newMessage
    $form.find('#group_conversation_info').hide()
    $('#action_compose_message').toggleClass 'active', newMessage

    if newMessage
      $form.find('.audience').html I18n.t('headings.new_message', 'New Message')
      $form.addClass('new')
      $form.find('#action_add_recipients').hide()
      $form.attr action: '/conversations'
    else
      $form.find('.audience').html $selected_conversation.find('.audience').html()
      $form.removeClass('new')
      $form.find('#action_add_recipients').showIf(!$selected_conversation.hasClass('private'))
      $form.attr action: $selected_conversation.find('a.details_link').attr('add_url')

    reset_message_form()
    $form.find('#user_note_info').hide().find('input').attr('checked', false)
    $form.show().find(':input:visible:first').focus()

  reset_message_form = ->
    $form.find('.audience').html $selected_conversation.find('.audience').html() if $selected_conversation?
    $form.find('input[name!=authenticity_token], textarea').val('').change()
    $form.find(".attachment:visible").remove()
    $form.find(".media_comment").hide()
    $form.find("#action_media_comment").show()
    inbox_resize()

  parse_query_string = (query_string = window.location.search.substr(1)) ->
    hash = {}
    for parts in query_string.split(/\&/)
      [key, value] = parts.split(/\=/, 2)
      hash[decodeURIComponent(key)] = decodeURIComponent(value)
    hash

  is_selected = ($conversation) ->
    $selected_conversation && $selected_conversation.attr('id') == $conversation?.attr('id')

  select_unloaded_conversation = (conversation_id, params) ->
    $.ajaxJSON '/conversations/' + conversation_id, 'GET', {}, (data) ->
      add_conversation data.conversation, true
      $("#conversation_" + conversation_id).hide()
      select_conversation $("#conversation_" + conversation_id), $.extend(params, {data: data})

  select_conversation = ($conversation, params={}) ->
    toggle_message_actions(off)

    if is_selected($conversation)
      $selected_conversation.removeClass 'inactive'
      $message_list.find('li.selected').removeClass 'selected'
      return

    $message_list.removeClass('private').hide().html ''
    $message_list.addClass('private') if $conversation?.hasClass('private')

    if $selected_conversation
      $selected_conversation.removeClass 'selected inactive'
      if MessageInbox.scope == 'unread'
        $selected_conversation.fadeOut 'fast', ->
          $(this).remove()
          $('#no_messages').showIf !$conversation_list.find('li').length
      $selected_conversation = null
    if $conversation
      $selected_conversation = $conversation.addClass('selected')

    if $selected_conversation || $('#action_compose_message').length
      show_message_form()
      $form.find('#body').val(params.message) if params.message
    else
      $form.parent().hide()

    if $selected_conversation
      $selected_conversation.scrollIntoView()
    else
      if params.user_id
        $('#from_conversation_id').val(params.from_conversation_id)
        $('#recipients').data('token_input').selector.add_by_user_id(params.user_id, params.from_conversation_id)
      return

    $form.loadingImage()
    $c = $selected_conversation

    completion = (data) ->
      return unless is_selected($c)
      for user in data.participants when !MessageInbox.user_cache[user.id]?.avatar_url
        MessageInbox.user_cache[user.id] = user
        user.html_name = html_name_for_user(user)
      if data['private'] and user = (user for user in data.participants when user.id isnt MessageInbox.user_id)[0] and can_add_notes_for(user)
        $form.find('#user_note_info').show()
      inbox_resize()
      $messages.show()
      i = j = 0
      message = data.messages[0]
      submission = data.submissions[0]
      while message || submission
        if message && (!submission || $.parseFromISO(message.created_at).datetime > $.parseFromISO(submission.submission_comments[submission.submission_comments.length - 1]?.created_at).datetime)
          # there's another message, and the next submission (if any) is not newer than it
          $message_list.append build_message(message)
          message = data.messages[++i]
        else
          # no more messages, or the next submission is newer than the next message
          $message_list.append build_submission(submission)
          submission = data.submissions[++j]
      $form.loadingImage 'remove'
      $message_list.hide().slideDown 'fast'
      if $selected_conversation.hasClass 'unread'
        # we've already done this server-side
        set_conversation_state $selected_conversation, 'read'

    if params.data
      completion params.data
    else
      $.ajaxJSON $selected_conversation.find('a.details_link').attr('href'), 'GET', {}, (data) ->
        completion(data)
      , ->
        $form.loadingImage('remove')

  MessageInbox.context_list = (contexts, limit=2) ->
    shared_contexts = (course.name for course_id, roles of contexts.courses when course = @contexts.courses[course_id]).
                concat(group.name for group_id, roles of contexts.groups when group = @contexts.groups[group_id])
    $.toSentence(shared_contexts.sort((a, b) ->
      a = a.toLowerCase()
      b = b.toLowerCase()
      if a < b
        -1
      else if a > b
        1
      else
        0
    )[0...limit])

  html_name_for_user = (user, contexts = {courses: user.common_courses, groups: user.common_groups}) ->
    $.h(user.name) + if contexts.courses?.length or contexts.groups?.length then " <em>" + $.h(MessageInbox.context_list(contexts)) + "</em>" else ''

  can_add_notes_for = (user) ->
    return false unless MessageInbox.notes_enabled
    return true if user.can_add_notes
    for course_id, roles of user.common_courses
      return true if 'StudentEnrollment' in roles and (MessageInbox.can_add_notes_for_account or MessageInbox.contexts.courses[course_id]?.can_add_notes)
    false

  formatted_message = (message) ->
    link_placeholder = "LINK_PLACEHOLDER"
    link_re = ///
      \b
      (                                            # Capture 1: entire matched URL
        (?:
          https?://                                # http or https protocol
          |                                        # or
          www\d{0,3}[.]                            # "www.", "www1.", "www2." … "www999."
          |                                        # or
          [a-z0-9.\-]+[.][a-z]{2,4}/               # looks like domain name followed by a slash
        )
        (?:                                        # One or more:
          [^\s()<>]+                               # Run of non-space, non-()<>
          |                                        # or
          \(([^\s()<>]+|(\([^\s()<>]+\)))*\)       # balanced parens, up to 2 levels
        )+
        (?:                                        # End with:
          \(([^\s()<>]+|(\([^\s()<>]+\)))*\)       # balanced parens, up to 2 levels
          |                                        # or
          [^\s`!()\[\]{};:'".,<>?«»“”‘’]           # not a space or one of these punct chars
        )
      ) | (
        LINK_PLACEHOLDER
      )
    ///gi

    # replace any links with placeholders so we don't escape them
    links = []
    placeholder_blocks = []
    message = message.replace link_re, (match, i) ->
      placeholder_blocks.push(if match == link_placeholder
          link_placeholder
        else
          link = match
          link = "http://" + link if link[0..3] == 'www'
          link = encodeURI(link).replace(/'/g, '%27')
          links.push link
          "<a href='#{$.h(link)}'>#{$.h(match)}</a>"
      )
      link_placeholder

    # now escape html
    message = $.h message

    # now put the links back in
    message = message.replace new RegExp(link_placeholder, 'g'), (match, i) ->
      placeholder_blocks.shift()

    # replace newlines
    message = message.replace /\n/g, '<br />\n'

    # generate quoting clumps
    processed_lines = []
    quote_block = []
    quotes_added = 0
    quote_clump = (lines) ->
      quotes_added += 1
      "<div class='quoted_text_holder'>
        <a href='#' class='show_quoted_text_link'>#{I18n.t("quoted_text_toggle", "show quoted text")}</a>
        <div class='quoted_text' style='display: none;'>
          #{lines.join "\n"}
        </div>
      </div>"
    for idx, line of message.split("\n")
      if line.match /^(&gt;|>)/
        quote_block.push line
      else
        processed_lines.push quote_clump(quote_block) if quote_block.length
        quote_block = []
        processed_lines.push line
    processed_lines.push quote_clump(quote_block) if quote_block.length
    message = processed_lines.join "\n"

  build_message = (data) ->
    $message = $("#message_blank").clone(true).attr('id', 'message_' + data.id)
    $message.data('id', data.id)
    $message.addClass(if data.generated
      'generated'
    else if data.author_id is MessageInbox.user_id
      'self'
    else
      'other'
    )
    user = MessageInbox.user_cache[data.author_id]
    if avatar = user?.avatar_url
      $message.prepend $('<img />').attr('src', avatar).addClass('avatar')
    user.html_name ?= html_name_for_user(user) if user
    user_name = user?.name ? I18n.t('unknown_user', 'Unknown user')
    $message.find('.audience').html user?.html_name || $.h(user_name)
    $message.find('span.date').text $.parseFromISO(data.created_at).datetime_formatted
    $message.find('p').html formatted_message(data.body)
    $message.find("a.show_quoted_text_link").click (event) ->
      $text = $(this).parents(".quoted_text_holder").children(".quoted_text")
      if $text.length
        event.stopPropagation()
        event.preventDefault()
        $text.show()
        $(this).hide()
    $pm_action = $message.find('a.send_private_message')
    pm_url = $.replaceTags $pm_action.attr('href'),
      user_id: data.author_id
      user_name: encodeURIComponent(user_name)
      from_conversation_id: $selected_conversation.data('id')
    $pm_action.attr('href', pm_url).click (e) ->
      e.stopPropagation()
    if data.forwarded_messages?.length
      $ul = $('<ul class="messages"></ul>')
      for submessage in data.forwarded_messages
        $ul.append build_message(submessage)
      $message.append $ul

    $ul = $message.find('ul.message_attachments').detach()
    $media_object_blank = $ul.find('.media_object_blank').detach()
    $attachment_blank = $ul.find('.attachment_blank').detach()
    if data.media_comment? or data.attachments?.length
      $message.append $ul
      if data.media_comment?
        $ul.append build_media_object($media_object_blank, data.media_comment)
      if data.attachments?
        for attachment in data.attachments
          $ul.append build_attachment($attachment_blank, attachment)

    $message

  build_media_object = (blank, data) ->
    $media_object = blank.clone(true).attr('id', 'media_comment_' + data.media_id)
    $media_object.find('span.title').html $.h(data.display_name)
    $media_object.find('span.media_comment_id').html $.h(data.media_id)
    $media_object

  build_attachment = (blank, data) ->
    $attachment = blank.clone(true).attr('id', 'attachment_' + data.id)
    $attachment.data('id', data.id)
    $attachment.find('span.title').html $.h(data.display_name)
    $link = $attachment.find('a')
    $link.attr('href', data.url)
    $link.click (e) ->
      e.stopPropagation()
    $attachment

  submission_id = (data) ->
    "submission_#{data.assignment_id}_#{data.user_id}"

  build_submission = (data) ->
    $submission = $("#submission_blank").clone(true).attr('id', submission_id(data))
    $submission.data('id', submission_id(data))
    $ul = $submission.find('ul')
    $header = $ul.find('li.header')
    href = $.replaceTags($header.find('a').attr('href'), course_id: data.assignment.course_id, assignment_id: data.assignment_id, id: data.user_id)
    $header.find('a').attr('href', href)
    user = MessageInbox.user_cache[data.user_id]
    user.html_name ?= html_name_for_user(user) if user
    user_name = user?.name ? I18n.t('unknown_user', 'Unknown user')
    $header.find('.title').html $.h(data.assignment.name)
    if data.submitted_at
      $header.find('span.date').text $.parseFromISO(data.submitted_at).datetime_formatted
    $header.find('.audience').html user?.html_name || $.h(user_name)
    if data.score && data.assignment.points_possible
      score = "#{data.score} / #{data.assignment.points_possible}"
    else
      score = data.score ? I18n.t('not_scored', 'no score')
    $header.find('.score').html(score)
    $comment_blank = $ul.find('.comment').detach()
    index = 0
    initially_shown = 4
    for idx in [data.submission_comments.length - 1 .. 0] by -1
      comment = data.submission_comments[idx]
      break if index >= 10
      index++
      comment = build_submission_comment($comment_blank, comment)
      comment.hide() if index > initially_shown
      $ul.append comment
    $more_link = $ul.find('.more').detach()
    # the submission response isn't yet paginating/limiting the number of
    # comments returned, but we don't want to display more than 10 here, so we
    # artificially limit it.
    if index > initially_shown
      $inline_more = $more_link.clone(true)
      $inline_more.find('.hidden').text(index - initially_shown)
      $inline_more.attr('title', $.h(I18n.t('titles.expand_inline', "Show more comments")))
      $inline_more.click ->
        submission = $(this).closest('.submission')
        submission.find('.more:hidden').show()
        $(this).hide()
        submission.find('.comment:hidden').slideDown('fast')
        inbox_resize()
        return false
      $ul.append $inline_more
    if data.submission_comments.length > index
      $more_link.find('a').attr('href', href).attr('target', '_blank')
      $more_link.find('.hidden').text(data.submission_comments.length - index)
      $more_link.attr('title', $.h(I18n.t('titles.view_submission', "Open submission in new window.")))
      $more_link.hide() if data.submission_comments.length > initially_shown
      $ul.append $more_link
    $submission

  build_submission_comment = (blank, data) ->
    $comment = blank.clone(true)
    user = MessageInbox.user_cache[data.author_id]
    if avatar = user?.avatar_url
      $comment.prepend $('<img />').attr('src', avatar).addClass('avatar')
    user.html_name ?= html_name_for_user(user) if user
    user_name = user?.name ? I18n.t('unknown_user', 'Unknown user')
    $comment.find('.audience').html user?.html_name || $.h(user_name)
    $comment.find('span.date').text $.parseFromISO(data.created_at).datetime_formatted
    $comment.find('p').html $.h(data.comment).replace(/\n/g, '<br />')
    $comment

  inbox_action_url_for = ($action, $conversation) ->
    $.replaceTags $action.attr('href'), 'id', $conversation.data('id')

  inbox_action = ($action, options) ->
    $loading_node = options.loading_node ? $action.closest('ul.conversations li')
    $loading_node = $('#conversation_actions').data('selected_conversation') unless $loading_node.length
    defaults =
      loading_node: $loading_node
      url: inbox_action_url_for($action, $loading_node)
      method: 'POST'
      data: {}
    options = $.extend(defaults, options)

    return unless options.before?(options.loading_node, options) ? true
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

  add_conversation = (data, append) ->
    $('#no_messages').hide()
    $conversation = $("#conversation_" + data.id)
    if $conversation.length
      $conversation.show()
    else
      $conversation = $("#conversation_blank").clone(true).attr('id', 'conversation_' + data.id)
    $conversation.data('id', data.id)
    if data.avatar_url
      $conversation.prepend $('<img />').attr('src', data.avatar_url).addClass('avatar')
    $conversation[if append then 'appendTo' else 'prependTo']($conversation_list).click (e) ->
      e.preventDefault()
      set_hash '#/conversations/' + $(this).data('id')
    update_conversation($conversation, data, null)
    $conversation.hide().slideDown('fast') unless append
    $conversation_list.append $("#conversations_loader")
    $conversation

  html_audience_for_conversation = (conversation, cutoff=2) ->
    audience = conversation.audience

    return "<span>#{$.h(I18n.t('notes_to_self', 'Monologue'))}</span>" if audience.length == 0
    context_info = "<em>#{$.h(MessageInbox.context_list(conversation.audience_contexts))}</em>"
    return "<span>#{$.h(MessageInbox.user_cache[audience[0]].name)}</span> #{context_info}" if audience.length == 1

    audience = audience[0...cutoff].concat([audience[cutoff...audience.length]]) if audience.length > cutoff
    $.toSentence(for id_or_array in audience
      if typeof id_or_array is 'number'
        "<span>#{$.h(MessageInbox.user_cache[id_or_array].name)}</span>"
      else
        """
        <span class='others'>
          #{$.h(I18n.t('other_recipients', "other", count: id_or_array.length))}
          <span>
            <ul>
              #{("<li>#{$.h(MessageInbox.user_cache[id].name)}</li>" for id in id_or_array).join('')}
            </ul>
          </span>
        </span>
        """
    ) + " " + context_info

  update_conversation = ($conversation, data, move_mode='slide') ->
    toggle_message_actions(off)

    $a = $conversation.find('a.details_link')
    $a.attr 'href', $.replaceTags($a.attr('href'), 'id', data.id)
    $a.attr 'add_url', $.replaceTags($a.attr('add_url'), 'id', data.id)
    if data.participants
      for user in data.participants when !MessageInbox.user_cache[user.id]
        MessageInbox.user_cache[user.id] = user

    if data.audience
      $conversation.data('audience', data.audience.concat([MessageInbox.user_id]))
      $conversation.find('.audience').html html_audience_for_conversation(data)
    $conversation.find('.actions a').click (e) ->
      e.preventDefault()
      e.stopImmediatePropagation()
      close_menus()
      open_conversation_menu($(this))
    .focus () ->
      close_menus()
      open_conversation_menu($(this))

    if data.message_count?
      $conversation.find('.count').text data.message_count
      $conversation.find('.count').showIf data.message_count > 1
    $conversation.find('span.date').text $.friendlyDatetime($.parseFromISO(data.last_message_at).datetime)
    move_direction = if $conversation.data('last_message_at') > data.last_message_at then 'down' else 'up'
    $conversation.data 'last_message_at', data.last_message_at
    $conversation.data 'label', data.label
    $p = $conversation.find('p')
    $p.text data.last_message
    ($conversation.addClass(property) for property in data.properties) if data.properties.length
    $conversation.addClass('private') if data['private']
    $conversation.addClass('labeled').addClass(data['label']) if data['label']
    $conversation.addClass('unsubscribed') unless data.subscribed
    set_conversation_state $conversation, data.workflow_state
    reposition_conversation($conversation, move_direction, move_mode) if move_mode

  reposition_conversation = ($conversation, move_direction, move_mode) ->
    $conversation.show()
    last_message = $conversation.data('last_message_at')
    $n = $conversation
    if move_direction == 'up'
      $n = $n.prev() while $n.prev() && $n.prev().data('last_message_at') < last_message
    else
      $n = $n.next() while $n.next() && $n.next().data('last_message_at') > last_message
    return if $n == $conversation
    if move_mode is 'immediate'
      $conversation.detach()[if move_direction == 'up' then 'insertBefore' else 'insertAfter']($n).scrollIntoView()
    else
      $dummy_conversation = $conversation.clone().insertAfter($conversation)
      $conversation.detach()[if move_direction == 'up' then 'insertBefore' else 'insertAfter']($n).animate({opacity: 'toggle', height: 'toggle'}, 0)
      $dummy_conversation.animate {opacity: 'toggle', height: 'toggle'}, 200, ->
        $(this).remove()
      $conversation.animate {opacity: 'toggle', height: 'toggle'}, 200, ->
        $conversation.scrollIntoView()

  remove_conversation = ($conversation) ->
    deselect = is_selected($conversation)
    $conversation.fadeOut 'fast', ->
      $(this).remove()
      $('#no_messages').showIf !$conversation_list.find('li').length
      set_hash '' if deselect

  set_conversation_state = ($conversation, state) ->
    $conversation.removeClass('read unread archived').addClass state

  $('#conversations').delegate '.actions a', 'blur', (e) ->
    $(window).one 'keyup', (e) ->
      close_menus() if e.shiftKey #or $('#conversation_actions a:focus').length == 0

  open_conversation_menu = ($node) ->
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
        unsubscribe  : $('#action_unsubscribe').parent()
        subscribe    : $('#action_subscribe').parent()
        forward      : $('#action_forward').parent()
        archive      : $('#action_archive').parent()
        unarchive    : $('#action_unarchive').parent()
        delete       : $('#action_delete').parent()
        deleteAll    : $('#action_delete_all').parent()
      labels:
        group: $('#conversation_actions .label_group')
        icon: $('#conversation_actions .label_icon')

    page.activeActionMenu = elements.node

    # add selected classes
    elements.parent.addClass 'selected'
    elements.container.addClass 'selected'
    elements.conversation.addClass 'menu_active'

    $container    = elements.container
    $conversation = elements.conversation

    # prep action container
    elements.container.data 'selected_conversation', elements.conversation
    elements.lists.removeClass('first last').hide()
    elements.listElements.hide()

    # show/hide relevant links
    elements.actions.markAsRead.show() if elements.conversation.hasClass 'unread'
    elements.actions.markAsUnread.show() if elements.conversation.hasClass 'read'

    elements.labels.group.show()
    elements.labels.icon.removeClass 'checked'
    elements.container.find('.label_icon.' + ($conversation.data('label') || 'none')).addClass('checked')

    if elements.conversation.hasClass('private')
      elements.actions.subscribe.hide()
      elements.actions.unsubscribe.hide()
    else
      elements.actions.unsubscribe.show() unless elements.conversation.hasClass 'unsubscribed'
      elements.actions.subscribe.show() if elements.conversation.hasClass 'unsubscribed'

    elements.actions.forward.show()
    elements.actions.delete.show()
    elements.actions.deleteAll.show()
    if MessageInbox.scope is 'archived' then elements.actions.unarchive.show() else elements.actions.archive.show()

    $(window).one 'keydown', (e) ->
      return if e.keyCode isnt 9 or e.shiftKey

      elements.focusable.one 'focus.actions_menu', (e) ->
        page.nextElement = $(e.target)
        elements.focusable.unbind '.actions_menu'
        elements.container.find('a:visible:first').focus()

        elements.container.find('a:visible:first').bind 'blur.actions_menu', (e), ->
          $(window).one 'keyup', (e) ->
            actionMenuActive = elements.container.find('a:focus').length
            unless actionMenuActive
              elements.container.find('a.visible').unbind '.actions_menu'
              page.activeActionMenu.focus()
        elements.container.find('a:visible:last').bind 'blur.actions_menu', (e), ->
          $(window).one 'keyup', (e) ->
            actionMenuActive = elements.container.find('a:focus').length
            unless actionMenuActive
              elements.container.find('a.visible').unbind '.actions_menu'
              page.nextElement.focus()
              close_menus()

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

  close_menus = () ->
    $('#actions .menus > li, #conversation_actions, #conversations .actions').removeClass('selected')
    $('#conversations li.menu_active').removeClass('menu_active')

  open_menu = ($menu) ->
    close_menus()
    unless $menu.hasClass('disabled')
      $div = $menu.parent('li, span').addClass('selected').find('div')
      # TODO: move this out in the DOM so we can center it and not have it get clipped
      offset = -($div.parent().position().left + $div.parent().outerWidth() / 2) + 6 # for box shadow
      offset = -($div.outerWidth() / 2) if offset < -($div.outerWidth() / 2)
      $div.css 'margin-left', offset + 'px'

  inbox_resize = ->
    available_height = $(window).height() - $('#header').outerHeight(true) - ($('#wrapper-container').outerHeight(true) - $('#wrapper-container').height()) - ($('#main').outerHeight(true) - $('#main').height()) - $('#breadcrumbs').outerHeight(true) - $('#footer').outerHeight(true)
    available_height = 425 if available_height < 425
    $('#inbox').height(available_height)
    $message_list.height(available_height - $form.outerHeight(true))
    $conversation_list.height(available_height - $('#actions').outerHeight(true))

  toggle_message_actions = (state) ->
    if state?
      $message_list.find('> li').removeClass('selected')
      $message_list.find('> li :checkbox').attr('checked', false)
    else
      state = !!$message_list.find('li.selected').length
    if state then $("#message_actions").slideDown(100) else $("#message_actions").slideUp(100)
    $form[if state then 'addClass' else 'removeClass']('disabled')

  set_last_label = (label) ->
    $conversation_list.removeClass('red orange yellow green blue purple').addClass(label) # so that the label hover is correct
    $.cookie('last_label', label)
    $last_label = label

  set_hash = (hash) ->
    if hash isnt location.hash
      location.hash = hash
      $(document).triggerHandler('document_fragment_change', hash)

  $.extend window,
    MessageInbox: MessageInbox

  $(document).ready () ->
    $conversations = $('#conversations')
    $conversation_list = $conversations.find("ul.conversations")
    set_last_label($.cookie('last_label') ? 'red')
    $messages = $('#messages')
    $message_list = $messages.find('ul.messages')
    $form = $('#create_message_form')
    $add_form = $('#add_recipients_form')
    $forward_form = $('#forward_message_form')
    $('#help_crumb').click (e) ->
      e.preventDefault()
      $.conversationsIntroSlideshow()

    $('#create_message_form, #forward_message_form').find('textarea').elastic().keypress (e) ->
      if e.which is 13 and e.shiftKey
        e.preventDefault()
        $(this).closest('form').submit()
        false

    $form.submit (e) ->
      valid = !!($form.find('#body').val() and ($form.find('#recipient_info').filter(':visible').length is 0 or $form.find('.token_input li').length > 0))
      e.stopImmediatePropagation() unless valid
      valid
    $form.formSubmit
      fileUpload: ->
        return $(this).find(".file_input:visible").length > 0
      beforeSubmit: ->
        $(this).loadingImage()
      success: (data) ->
        $(this).loadingImage 'remove'
        if data.length > 1 # e.g. we just sent bulk private messages
          for conversation in data
            $conversation = $('#conversation_' + conversation.id)
            update_conversation($conversation, conversation, 'immediate') if $conversation.length
          $.flashMessage(I18n.t('messages_sent', 'Messages Sent'))
        else
          conversation = data[0] ? data
          $conversation = $('#conversation_' + conversation.id)
          if $conversation.length
            build_message(conversation.messages[0]).prependTo($message_list).slideDown 'fast' if is_selected($conversation)
            update_conversation($conversation, conversation)
          else
            add_conversation(conversation)
            set_hash '#/conversations/' + conversation.id
          $.flashMessage(I18n.t('message_sent', 'Message Sent'))
        reset_message_form()
      error: (data) ->
        $form.find('.token_input').errorBox(I18n.t('recipient_error', 'The course or group you have selected has no valid recipients'))
        $('.error_box').filter(':visible').css('z-index', 10) # TODO: figure out why this is necessary
        $(this).loadingImage 'remove'
    $form.click ->
      toggle_message_actions off

    $add_form.submit (e) ->
      valid = !!($(this).find('.token_input li').length)
      e.stopImmediatePropagation() unless valid
      valid
    $add_form.formSubmit
      beforeSubmit: ->
        $(this).loadingImage()
      success: (data) ->
        $(this).loadingImage 'remove'
        build_message(data.messages[0]).prependTo($message_list).slideDown 'fast'
        update_conversation($selected_conversation, data)
        reset_message_form()
        $(this).dialog('close')
      error: (data) ->
        $(this).loadingImage 'remove'
        $(this).dialog('close')


    $message_list.click (e) ->
      if $(e.target).closest('a.instructure_inline_media_comment').length
        # a.instructure_inline_media_comment clicks have to propagate to the
        # top due to "live" handling; if it's one of those, it's not really
        # intended for us, just let it go
      else
        $message = $(e.target).closest('#messages > ul > li')
        unless $message.hasClass('generated') or $message.hasClass('submission')
          $selected_conversation?.addClass('inactive')
          $message.toggleClass('selected')
          $message.find('> :checkbox').attr('checked', $message.hasClass('selected'))
        toggle_message_actions()

    $('.menus > li > a').click (e) ->
      e.preventDefault()
      open_menu $(this)
    .focus () ->
      open_menu $(this)

    $(document).bind 'mousedown', (e) ->
      unless $(e.target).closest("span.others").find('> span').length
        $('span.others > span').hide()
      close_menus() unless $(e.target).closest(".menus > li, #conversation_actions, #conversations .actions").length

    $('#menu_views').parent().find('li a').click (e) ->
      close_menus()
      $('#menu_views').text $(this).text()

    $('#message_actions').find('a').click (e) ->
      e.preventDefault()

    $('#conversation_actions').find('li a').click (e) ->
      e.preventDefault()
      close_menus()

    $('.action_mark_as_read').click (e) ->
      e.preventDefault()
      e.stopImmediatePropagation()
      inbox_action $(this),
        method: 'PUT'
        before: ($node) ->
          set_conversation_state $node, 'read' unless MessageInbox.scope == 'unread'
          true
        success: ($node) ->
          remove_conversation $node if MessageInbox.scope == 'unread'
        error: ($node) ->
          set_conversation_state $node 'unread' unless MessageInbox.scope == 'unread'

    $('.action_mark_as_unread').click (e) ->
      e.preventDefault()
      e.stopImmediatePropagation()
      inbox_action $(this),
        method: 'PUT'
        before: ($node) -> set_conversation_state $node, 'unread'
        error: ($node) -> set_conversation_state $node, 'read'

    $('.action_remove_label').click (e) ->
      e.preventDefault()
      e.stopImmediatePropagation()
      current_label = null
      inbox_action $(this),
        method: 'PUT'
        before: ($node) ->
          current_label = $node.data('label')
          $node.removeClass('labeled ' + current_label) if current_label
          current_label
        success: ($node, data) ->
          update_conversation($node, data)
          remove_conversation $node if MessageInbox.scope == 'labeled'
        error: ($node) ->
          $node.addClass('labeled ' + current_label)

    $('.action_add_label').click (e) ->
      e.preventDefault()
      e.stopImmediatePropagation()
      label = null
      current_label = null
      inbox_action $(this),
        method: 'PUT'
        before: ($node, options) ->
          current_label = $node.data('label')
          label = options.url.match(/%5Blabel%5D=(.*)/)[1]
          if label is 'last'
            label = $last_label
            options.url = options.url.replace(/%5Blabel%5D=last/, '%5Blabel%5D=' + label)
          $node.removeClass('red orange yellow green blue purple').addClass('labeled').addClass(label)
          label isnt current_label
        success: ($node, data) ->
          update_conversation($node, data)
          set_last_label(label)
          remove_conversation $node if MessageInbox.label_scope and MessageInbox.label_scope isnt label
        error: ($node) ->
          $node.removeClass('labeled ' + label)
          $node.addClass('labeled ' + current_label) if current_label

    $('#action_add_recipients').click (e) ->
      e.preventDefault()
      $add_form
        .attr('action', inbox_action_url_for($(this), $selected_conversation))
        .dialog('close').dialog
          width: 420
          title: I18n.t('title.add_recipients', 'Add Recipients')
          buttons: [
            {
              text: I18n.t('buttons.add_people', 'Add People')
              click: -> $(this).submit()
            }
            {
              text: I18n.t('#buttons.cancel', 'Cancel')
              click: -> $(this).dialog('close')
            }
          ]
          open: ->
            token_input = $('#add_recipients').data('token_input')
            token_input.base_exclude = $selected_conversation.data('audience')
            $(this).find("input[name!=authenticity_token]").val('').change()
          close: ->
            $('#add_recipients').data('token_input').input.blur()

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
      inbox_action $(this),
        method: 'PUT'
        success: remove_conversation

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
          loading_node: $selected_conversation
          data: {remove: (parseInt message.id.replace(/message_/, '') for message in $selected_messages)}
          success: ($node, data) ->
            # TODO: once we've got infinite scroll hooked up, we should
            # have the response tell us the number of messages still in
            # the conversation, and key off of that to know if we should
            # delete the conversation (or possibly reload its messages)
            if $message_list.find('> li').not('.selected, .generated, .submission').length
              $selected_messages.remove()
              update_conversation($node, data)
            else
              remove_conversation($node)
          error: ->
            $selected_messages.show()

    $('#action_forward').click ->
      $forward_form.find("input[name!=authenticity_token], textarea").val('').change()
      $preview = $forward_form.find('ul.messages').first()
      $preview.html('')
      $preview.html($message_list.find('> li.selected').clone(true).removeAttr('id').removeClass('self'))
      $preview.find('> li')
        .removeClass('selected odd')
        .find('> :checkbox')
        .attr('checked', true)
        .attr('name', 'forwarded_message_ids[]')
        .val ->
          $(this).closest('li').data('id')
      $preview.find('> li').last().addClass('last')
      $forward_form.css('max-height', ($(window).height() - 300) + 'px')
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
        close: ->
          $('#forward_recipients').data('token_input').input.blur()

    $forward_form.submit (e) ->
      valid = !!($(this).find('#forward_body').val() and $(this).find('.token_input li').length)
      e.stopImmediatePropagation() unless valid
      valid
    $forward_form.formSubmit
      beforeSubmit: ->
        $(this).loadingImage()
      success: (data) ->
        conversation = data[0]
        $(this).loadingImage 'remove'
        $conversation = $('#conversation_' + conversation.id)
        if $conversation.length
          build_message(conversation.messages[0]).prependTo($message_list).slideDown 'fast' if is_selected($conversation)
          update_conversation($conversation, conversation)
        else
          add_conversation(conversation)
        set_hash '#/conversations/' + conversation.id
        reset_message_form()
        $(this).dialog('close')
      error: (data) ->
        $(this).loadingImage 'remove'
        $(this).dialog('close')


    $('#cancel_bulk_message_action').click ->
      toggle_message_actions off

    $('#conversation_blank .audience, #create_message_form .audience').click (e) ->
      if ($others = $(e.target).closest('span.others').find('> span')).length
        if not $(e.target).closest('span.others > span').length
          $('span.others > span').not($others).hide()
          $others.toggle()
          $others.css('left', $others.parent().position().left)
          $others.css('top', $others.parent().height() + $others.parent().position().top)
        e.preventDefault()
        return false

    nextAttachmentIndex = 0
    $('#action_add_attachment').click (e) ->
      e.preventDefault()
      $attachment = $("#attachment_blank").clone(true)
      $attachment.attr('id', null)
      $attachment.find("input[type='file']").attr('name', 'attachments[' + (nextAttachmentIndex++) + ']')
      $('#attachment_list').append($attachment)
      $attachment.slideDown "fast", ->
        inbox_resize()
      return false

    $("#attachment_blank a.remove_link").click (e) ->
      e.preventDefault()
      $(this).parents(".attachment").slideUp "fast", ->
        inbox_resize()
        $(this).remove()
      return false

    $('#action_media_comment').click (e) ->
      e.preventDefault()
      $("#create_message_form .media_comment").mediaComment 'create', 'audio', (id, type) ->
        $("#media_comment_id").val(id)
        $("#media_comment_type").val(type)
        $("#create_message_form .media_comment").show()
        $("#action_media_comment").hide()

    $('#create_message_form .media_comment a.remove_link').click (e) ->
      e.preventDefault()
      $("#media_comment_id").val('')
      $("#media_comment_type").val('')
      $("#create_message_form .media_comment").hide()
      $("#action_media_comment").show()

    for conversation in MessageInbox.initial_conversations
      add_conversation conversation, true
    $('#no_messages').showIf !$conversation_list.find('li:not([id=conversations_loader])').length

    $('.recipients').tokenInput
      placeholder: I18n.t('recipient_field_placeholder', "Enter a name, course, or group")
      added: (data, $token, new_token) ->
        if new_token and data.type
          $token.addClass(data.type)
          if data.user_count?
            $token.addClass('details')
            $details = $('<span />')
            $details.text(I18n.t('people_count', 'person', {count: data.user_count}))
            $token.append($details)
        unless data.id and "#{data.id}".match(/^(course|group)_/)
          data = $.extend({}, data)
          delete data.avatar_url # since it's the wrong size and possibly a blank image
          current_data = MessageInbox.user_cache[data.id] ? {}
          MessageInbox.user_cache[data.id] = $.extend(current_data, data)
      selector:
        messages: {no_results: I18n.t('no_results', 'No results found')}
        populator: ($node, data, options={}) ->
          if data.avatar_url
            $img = $('<img class="avatar" />')
            $img.attr('src', data.avatar_url)
            $node.append($img)
          context_name  = if data.context_name then data.context_name else ''
          context_name  = if context_name.length < 40 then context_name else context_name.substr(0, 40) + '...'
          $context_name = if data.context_name then $('<span />', class: 'context_name').text("(#{context_name})") else ''
          $b = $('<b />')
          $b.text(data.name)
          $name = $('<span />', class: 'name')
          $name.append($b, $context_name)
          $span = $('<span />', class: 'details')
          if data.common_courses?
            $span.text(MessageInbox.context_list(courses: data.common_courses, groups: data.common_groups))
          else if data.type and data.user_count?
            $span.text(I18n.t('people_count', 'person', {count: data.user_count}))
          else if data.item_count?
            if data.id.match(/_groups$/)
              $span.text(I18n.t('groups_count', 'group', {count: data.item_count}))
            else if data.id.match(/_sections$/)
              $span.text(I18n.t('sections_count', 'section', {count: data.item_count}))
          $node.append($name, $span)
          $node.attr('title', data.name)
          text = data.name
          if options.parent
            if data.select_all and data.no_expand # "Select All", e.g. course_123_all -> "Spanish 101: Everyone"
              text = options.parent.data('text')
            else if (data.id + '').match(/_\d+_/) # e.g. course_123_teachers -> "Spanish 101: Teachers"
              text = I18n.beforeLabel(options.parent.data('text')) + " " + text
          $node.data('text', text)
          $node.data('id', data.id)
          $node.data('user_data', data)
          $node.addClass(if data.type then data.type else 'user')
          if options.level > 0
            $node.prepend('<a class="toggle"><i></i></a>')
            $node.addClass('toggleable') unless data.item_count # can't toggle synthetic contexts, e.g. "Student Groups"
          if data.type == 'context' and not data.no_expand
            $node.prepend('<a class="expand"><i></i></a>')
            $node.addClass('expandable')
        limiter: (options) ->
          if options.level > 0 then -1 else 5
        preparer: (post_data, data, parent) ->
          context = post_data.context
          if not post_data.search and context and data.length > 1
            if context.match(/^(course|section)_\d+$/)
              # i.e. we are listing synthetic contexts under a course or section
              data.unshift
                id: "#{context}_all"
                name: I18n.t('enrollments_everyone', "Everyone")
                user_count: parent.data('user_data').user_count
                type: 'context'
                avatar_url: parent.data('user_data').avatar_url
                select_all: true
            else if context.match(/^((course|section)_\d+_.*|group_\d+)$/) and not context.match(/^course_\d+_(groups|sections)$/)
              # i.e. we are listing all users in a group or synthetic context
              data.unshift
                id: context
                name: I18n.t('select_all', "Select All")
                user_count: parent.data('user_data').user_count
                type: 'context'
                avatar_url: parent.data('user_data').avatar_url
                select_all: true
                no_expand: true # just a magic select-all checkbox, you can't drill into it
        base_data:
          synthetic_contexts: 1
        browser:
          data:
            per_page: -1
            type: 'context'

    token_input = $('#recipients').data('token_input')
    # since it doesn't infer percentage widths, just whatever the current pixels are
    token_input.fake_input.css('width', '100%')
    token_input.change = (tokens) ->
      if tokens.length > 1 or tokens[0]?.match(/^(course|group)_/)
        $form.find('#group_conversation').attr('checked', false) if !$form.find('#group_conversation_info').is(':visible')
        $form.find('#group_conversation_info').show()
        $form.find('#user_note_info').hide()
      else
        $form.find('#group_conversation').attr('checked', false)
        $form.find('#group_conversation_info').hide()
        $form.find('#user_note_info').showIf((user = MessageInbox.user_cache[tokens[0]]) and can_add_notes_for(user))
      inbox_resize()

    $(window).resize inbox_resize
    setTimeout inbox_resize

    setTimeout () ->
      $conversation_list.pageless
        totalPages: Math.ceil(MessageInbox.initial_conversations_count / MessageInbox.conversation_page_size)
        container: $conversation_list
        params:
          format: 'json'
          per_page: MessageInbox.conversations_per_page
        loader: $("#conversations_loader")
        scrape: (data) ->
          if typeof(data) == 'string'
            try
              data = $.parseJSON(data) || []
            catch error
              data = []
            for conversation in data
              add_conversation conversation, true
          $conversation_list.append $("#conversations_loader")
          false
      , 1

    $(window).bind 'hashchange', ->
      hash = location.hash
      if match = hash.match(/^#\/conversations\/(\d+)(\?(.*))?/)
        params = if match[3] then parse_query_string(match[3]) else {}
        if ($c = $('#conversation_' + match[1])) and $c.length
          select_conversation($c, params)
        else
          select_unloaded_conversation(match[1], params)
      else if $('#action_compose_message').length
        params = {}
        if match = hash.match(/^#\/conversations\?(.*)$/)
          params = parse_query_string(match[1])
        select_conversation(null, params)
    .triggerHandler('hashchange')
