/** @jsx React.DOM */
define([
  'react',
  'react-modal',
  './SFUCopyrightComplianceNotice'
  ], function (React, ReactModal, SFUCopyrightComplianceNotice) {

    var SFUCopyrightComplianceModalDialog = React.createClass({

      propTypes: {
        modalIsOpen: React.PropTypes.bool
      },

      getInitialState() {
        return {
          modalIsOpen: this.props.modalIsOpen
        }
      },

      componentWillReceiveProps: function(nextProps) {
        this.setState({
          modalIsOpen: nextProps.modalIsOpen
        });
      },

      openModal(e) {
        e.preventDefault();
        this.setState({modalIsOpen: true});
      },

      closeModal(e) {
        if (e) {
          e.preventDefault();
        }
        this.setState({
          modalIsOpen: false
        });
      },

      publishCourse(e) {
        if (e) {
          e.preventDefault();
        }
        this.setState({
          modalIsOpen: false
        }, () => {
          document.getElementById(this.props.formId).submit();
        });
      },

      render() {
        return(
          <ReactModal
            isOpen={this.state.modalIsOpen}
            className='ReactModal__Content--canvas'
            overlayClassName='ReactModal__Overlay--canvas'
          >
            <div className="ReactModal__Layout">

              <div className="ReactModal__InnerSection ReactModal__Header">
                <div className="ReactModal__Header-Title">
                  <h4>Copyright Compliance Notice</h4>
                </div>
                <div className="ReactModal__Header-Actions">
                  <button className="Button Button--icon-action" type="button" onClick={this.closeModal}>
                    <i className="icon-x"></i>
                    <span className="screenreader-only">Close</span>
                  </button>
                </div>
              </div>

              <div className="ReactModal__InnerSection ReactModal__Body">
                <SFUCopyrightComplianceNotice />
              </div>

              <div className="ReactModal__InnerSection ReactModal__Footer">
                <div className="ReactModal__Footer-Actions">
                  <button type="button" className="btn btn-default" onClick={this.closeModal}>Cancel</button>
                  <button type="button" className="btn btn-primary" onClick={this.publishCourse}>Publish</button>
                </div>
              </div>

            </div>
          </ReactModal>
        )
      }
    });

  return SFUCopyrightComplianceModalDialog;
});