import React from 'react'
import $ from 'jquery'

  var RangeInput = React.createClass({
    propTypes: {
      min:           React.PropTypes.number.isRequired,
      max:           React.PropTypes.number.isRequired,
      defaultValue:  React.PropTypes.number.isRequired,
      labelText:     React.PropTypes.string.isRequired,
      name:          React.PropTypes.string.isRequired,
      step:          React.PropTypes.number,
      formatValue:   React.PropTypes.func,
      onChange:      React.PropTypes.func
    },

    getDefaultProps: function() {
      return {
        step: 1,
        onChange: function(){},
        formatValue: val => val
      };
    },

    getInitialState: function() {
      return { value: this.props.defaultValue };
    },

    /* workaround for https://github.com/facebook/react/issues/554 */
    componentDidMount: function() {
      // https://connect.microsoft.com/IE/Feedback/Details/856998
      $(this.refs.rangeInput.getDOMNode()).on('input change', this.handleChange);
    },

    componentWillUnmount: function() {
      $(this.refs.rangeInput.getDOMNode()).off('input change', this.handleChange);
    },
    /* end workaround */

    handleChange: function(event) {
      this.setState({ value: event.target.value });
      this.props.onChange(event.target.value);
    },

    render: function() {
      var {
        labelText,
        formatValue,
        onChange,
        value,
        ...props
      } = this.props;

      return (
        <label className="RangeInput">
          <div className="RangeInput__label">
            {labelText}
          </div>
          <div className="RangeInput__control">
            <input  className="RangeInput__input"
                    ref="rangeInput"
                    type="range"
                    role="slider"
                    aria-valuenow={this.props.defaultValue}
                    aria-valuemin={this.props.min}
                    aria-valuemax={this.props.max}
                    aria-valuetext={formatValue(this.state.value)}
                    onChange={function() {}}
                    {...props} />
            <output htmlFor={this.props.name} className="RangeInput__value">
              { formatValue(this.state.value) }
            </output>
          </div>
        </label>
      );
    }
  });
export default RangeInput
