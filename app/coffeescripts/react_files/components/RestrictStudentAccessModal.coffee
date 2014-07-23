define [
  'react'
  'compiled/react/shared/utils/withReactDOM'
], (React, withReactDOM) ->
  
  RestrictStudentAccessModal = React.createClass

    getDefaultProps: -> open: false

    componentDidMount: ->
      @dialog = $(@refs.dialog.getDOMNode()).dialog({ autoOpen: false })
      @dialog.find('#cancelButton').on "click", (event) => @dialog.dialog('close')

    componentWillUnmount: ->
      @dialog.destroy()

    componentWillReceiveProps: (newProps) ->
      if newProps.open
        @dialog.dialog('open')
      else
        @dialog.dialog('close')

    render: withReactDOM ->
      form ref: 'dialog', id:"testdialog", style: {display: 'none'}, title:"Title Goes Here",
        p null,
          "everything should go in here"
        div className: 'button-container',
          button type: 'submit', className: 'btn btn-primary',
            'Submit'
          a id: 'cancelButton', className: 'btn dialog_closer',
            'Cancel'
