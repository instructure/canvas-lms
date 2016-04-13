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

    componentWillMount () {
      this.props.store.subscribe(this.handleChange);
      this.props.store.dispatch(Actions.getCourseImage(this.props.courseId));
    }

    handleChange () {
      this.setState(this.props.store.getState());
    }

    render () {

      const styles = {
        backgroundImage: `url(${this.state.imageUrl})`
      };

      return (
        <div>
          <input ref="hiddenInput" type="hidden" name={this.props.name} value={this.state.courseImage} />
          <div
            className="CourseImageSelector"
            style={(this.state.imageUrl) ? styles : {}}
          >
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