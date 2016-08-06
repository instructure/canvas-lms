define [
  'i18n!assignment_muter'
  'jquery'
  'jst/mute_dialog'
  'jquery.ajaxJSON'
  'jquery.disableWhileLoading'
  'jqueryui/dialog'
  'vendor/jquery.ba-tinypubsub'
], (I18n, $, mute_dialog_template) ->

  class AssignmentMuter
    constructor: (@$link, @assignment, @url, @setter, @options) ->
      if @options?.openDialogInstantly
        if @assignment.muted then @confirmUnmute() else @showDialog()
      else
        @$link = $(@$link)
        @updateLink()
        @$link.click (event) =>
          event.preventDefault()
          if @assignment.muted then @confirmUnmute() else @showDialog()

    updateLink: =>
      @$link.text(if @assignment.muted then I18n.t('unmute_assignment', 'Unmute Assignment') else I18n.t('mute_assignment', 'Mute Assignment'))

    showDialog: =>
      @$dialog = $(mute_dialog_template()).dialog
        buttons: [{
          text: I18n.t('Cancel')
          class: 'Button'
          'data-action': 'cancel'
          click: =>
            @$dialog.dialog('close')
        },{
          text: I18n.t('mute_assignment', 'Mute Assignment')
          class: 'Button Button--primary'
          'data-action': 'mute'
          'data-text-while-loading': I18n.t('muting_assignment', 'Muting Assignment...')
          click: =>
            @$dialog.disableWhileLoading $.ajaxJSON(@url, 'put', { status : true }, @afterUpdate)
        }]
        open: => setTimeout (=> @$dialog.parent().find('.ui-dialog-titlebar-close').focus()), 100
        close: => @$dialog.remove()
        resizable: false
        width: 400

    afterUpdate: (serverResponse) =>
      if @setter
        @setter @assignment, 'muted', serverResponse.assignment.muted
      else
        @assignment.muted = serverResponse.assignment.muted
      @updateLink() unless @options?.openDialogInstantly
      @$dialog.dialog('close')
      $.publish('assignment_muting_toggled', [@assignment])

    confirmUnmute: =>
      @$dialog = $('<div />')
        .text(I18n.t('unmute_dialog', "This assignment is currently muted. That means students can't see their grades and feedback. Would you like to unmute now?"))
        .dialog
          buttons: [{
            text: I18n.t('Cancel')
            class: 'Button'
            'data-action': 'cancel'
            click: =>
              @$dialog.dialog('close')
          },{
            text: I18n.t('unmute_button', 'Unmute Assignment')
            class: 'Button Button--primary'
            'data-action': 'unmute'
            'data-text-while-loading': I18n.t('unmuting_assignment', 'Unmuting Assignment...')
            click: =>
              @$dialog.disableWhileLoading $.ajaxJSON(@url, 'put', { status : false }, @afterUpdate)
          }]
          open: => setTimeout (=> @$dialog.parent().find('.ui-dialog-titlebar-close').focus()), 100
          close: => @$dialog.remove()
          resizable: false
          title: I18n.t("unmute_assignment", "Unmute Assignment")
          width: 400
