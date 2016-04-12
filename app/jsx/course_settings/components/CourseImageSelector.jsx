define([
  'react'
], (React) => {

  class CourseImageSelector extends React.Component {

    constructor (props) {
      super(props);
      this.state = props.store.getState();
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
          Picker goes here :)
        </div>
      );
    }
  };

  return CourseImageSelector;

});