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
      return (
        <div className="grid-row">
          <div className="col-xs-12">
            <label className="checkbox text-left">
              <input type="checkbox" data-rel={this.props.name} onChange={this.props.handleChange} /> {this.props.description}
            </label>
          </div>
        </div>
      );
    },

    text() {
      return (
        <div className="grid-row">
          <div className="col-xs-12">
            <label className="text-left">{this.props.description}</label>
            <input type="text"
              className="form-control input-block-level"
              placeholder={this.props.description}
              defaultValue={this.props.value}
              required={this.props.required}
              data-rel={this.props.name}
              onChange={this.props.handleChange} />
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