define([], function () {
  var StandardRenderMixin = {
    isConcluded() {
      return this.props.rowData.isConcluded;
    },

    render() {
      return (this.props.isActiveCell && !this.isConcluded()) ? this.renderEditGrade() : this.renderViewGrade();
    }
  };

  return StandardRenderMixin;
});
