/** @jsx React.DOM */
define([], function () {
  var StandardRenderMixin = {
    render() {
      return (this.props.isActiveCell) ? this.renderEditGrade() : this.renderViewGrade();
    }
  };

  return StandardRenderMixin;
});
