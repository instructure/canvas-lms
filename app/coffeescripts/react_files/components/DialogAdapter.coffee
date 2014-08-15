define [
  'jquery'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'i18n!restrict_student_access'
  'jqueryui/dialog'
], ($, React, withReactDOM, I18n) ->
  
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

      React.renderComponent(
        React.Children.only(props.children),
        @node
      )

      if props.open
        @dialog.open()
      else
        @dialog.close()

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

      @dialog = $(@node).dialog(options).data('dialog')
      @handlePropsChanged()

    render: withReactDOM ->
      div {}
