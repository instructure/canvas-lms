define [
  'jquery'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'i18n!restrict_student_access'
  './DialogContent'
  './DialogButtons'
  'jqueryui/dialog'
], ($, React, withReactDOM, I18n, DialogContent, DialogButtons) ->

  DialogAdapter = React.createClass
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
      React.renderComponent(content, @node)

    addButtons: (buttons) ->
      # hack to get buttons to render to buttonset ui
      if buttons?
        buttonSet = $(@node).parent().find('.ui-dialog-buttonset').html('').get(0)
        React.renderComponent(buttons, buttonSet)
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

    render: withReactDOM ->
      div {}
