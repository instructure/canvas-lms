/** @jsx React.DOM */
define([], function () {
  var StandardCellFocusMixin = {
    componentDidUpdate(previousProps, previousState) {
      var isActiveCell    = this.props.isActiveCell,
          gradeHasChanged = (this.state.gradeToPost != previousState.grade);

      if (previousProps.isActiveCell && !isActiveCell) {
        var gradeToPost = this.state.gradeToPost;
        if (gradeToPost && this.getDisplayGrade() !== gradeToPost) {
          this.sendSubmission();
        }
      }

      if(isActiveCell && !gradeHasChanged) {
        var gradeInput = this.refs.gradeInput.getDOMNode();
        gradeInput.select();
      }
    },
  };

  return StandardCellFocusMixin;
});
