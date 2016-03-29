define([
  'react',
  'underscore',
  'jquery',
  'i18n!gradebook2',
  'bower/reflux/dist/reflux',
  'jsx/gradebook/grid/stores/gradebookToolbarStore',
  'jsx/gradebook/grid/actions/customColumnsActions',
  'react-modal',
  'jsx/gradebook/grid/constants',
  'compiled/jquery.rails_flash_notifications'
], function(React, _, $, I18n, Reflux, GradebookToolbarStore, CustomColumnsActions, Modal, GradebookConstants) {

  const modalOverrides = {
    overlay : {
      backgroundColor: 'rgba(0,0,0,0.5)'
    },  
    content : {
      position: 'static',
      top: '0',
      left: '0',
      right: 'auto',
      bottom: 'auto',
      borderRadius: '0',
      border: 'none',
      padding: '0'
    }
  };

  var TeacherNote = React.createClass({
    propTypes: {
      note: React.PropTypes.string.isRequired,
      userId: React.PropTypes.string.isRequired,
      studentName: React.PropTypes.string.isRequired,
      columnId: React.PropTypes.string.isRequired
    },

    mixins: [
      Reflux.connect(GradebookToolbarStore, 'toolbarOptions')
    ],

    getInitialState() {
      return {
        showModal: false,
        content: this.props.note
      };
    },

    showModal() {
      this.setState({ showModal: true });
    },

    hideModal() {
      this.setState({ showModal: false, content: this.props.note });
    },

    noErrorsOnPage() {
      return $('.ic-flash-error').length === 0;
    },

    updateContent(event) {
      var newContent = event.target.value,
        maxLength  = GradebookConstants.MAX_NOTE_LENGTH;

      if (newContent.length <= maxLength) {
        this.setState({ content: event.target.value });
      } else if(this.noErrorsOnPage()) {
        $.flashError(I18n.t('Note length cannot exceed %{maxLength} characters.', { maxLength: maxLength }));
      }
    },

    handleSubmit() {
      var columnId   = this.props.columnId,
        regexReplace = columnId + '/data/' + this.props.userId,
        url          = GradebookConstants.custom_column_datum_url.replace(/:id\/data\/:user_id/, regexReplace);

      $.ajaxJSON(url, 'PUT', { 'column_data[content]': this.state.content },
        () => {
          this.setState({ showModal: false });
        },
        () => {
          $.flashError(I18n.t('There was an error saving the note. Please try again.'));
        }
      );
    },

    nameToDisplay() {
      var hideNames = this.state.toolbarOptions.hideStudentNames;
      return hideNames ? I18n.t('student (name hidden)') : this.props.studentName;
    },

    render() {
      var close, save, title;

      close = I18n.t('Close');
      title = I18n.t('Notes for %{name}', { name: this.nameToDisplay() });
      save = I18n.t('Save');

      return (
        <div ref='noteCell' className='teacher-note' onClick={this.showModal}>
          <span>{this.state.content}</span>
          <Modal
            className='ReactModal__Content--canvas ReactModal__Content--mini-modal'
            overlayClassName='ReactModal__Overlay--canvas'
            style={modalOverrides}
            isOpen={this.state.showModal}
            onRequestClose={this.hideModal}>
            <div>
              <div className="ReactModal__Layout">
                <div className="ReactModal__InnerSection ReactModal__Header">
                  <div className="ReactModal__Header-Title">
                    <h4 ref='studentName'>
                      {title}
                    </h4>
                  </div>
                  <div className="ReactModal__Header-Actions">
                    <button className="Button Button--icon-action"
                      type="button" onClick={this.hideModal}>
                      <i className="icon-x"></i>
                      <span className="screenreader-only">
                        {close}
                      </span>
                    </button>
                  </div>
                </div>
                <div className="ReactModal__InnerSection ReactModal__Body notes-body"
                  onClick={this.makeTextEditable}>
                  <textarea className='notes-textarea'
                    value={this.state.content} onChange={this.updateContent}/>
                </div>

                <div className="ReactModal__InnerSection ReactModal__Footer">
                  <div className="ReactModal__Footer-Actions">
                    <button type="button" className="btn btn-default"
                      onClick={this.hideModal}>
                      {I18n.t('Cancel')}
                    </button>
                    <button type="submit" className="btn btn-primary"
                      disabled={this.state.content === this.props.note}
                      onClick={this.handleSubmit}>
                      {save}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </Modal>
        </div>
      );
    },
  });

  return TeacherNote;
});
