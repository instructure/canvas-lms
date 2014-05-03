define [
  'i18n!feature_flags'
  'compiled/views/DialogBaseView'
  'jst/feature_flags/featureFlagDialog'
], (I18n, DialogBaseView, template) ->

  class FeatureFlagDialog extends DialogBaseView

    @optionProperty 'deferred'

    @optionProperty 'message'

    @optionProperty 'title'

    @optionProperty 'hasCancelButton'

    template: template

    labels:
      okay   : I18n.t('#buttons.okay', 'Okay')
      cancel : I18n.t('#buttons.cancel', 'Cancel')

    dialogOptions: ->
      options =
        title   : @title
        height  : 300
        width   : 500
        buttons : [text: @labels.okay, click: @onConfirm, class: 'btn-primary']
      if @hasCancelButton
        options.buttons.unshift(text: @labels.cancel, click: @onCancel)
      options

    onCancel: (e) =>
      @deferred.reject()
      @close()

    onConfirm: (e) =>
      if @hasCancelButton then @deferred.resolve() else @deferred.reject()
      @close()

    toJSON: ->
      message: @message
