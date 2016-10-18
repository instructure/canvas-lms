define([
  "react",
  "./IcInput",
  "classnames"
], function(React, IcInput, classnames) {

  var { string } = React.PropTypes;

  /**
   * A checkbox input wrapped with appropriate ic-Form-* elements and
   * classes, with support for a label and error message.
   *
   * All other props are passed through to the
   * <input />
   */
  var IcCheckbox = React.createClass({
    propTypes: {
      error: string,
      label: string
    },

    render() {
      var { controlClassName } = this.props;

      return (
        <IcInput
          {...this.props}
          type="checkbox"
          appendLabel={true}
          noClassName={true}
          controlClassName={classnames("ic-Form-control--checkbox", controlClassName)}
        />
      );
    }
  });
  return IcCheckbox;
});
