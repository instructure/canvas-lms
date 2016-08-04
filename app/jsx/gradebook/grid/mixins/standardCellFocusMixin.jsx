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

      if(isActiveCell && !gradeHasChanged && !this.isConcluded()) {
        var gradeInput = this.refs.gradeInput;
        gradeInput.select();
      }
    },
  };

  return StandardCellFocusMixin;
});
