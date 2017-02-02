import I18n from 'i18n!external_tools'
import $ from 'jquery'
import React from 'react'
import InputMixin from 'jsx/external_apps/mixins/InputMixin'

export default React.createClass({
    displayName: 'TextAreaInput',

    mixins: [InputMixin],

    propTypes: {
      defaultValue: React.PropTypes.string,
      label:        React.PropTypes.string,
      id:           React.PropTypes.string,
      rows:         React.PropTypes.number,
      required:     React.PropTypes.bool,
      hintText:     React.PropTypes.string,
      errors:       React.PropTypes.object
    },

    render() {
      return (
        <div className={this.getClassNames()}>
          <label>
            {this.props.label}
            <textarea ref="input" rows={this.props.rows || 3} defaultValue={this.props.defaultValue}
              className="form-control input-block-level"
              placeholder={this.props.label} id={this.props.id}
              required={this.props.required ? "required" : null}
              onChange={this.handleChange}
              aria-invalid={!!this.getErrorMessage()} />
            {this.renderHint()}
          </label>
        </div>
      )
    }
  });
