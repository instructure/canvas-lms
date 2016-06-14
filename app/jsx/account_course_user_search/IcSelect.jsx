define([
  "react",
  "./IcInput"
], function(React, IcInput) {

  var { string } = React.PropTypes;

  /**
   * A select wrapped with appropriate ic-Form-* elements and classes,
   * with support for a label and error message.
   *
   * All other props (including children) are passed through to the
   * <select />
   */
  var IcSelect = React.createClass({
    propTypes: {
      error: string,
      label: string
    },

    render() {
      return (
        <IcInput
          {...this.props}
          elementType="select"
        />
      );
    }
  });
  return IcSelect;
});

