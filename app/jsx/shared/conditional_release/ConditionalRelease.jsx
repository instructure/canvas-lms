define([
  'jquery',
  'react',
  'react-modal',
  'i18n!conditional_release',
], function($, React, Modal, I18n) {

  // Conditional Release adds its form at the tail of the page
  // because it is sometimes nested within a larger form (eg., discussion topics)
  const HiddenForm = React.createClass({
    propTypes: {
      env: React.PropTypes.object.isRequired,
      target: React.PropTypes.string.isRequired
    },

    render() {
      return (
        <form id="conditional-release-editor-form"
            target={this.props.target}
            method="POST"

            action={this.props.env.edit_rule_url}>
          <input type="hidden" name="env" value={JSON.stringify(this.props.env)} />
        </form>
      );
    }
  });

  // Need to specify componentDidMount so that we can be sure the iframe exists before
  // submitting a form targetting it
  const ConditionalReleaseFrame = React.createClass({
    render() {
      return (
        <div className="conditional-release-editor-body ReactModal__Body">
         <iframe className="conditional-release-editor-frame" id={this.props.name} name={this.props.name} src={this.props.source}></iframe>
       </div>
      )
    },

    componentDidMount() {
      this.props.onComponentDidMount();
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
        modalIsOpen: false,
        hiddenContainer: null
      };
    },

    enabled() {
      return this.props.env &&
        this.props.env.assignment &&
        this.props.env.assignment.id &&
        !this.props.assignmentDirty;
    },

    saveDataMessage() {
      if (!this.enabled()) {
        return (
          <div ref="saveDataMessage" className="conditional-release-save-data">
            {I18n.t('Save your %{type} to begin specifying conditional content.', { type: this.props.type })}
          </div>
        );
      }
    },

    popupId() {
      if (this.props.env.assignment) {
        return "conditional_release_" + this.props.env.assignment.id;
      } else {
        return "conditional_release_no_assignment";
      }
    },

    hiddenContainer() {
      return this.state.hiddenContainer;
    },

    componentDidMount() {
      const $hiddenContainer = $('<div id="conditional-release-hidden-form-container"></div>');
      this.setState({ hiddenContainer: $hiddenContainer });
      $('body').append($hiddenContainer);
      React.render(
        <HiddenForm target={this.popupId()} env={this.props.env}></HiddenForm>,
        $hiddenContainer.get(0));
    },

    componentWillUnmount() {
      React.unmountComponentAtNode(this.hiddenContainer().get(0));
      this.hiddenContainer().remove();
    },

    onClick(event) {
      event.preventDefault();
      event.stopPropagation();
      this.setState({ modalIsOpen: true });
    },

    closeModal() {
      this.setState({ modalIsOpen:  false });
      this.refs.iframe.source = null;
    },

    submitForm() {
      $("#conditional-release-editor-form").submit();
    },

    render () {
      return (
        <div className="conditional-release-editor">
          <button ref="button" className="Button" disabled={!this.enabled()} onClick={this.onClick}>
            {I18n.t('View conditional content settings')}
          </button>
          { this.saveDataMessage() }
          <Modal isOpen={this.state.modalIsOpen}
                 onAfterOpen={this.onModalOpen}
                 onRequestClose={this.closeModal}
                 className='conditional-release-editor-modal ReactModal__Content--canvas'
                 overlayClassName='ReactModal__Overlay--canvas'>
            <div className="conditional-release-editor-layout ReactModal__Layout">
              <div className="ReactModal__Header">
                <div className="ReactModal__Header-Title">
                  <h4>{I18n.t('Conditional Content')}</h4>
                </div>
                <div className="ReactModal__Header-Actions">
                  <button className="Button Button--icon-action" type="button" onClick={this.closeModal}>
                    <i className="icon-x"></i>
                    <span className="screenreader-only">Close</span>
                  </button>
                </div>
              </div>
              <ConditionalReleaseFrame ref="iframe" name={this.popupId()} onComponentDidMount={this.submitForm} />
            </div>
          </Modal>
        </div>
      )
    }
  });

  const attach = function(element, type, env) {
    const editor = (
      <Editor env={env} type={type} />
    );
    return React.render(editor, element);
  };

  const ConditionalRelease = {
    Editor: Editor,
    attach: attach
  };

  return ConditionalRelease;
});
