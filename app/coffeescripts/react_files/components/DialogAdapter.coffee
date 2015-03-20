define [
  'jquery'
  'react'
  'compiled/react/shared/utils/withReactElement'
  'i18n!restrict_student_access'
  './DialogContent'
  './DialogButtons'
  'jqueryui/dialog'
], ($, React, withReactElement, I18n, DialogContentComponent, DialogButtonsComponent) ->

  DialogContent = React.createFactory DialogContentComponent
  DialogButtons = React.createFactory DialogButtonsComponent

  DialogAdapter = React.createClass
    displayName: 'DialogAdapter'

    propTypes:
      open: React.PropTypes.bool.isRequired
      title: React.PropTypes.string

    getDefaultProps: ->
      open: false
      modal: true
      title: I18n.t("title.default_title", "Dialog")
      onOpen: -> {}
      onClose: -> {}

    componentWillReceiveProps: (newProps) ->
      @handlePropsChanged(newProps)

    handlePropsChanged: (props) ->
      props ?= @props
      @forceBuildDialog(props)

      if props.open
        @dialog.open()
        #focus the close button after one tick (let render happen first)
        setTimeout =>
          primary = $(_this.node).parent().find('.btn-primary')
          if primary
            primary.focus()
          else
            $(@node).parents('.ui-dialog').find('.ui-dialog-titlebar-close').focus()
        , 1
      else
        @dialog.close()

    forceBuildDialog: (props) ->
      content = null
      buttons = null
      if React.Children.count(props.children) == 1
        content = props.children
      else
        {content, buttons} = @processMultipleChildren(props)

      @addContent(content)
      @addButtons(buttons)

    processMultipleChildren: (props) ->
      content = null
      buttons = null
      React.Children.forEach props.children, (child) ->
        if child.type == DialogContent.type
          content = child
        if child.type == DialogButtons.type
          buttons = child
      {content: content, buttons: buttons}

    addContent: (content) ->
      React.render(content, @node)

    addButtons: (buttons) ->
      # hack to get buttons to render to buttonset ui
      if buttons?
        buttonSet = $(@node).parent().find('.ui-dialog-buttonset').html('').get(0)
        React.render(buttons, buttonSet)
      else
        $(@node).parent().find('.ui-dialog-buttonpane').hide()

    componentWillUnmount: ->
      @dialog.destroy()

    componentDidMount: ->
      @node = @getDOMNode()

      options =
        modal: @props.modal
        close: @props.onClose
        open: @props.onOpen
        title: @props.title
        autoOpen: false
        buttons: [{text: ''}] # force buttonset ui to be created

      @dialog = $(@node).dialog(options).data('dialog')
      @handlePropsChanged()

    close: ->
      @dialog.close()

    render: withReactElement ->
      div {}
