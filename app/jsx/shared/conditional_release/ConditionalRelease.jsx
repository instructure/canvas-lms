define([
  'jquery',
  'react',
  'react-dom',
  'react-modal',
  'classnames',
  'i18n!conditional_release',
  'jquery.instructure_forms',
], ($, React, ReactDOM, Modal, classNames, I18n) => {

  const SAVE_TIMEOUT = 15000

  // Conditional Release adds its form at the tail of the page
  // because it is sometimes nested within a larger form (eg., discussion topics)
  const HiddenForm = React.createClass({
    propTypes: {
      env: React.PropTypes.object.isRequired,
      target: React.PropTypes.string.isRequired
    },

    render() {
      return (
        <form id='conditional-release-editor-form'
            target={this.props.target}
            method='POST'
            action={this.props.env.edit_rule_url}>
          <input type='hidden' name='env' value={JSON.stringify(this.props.env)} />
        </form>
      );
    }
  });

  const Editor = React.createClass({
    displayName: 'ConditionalReleaseEditor',

    propTypes: {
      env: React.PropTypes.object.isRequired,
      type: React.PropTypes.string.isRequired
    },

    getInitialState() {
      return {
        messagePort: null,
        validationErrors: null,
        saveInProgress: null
      };
    },

    setValidationErrors(err) {
      this.setState({ validationErrors: JSON.parse(err) });
    },

    validateBeforeSave() {
      const errors = []
      if (this.state.validationErrors) {

        this.state.validationErrors.forEach((errorRecord) => {
          $.screenReaderFlashError(I18n.t('%{error} in mastery paths range %{index}', {
            error: errorRecord.error,
            index: errorRecord.index + 1 }))
          errors.push({ message: errorRecord.error })
        })
      }
      return errors.length == 0 ? null : errors;
    },

    focusOnError() {
      if (this.refs.iframe && this.refs.iframe.contentWindow) {
        this.refs.iframe.contentWindow.focus()
      }
      this.postMessage('focusOnError')
    },

    updateAssignment(newAttributes = {}) {
      // a not_graded assignment counts as a non-assignment
      // to cyoe
      if (newAttributes.grading_type === 'not_graded') {
        newAttributes.id = null;
      }
      this.postMessage('updateAssignment', {
        grading_standard_id: newAttributes.grading_standard_id,
        grading_type: newAttributes.grading_type,
        id: newAttributes.id,
        points_possible: newAttributes.points_possible,
        submission_types: newAttributes.submission_types
      });
    },

    save(timeoutMs = SAVE_TIMEOUT) {
      if (this.state.saveInProgress) {
        return this.state.saveInProgress;
      } else {
        const saveObject = $.Deferred()
        setTimeout(this.saveError.bind(this, saveObject, 'timeout'), timeoutMs)

        this.postMessage('save')
        this.setState({ saveInProgress: saveObject })
        return saveObject.promise();
      }
    },

    saveComplete(saveInProgress) {
      if (saveInProgress) {
        saveInProgress.resolve()
        if (this.state.saveInProgress == saveInProgress) {
          this.setState({ saveInProgress: null })
        }
      }
    },

    saveError(saveInProgress, reason) {
      if (saveInProgress) {
        saveInProgress.reject(reason)
        if (this.state.saveInProgress == saveInProgress) {
          this.setState({ saveInProgress: null })
        }
      }
    },

    updateModalState(state) {
      this.setState({ showOverlay: state.isVisible })

      if (state.isVisible) {
        $('body').addClass('conditional-release-modal-visible')
      } else {
        $('body').removeClass('conditional-release-modal-visible')
      }
    },

    popupId() {
      if (this.props.env.assignment) {
        return 'conditional_release_' + this.props.env.assignment.id;
      } else {
        return 'conditional_release_no_assignment';
      }
    },

    loadEditor() {
      const $hiddenContainer = $('<div id="conditional-release-hidden-form-container"></div>');
      $('body').append($hiddenContainer);
      ReactDOM.render(
        <HiddenForm target={this.popupId()} env={this.props.env}></HiddenForm>,
        $hiddenContainer.get(0));

      $('#conditional-release-editor-form').submit();

      ReactDOM.unmountComponentAtNode($hiddenContainer.get(0));
      $hiddenContainer.remove();

      $(this.refs.iframe).on('load', () => {
        this.connect(this.refs.iframe.contentWindow)
      });
    },

    connect(target) {
      const channel = new MessageChannel();
      const localPort = channel.port1;
      localPort.onmessage = this.handleMessage;
      this.setState({ messagePort: localPort })

      const remotePort = channel.port2;
      target.postMessage({
        context: 'conditional-release',
        messageType: 'connect'
      }, '*', [ remotePort ])
    },

    disconnect() {
      if (this.state.messagePort) {
        this.state.messagePort.close();
      }
      this.setState({ messagePort: null })
    },

    postMessage(type, body = null) {
      if (this.state.messagePort) {
        const message = {
          context: 'conditional-release',
          messageType: type,
          messageBody: body
        }
        this.state.messagePort.postMessage(message)
      }
    },

    handleMessage(messageEvent) {
      if (messageEvent.data && messageEvent.data.context === 'conditional-release') {
        switch (messageEvent.data.messageType) {
        case 'saveComplete':
          this.saveComplete(this.state.saveInProgress);
          break;
        case 'saveError':
          this.saveError(this.state.saveInProgress, messageEvent.data.messageBody);
          break;
        case 'validationErrors':
          this.setValidationErrors(messageEvent.data.messageBody);
          break;
        case 'modalStateChange':
          this.updateModalState(messageEvent.data.messageBody)
          break;
        }
      }
    },

    componentDidMount() {
      this.loadEditor();
    },

    render () {
      const iframeId = this.popupId();
      const frameClasses = classNames({
        'conditional-release-editor-frame': true,
        'conditional-release-editor-frame--modal-visible': this.state.showOverlay,
      })

      return (
        <div className='conditional-release-editor'>
          {this.state.showOverlay
            ? (<div id='conditional-release-modal-overlay' className='ReactModal__Overlay ReactModal__Overlay--after-open'></div>)
            : null}
          <iframe
            className={frameClasses}
            ref='iframe'
            id={iframeId}
            name={iframeId}
            title={I18n.t('Mastery Paths Editor')}
            aria-label={I18n.t('Mastery Paths Editor')}
          />
        </div>
      )
    }
  });

  const attach = function(element, type, env) {
    const editor = (
      <Editor env={env} type={type} />
    );
    return ReactDOM.render(editor, element);
  };

  const ConditionalRelease = {
    Editor: Editor,
    attach: attach
  };

  return ConditionalRelease;
});
