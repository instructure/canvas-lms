/** @jsx React.DOM */

define([
  'jquery',
  'react',
  'i18n!course_wizard',
  'react-modal',
  './InfoFrame',
  './Checklist',
  'compiled/jquery.rails_flash_notifications'
], function($, React, I18n, ReactModal, InfoFrame, Checklist) {

  var CourseWizard = React.createClass({
      displayName: 'CourseWizard',

      propTypes: {
        showWizard: React.PropTypes.bool,
        overlayClassName: React.PropTypes.string
      },

      getInitialState: function () {
        return {
          showWizard: this.props.showWizard,
          selectedItem: false
        };
      },

      componentDidMount: function () {
        this.refs.closeLink.getDOMNode().focus();
        $(this.refs.wizardBox.getDOMNode()).removeClass('ic-wizard-box--is-closed');
        $.screenReaderFlashMessageExclusive(I18n.t("Course Setup Wizard is showing."));
      },

      componentWillReceiveProps: function (nextProps) {
        this.setState({
          showWizard: nextProps.showWizard
        }, () => {
          $(this.refs.wizardBox.getDOMNode()).removeClass('ic-wizard-box--is-closed');
          if (this.state.showWizard) {
            this.refs.closeLink.getDOMNode().focus();
          }
        });
      },

      /**
       * Handles what should happen when a checklist item is clicked.
       */
      checklistClickHandler: function (itemToShowKey) {
        this.setState({
          selectedItem: itemToShowKey
        });
      },

      closeModal: function (event) {
        if (event) {
          event.preventDefault()
        };

        this.setState({
          showWizard: false
        })
      },

      render: function () {
          return (
              <ReactModal
                isOpen={this.state.showWizard}
                onRequestClose={this.closeModal}
                overlayClassName={this.props.overlayClassName}
              >
                <div ref="wizardBox" className="ic-wizard-box">
                  <div className="ic-wizard-box__header">
                    <a href="/" className="ic-wizard-box__logo-link">
                      <span className="screenreader-only">{I18n.t("My dashboard")}</span>
                    </a>
                    <Checklist className="ic-wizard-box__nav"
                               selectedItem={this.state.selectedItem}
                               clickHandler={this.checklistClickHandler}
                    />
                  </div>
                  <div className="ic-wizard-box__main">
                    <div className="ic-wizard-box__close">
                      <div className="ic-Expand-link ic-Expand-link--Secondary ic-Expand-link--from-right">
                        <a ref="closeLink" href="#" className="ic-Expand-link__trigger" onClick={this.closeModal}>
                          <div className="ic-Expand-link__layout">
                            <i className="icon-x ic-Expand-link__icon"></i>
                            <span className="ic-Expand-link__text">{I18n.t("Close and return to Canvas")}</span>
                          </div>
                        </a>
                      </div>
                    </div>
                    <InfoFrame className="ic-wizard-box__content" itemToShow={this.state.selectedItem} closeModal={this.closeModal} />
                  </div>
                </div>
              </ReactModal>
          );
      }
  });

  return CourseWizard;

});