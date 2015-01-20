/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'jquery',
  'underscore',
  'react',
  'jsx/external_apps/mixins/InputMixin'
], function (I18n, $, _, React, InputMixin) {

  return React.createClass({
    displayName: 'SelectInput',

    mixins: [InputMixin],

    propTypes: {
      defaultValue: React.PropTypes.string,
      allowBlank:   React.PropTypes.bool,
      values:       React.PropTypes.object,
      label:        React.PropTypes.string,
      id:           React.PropTypes.string,
      required:     React.PropTypes.bool,
      hintText:     React.PropTypes.string,
      errors:       React.PropTypes.object
    },

    renderSelectOptions() {
      var options = _.map(this.props.values, function(v, k) {
        return <option key={k} value={k}>{v}</option>
      }.bind(this));
      if (this.props.allowBlank) {
        options.unshift(<option key="NO_VALUE" value={null}></option>);
      }
      return options;
    },

    handleSelectChange(e) {
      e.preventDefault();
      this.setState({ value: e.target.value });
    },

    render() {
      return (
        <div className={this.getClassNames()}>
          <label>
            {this.props.label}
            <select ref="input" className="form-control input-block-level"
              defaultValue={this.props.defaultValue}
              required={this.props.required ? "required" : null}
              onChange={this.handleSelectChange}
              aria-invalid={!!this.getErrorMessage()}>
              {this.renderSelectOptions()}
            </select>
            {this.renderHint()}
          </label>
        </div>
      )
    }
  });
});