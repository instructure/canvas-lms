define [
  'underscore'
  'Backbone'
  'use!vendor/bootstrap/bootstrap-dropdown'
  'use!vendor/bootstrap-select/bootstrap-select'
], (_, {View}) ->

  class InboxHeaderView extends View

    els:
      '#compose-btn':     '$composeBtn'
      '#reply-btn':       '$replyBtn'
      '#reply-all-btn':   '$replyAllBtn'
      '#delete-btn':      '$deleteBtn'
      '#type-filter':     '$typeFilter'
      '#course-filter':   '$courseFilter'
      '#admin-btn':       '$adminBtn'
      '#mark-unread-btn': '$markUnreadBtn'
      '#admin-menu':      '$adminMenu'

    events:
      'click #compose-btn':       'onCompose'
      'click #reply-btn':         'onReply'
      'click #reply-all-btn':     'onReplyAll'
      'click #delete-btn':        'onDelete'
      'change #type-filter':      'onFilterChange'
      'change #course-filter':    'onFilterChange'
      'mouseover #course-filter': 'onCourseHover'
      'click #mark-unread-btn':   'onMarkUnread'
      'click #forward-btn':       'onForward'

    render: () ->
      super()
      @$typeFilter.selectpicker()
      @$courseFilter.selectpicker().next().on('mouseover', @onCourseHover)

    onCompose:     (e) -> @trigger('compose')

    onReply:       (e) -> @trigger('reply')

    onReplyAll:    (e) -> @trigger('reply-all')

    onDelete:      (e) -> @trigger('delete')

    onMarkUnread: (e) ->
      e.preventDefault()
      @trigger('mark-unread')

    onForward: (e) ->
      e.preventDefault()
      @trigger('forward')

    onModelChange: (newModel, oldModel) ->
      @toggleMessageBtns(!newModel.get('selected'))
      oldModel.off(null, null, this) if oldModel
      @onReadStateChange(newModel)
      newModel.on('change:workflow_state', @onReadStateChange, this)

    onReadStateChange: (msg) ->
      @hideMarkUnreadBtn(msg.unread())

    filterObj: (obj) -> _.object(_.filter(_.pairs(obj), (x) -> !!x[1]))

    onFilterChange: (e) ->
      @trigger('filter', @filterObj({type: @$typeFilter.val(), course: @$courseFilter.val()}))

    displayState: (state) ->
      @$typeFilter.val(state.type)
      @$courseFilter.val(state.course)
      @$typeFilter.selectpicker('render')
      @$courseFilter.selectpicker('render')
      course = @$courseFilter.find('option:selected')
      @trigger('course', {name: course.text(), code: course.data('code')})

    didCourseLoad: false
    onCourseHover: () =>
      return if @didCourseLoad
      @didCourseLoad = true
      _.each(@$courseFilter.find('optgroup'), (optgroup) =>
        $optgroup = $(optgroup)
        url = $optgroup.data('url')
        if !url then return
        $.ajax(url).done((data) =>
          _.each(data, (course) =>
            if @$courseFilter.find('option[value='+course.id+']').length then return
            $optgroup.append($('<option />').text(course.name).attr('value', course.id).attr('data-code', course.course_code))
          )
          @$courseFilter.selectpicker('refresh')
        )
      )

    toggleMessageBtns: (value) ->
      @toggleReplyBtn(value)
      @toggleReplyAllBtn(value)
      @toggleDeleteBtn(value)
      @toggleAdminBtn(value)

    toggleReplyBtn:    (value) -> @_toggleBtn(@$replyBtn, value)

    toggleReplyAllBtn: (value) -> @_toggleBtn(@$replyAllBtn, value)

    toggleDeleteBtn:   (value) -> @_toggleBtn(@$deleteBtn, value)

    toggleAdminBtn:    (value) -> @_toggleBtn(@$adminBtn, value)

    hideMarkUnreadBtn: (hide) -> if hide then @$markUnreadBtn.parent().detach() else @$adminMenu.prepend(@$markUnreadBtn.parent())

    _toggleBtn: (btn, value) ->
      value = if typeof value is 'undefined' then !btn.prop('disabled') else value
      btn.prop('disabled', value)
