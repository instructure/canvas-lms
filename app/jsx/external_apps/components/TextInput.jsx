/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'jquery',
  'react',
  'jsx/external_apps/mixins/InputMixin'
], function (I18n, $, React, InputMixin) {

  return React.createClass({
    displayName: 'TextInput',

    mixins: [InputMixin],

    propTypes: {
      defaultValue: React.PropTypes.string,
      label:        React.PropTypes.string,
      id:           React.PropTypes.string,
      required:     React.PropTypes.bool,
      hintText:     React.PropTypes.string,
      errors:       React.PropTypes.object
    },

    render() {
      return (
        <div className={this.getClassNames()}>
          <label>
            {this.props.label}
            <input ref="input" type="text" defaultValue={this.state.value}
              className="form-control input-block-level"
              placeholder={this.props.label}
              required={this.props.required ? "required" : null}
              onChange={this.handleChange}
              aria-invalid={!!this.getErrorMessage()} />
            {this.renderHint()}
          </label>
        </div>
      )
    }
  });
});