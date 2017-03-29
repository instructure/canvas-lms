import React from 'react'
import _ from 'underscore'
import classnames from 'classnames'

const { string, any, bool } = React.PropTypes
let idCount = 0
const IcInputPropTypes = {
  error: string,
  label: string,
  hint: string,
  elementType: any,
  controlClassName: string,
  appendLabel: bool,
  noClassName: bool
}

  /**
   * An input wrapped with appropriate ic-Form-* elements and classes,
   * with support for a label, error message and extra classes on the
   * wrapping div.
   *
   * All other props are passed through to the <input />
   */
  class IcInput extends React.Component {
    static propTypes = IcInputPropTypes
    static defaultProps = {
      elementType: 'input'
    }

    componentWillMount () {
      this.id = `ic_input_${idCount++}`;
    }

    render () {
      const { error, label, hint, elementType, appendLabel, controlClassName, noClassName } = this.props
      const inputProps = Object.assign({}, _.omit(this.props, Object.keys(IcInputPropTypes)), {id: this.id})
      if (elementType === "input" && !this.props.type) {
        inputProps.type = "text";
      }
      if (!noClassName) {
        inputProps.className = classnames(inputProps.className, "ic-Input");
      }

      const labelElement = label &&
        <label htmlFor={this.id} className="ic-Label">{label}</label>;

      const hintElement = !!hint && <div className="ic-Form-help-text">{hint}</div>

      return (
        <div className={classnames('ic-Form-control', controlClassName, {'ic-Form-control--has-error': error})}>
          {!!label && !appendLabel && labelElement}
          {React.createElement(elementType, inputProps)}
          {!!label && appendLabel && labelElement}
          {!!error &&
            <div className="ic-Form-message ic-Form-message--error">
              <div className="ic-Form-message__Layout">
                <i className="icon-warning" role="presentation" />
                {error}
              </div>
            </div>
          }
          {!!hint && hintElement}
        </div>
      );
    }
  }

export default IcInput
