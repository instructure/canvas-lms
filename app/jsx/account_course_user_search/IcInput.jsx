define([
  "react",
  "underscore",
  "bower/classnames/index"
], function(React, _, classnames) {

  var { string, any, bool } = React.PropTypes;

  var idCount = 0;

  /**
   * An input wrapped with appropriate ic-Form-* elements and classes,
   * with support for a label, error message and extra classes on the
   * wrapping div.
   *
   * All other props are passed through to the <input />
   */
  var IcInput = React.createClass({
    propTypes: {
      error: string,
      label: string,
      hint: string,
      elementType: any,
      controlClassName: string,
      appendLabel: bool,
      noClassName: bool
    },

    getDefaultProps() {
      return {
        elementType: "input"
      };
    },

    componentWillMount() {
      this.id = `ic_input_${idCount++}`;
    },

    render() {
      var { error, label, hint, elementType, appendLabel, controlClassName, noClassName } = this.props;
      var inputProps = _.extend({}, _.omit(this.props, ["error", "label", "elementType"]), {id: this.id});
      if (elementType === "input" && !this.props.type) {
        inputProps.type = "text";
      }
      if (!noClassName) {
        inputProps.className = classnames(inputProps.className, "ic-Input");
      }

      var labelElement = label &&
        <label htmlFor={this.id} className="ic-Label">{label}</label>;

      var hintElement = !!hint && <div className="ic-Form-help-text">{hint}</div>

      return (
        <div className={classnames("ic-Form-control", controlClassName, {"ic-Form-control--has-error": error})}>
          {!!label && !appendLabel && labelElement}
          {React.createElement(elementType, inputProps)}
          {!!label && appendLabel && labelElement}
          {!!error &&
            <div className="ic-Form-message ic-Form-message--error">
              <div className="ic-Form-message__Layout">
                <i className="icon-warning" role="presentation"></i>
                {error}
              </div>
            </div>
          }
          {!!hint && hintElement}
        </div>
      );
    }
  });
  return IcInput;
});
