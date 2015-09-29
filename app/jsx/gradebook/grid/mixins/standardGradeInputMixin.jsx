/** @jsx React.DOM */
define([], function () {
  var StandardGradeInputMixin = {
    handleOnChange(event) {
      this.setState({gradeToPost: event.target.value});
    },

    renderEditGrade() {
      return (
        <input
          onChange={this.handleOnChange}
          className="grade"
          ref="gradeInput"
          type="text"
          value={this.state.gradeToPost || this.getDisplayGrade()}/>
      );
    },
  };

  return StandardGradeInputMixin;
});
