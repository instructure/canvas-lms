define([
  'react',
  'react-modal',
  'i18n!course_images',
  '../actions'
], (React, Modal, I18n, Actions) => {

  class CourseImageSelector extends React.Component {

    constructor (props) {
      super(props);
      this.state = props.store.getState();

      this.handleChange = this.handleChange.bind(this);
    }

    componentDidMount () {
      this.props.store.subscribe(this.handleChange);
    }

    handleChange () {
      this.setState(this.props.store.getState());
    }

    render () {
      return (
        <div>
          <input ref="hiddenInput" type="hidden" name={this.props.name} value={this.state.courseImage} />
          <div className="CourseImageSelector">
            <button
              className="Button"
              type="button"
              onClick={() => this.props.store.dispatch(Actions.setModalVisibility(true))}
            >
              {I18n.t('Change Image')}
            </button>
          </div>
          <Modal
            className="CourseImageSelector__Modal"
            isOpen={this.state.showModal}
            onRequestClose={() => this.props.store.dispatch(Actions.setModalVisibility(false))}
          >
            Picker will render here :)
          </Modal>
        </div>
      );
    }
  };

  return CourseImageSelector;

});