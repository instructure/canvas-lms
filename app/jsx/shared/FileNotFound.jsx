define([
  'jquery',
  'react',
  'react-dom',
  'i18n!file_not_found',
  'compiled/fn/preventDefault'
], function ($, React, ReactDOM, I18n, preventDefault) {

  const LABEL_TEXT = I18n.t('Please let them know which page you were viewing and the link you clicked on.');

  class FileNotFound extends React.Component {
    constructor () {
      super();
      this.state = {
        status: 'composing'
      };
    }

    submitMessage () {
      const conversationData = {
        subject: I18n.t('Broken file link found in your course'),
        recipients: this.props.contextCode + '_teachers',
        body: `${I18n.t('This most likely happened because you imported course content without its associated files.')}

        ${I18n.t('This student wrote:')} ${ReactDOM.findDOMNode(this.refs.message).value}`,
        context_code: this.props.contextCode
      };

      const dfd = $.post('/api/v1/conversations', conversationData);
      $(ReactDOM.findDOMNode(this.refs.form)).disableWhileLoading(dfd);

      dfd.done(() => this.setState({status: 'sent'}));
    }

    render () {
      if (this.state.status === 'composing') {
        return (
          <div>
            <p>{I18n.t('Be a hero and ask your instructor to fix this link.')}</p>
            <form
              style={{marginBottom: 0}}
              ref='form'
              onSubmit={preventDefault(this.submitMessage)}
            />
              <div className='form-group pad-box'>
                <label htmlFor='fnfMessage' className='screenreader-only'>
                  {LABEL_TEXT}
                </label>
                <textarea
                  className='input-block-level'
                  id='fnfMessage'
                  placeholder={LABEL_TEXT}
                  ref='message'
                />
              </div>
              <div className='form-actions' style={{marginBottom: 0}}>
                <button type='submit' className='btn btn-primary'>{I18n.t('Send')}</button>
              </div>
          </div>
        );
      } else {
        return (
          <p>{I18n.t('Your message has been sent. Thank you!')}</p>
        );
      }
    }
  }

  FileNotFound.propTypes = {
    contextCode: React.PropTypes.string.isRequired
  };

  return FileNotFound;

});
