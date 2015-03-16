/** @jsx React.DOM */

define([
  'react'
], function (React) {

  return React.createClass({
    displayName: 'ConfigOptionField',

    propTypes: {
      handleChange: React.PropTypes.func.isRequired,
      name: React.PropTypes.string.isRequired,
      type: React.PropTypes.string.isRequired,
      value: React.PropTypes.any,
      required: React.PropTypes.bool,
      description: React.PropTypes.string.isRequired
    },

    checkbox() {
      var checked = this.props.value ? "checked" : "";
      return (
        <div className="grid-row">
          <div className="col-xs-12">
            <label className="checkbox">
              <input type="checkbox" name={this.props.name}  data-rel={this.props.name} onChange={this.props.handleChange} checked={checked}/> {this.props.description}
            </label>
          </div>
        </div>
      );
    },

    text() {
      return (
        <div className="grid-row">
          <div className="col-xs-12">
            <label>
              {this.props.description}
              <input type="text"
                className="form-control input-block-level"
                placeholder={this.props.description}
                defaultValue={this.props.value}
                required={this.props.required}
                data-rel={this.props.name}
                name={this.props.name}
                onChange={this.props.handleChange} />
            </label>
          </div>
        </div>
      );
    },

    render() {
      return (
        <div className="form-group">
          {this.props.type === 'checkbox' ? this.checkbox() : this.text()}
        </div>
      )
    }
  });

});