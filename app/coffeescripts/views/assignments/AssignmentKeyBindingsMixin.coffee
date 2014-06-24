define [
  'underscore'
  'i18n!assignments'
], ( _, I18n) ->

  keyBindings:
    [
      keyCode: 74
      handler: 'goToNextItem'
      key: I18n.t 'keycodes.next', 'j'
      desc: I18n.t 'keyboard_next_item', 'Focus on the next assignment or group'
    ,
      keyCode: 75
      handler: 'goToPrevItem'
      key: I18n.t 'keycodes.previous', 'k'
      desc: I18n.t 'keyboard_prev_item', 'Focus on the previous assignment or group'
    ,
      keyCode: 69
      handler: 'editItem'
      key: I18n.t 'keycodes.edit_item', 'e'
      desc: I18n.t 'keyboard_edit_item', 'Edit the current assignment or group'
    ,
      keyCode: 68
      handler: 'deleteItem'
      key: I18n.t 'keycodes.del_item', 'd'
      desc: I18n.t 'keyboard_del_item', 'Delete the current assignment or group'
    ,
      keyCode: 65
      handler: 'addItem'
      key: I18n.t 'keycodes.add_item', 'a'
      desc: I18n.t 'keyboard_add_item', 'Add an assignment to selected group'
    ,
      keyCode: 70
      handler: 'showAssignment'
      key: I18n.t 'keycodes.show_assign', 'f'
      desc: I18n.t 'keyboard_show_assign', 'Show full preview of the selected assignment'
    ,
      keyCode: null
      key: I18n.t 'keycodes.close_menu', 'esc'
      desc: I18n.t 'keyboard_close_menu', 'Close the active dialog'
    ]

  handleKeys: (e) ->
    modifiers = ['shiftKey', 'altKey', 'ctrlKey']
    return if _.any(e[mod] for mod in modifiers)
    b = _.find(@keyBindings, (binding) ->
      binding.keyCode == e.keyCode
    )
    if b?.handler
      @[b.handler]?(e)
      e.stopPropagation()
