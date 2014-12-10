require [
  'jquery'
  'react'
  'i18n!file_not_found'
  'compiled/fn/preventDefault'
  'compiled/react/shared/utils/withReactDOM'
], ($, React, I18n, preventDefault, withReactDOM) ->
  FileNotFoundForm = React.createClass
    getInitialState: ->
      status: 'composing'

    submitMessage: ->
      conversationData =
        subject: I18n.t('Broken file link found in your course')
        recipients: ENV.context_asset_string + "_teachers"
        body: I18n.t("This most likely happened because you imported course content without its associated files.") + "\n\n" + I18n.t("This student wrote:") + " " + @refs.message.getDOMNode().value
        context_code: ENV.context_asset_string

      dfd = $.post "/api/v1/conversations", conversationData
      $(@refs.form.getDOMNode()).disableWhileLoading dfd

      dfd.done => @setState(status: 'sent')

    render: withReactDOM ->
      if @state.status == 'composing'
        div {},
          p {}, I18n.t("Be a hero and ask your instructor to fix this link.")
          form style: {'margin-bottom': 0}, ref: 'form', onSubmit: preventDefault(@submitMessage),
            div className: 'form-group pad-box',
              label for: 'fnfMessage', className: "screenreader-only", I18n.t('Please let them know which page you were viewing and link you clicked on.')
              textarea className: 'input-block-level', id: 'fnfMessage', placeholder: I18n.t('Please let them know which page you were viewing and link you clicked on.'), ref: 'message',
            div className: 'form-actions', style: {'margin-bottom': 0},
              button type: 'submit', className: 'btn btn-primary',
                I18n.t('Send')
      else
        p {}, I18n.t("Your message has been sent. Thank you!")

  React.renderComponent(FileNotFoundForm(), $('#sendMessageForm')[0])


