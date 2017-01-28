define [
  'Backbone',
  'jst/gradezilla/checkbox_view'
], ({View}, template) ->

  class CheckboxView extends View

    tagName: 'label'

    className: 'checkbox-view'

    @optionProperty 'color'

    @optionProperty 'label'

    checked: true

    template: template

    events:
      'click': 'onClick'

    onClick: (e) ->
      e.preventDefault()
      @toggleState()

    toggleState: ->
      @checked = !@checked
      @trigger('togglestate', @checked)
      @render()

    toJSON: ->
      json =
        checked : @checked.toString()
        color   : if @checked then @options.color else 'none'
        label   : @options.label
