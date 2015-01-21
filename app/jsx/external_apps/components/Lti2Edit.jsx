/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'jquery',
  'old_unsupported_dont_use_react',
  'str/htmlEscape'
], function (I18n, $, React, htmlEscape) {

  return React.createClass({
    displayName: 'Lti2Edit',

    propTypes: {
      tool: React.PropTypes.object.isRequired,
      handleActivateLti2: React.PropTypes.func.isRequired,
      handleDeactivateLti2: React.PropTypes.func.isRequired,
      handleCancel: React.PropTypes.func.isRequired
    },

    toggleButton() {
      if (this.props.tool.enabled === false) {
        return <button type="button" className="btn btn-primary" onClick={this.props.handleActivateLti2}>{I18n.t('Enable')}</button>;
      } else {
        return <button type="button" className="btn btn-primary" onClick={this.props.handleDeactivateLti2}>{I18n.t('Disable')}</button>;
      }
    },

    render() {
      var p1 = I18n.t(
        '*name* is currently **status**.',
        { wrappers: [
          '<strong>' + htmlEscape(this.props.tool.name) + '</strong>',
          (this.props.tool.enabled === false ? 'disabled' : 'enabled')
        ]}
      );
      return (
        <div className="Lti2Permissions">
          <div className="ReactModal__InnerSection ReactModal__Body--force-no-corners ReactModal__Body">
            <p dangerouslySetInnerHTML={{ __html: p1 }}></p>
          </div>
          <div className="ReactModal__InnerSection ReactModal__Footer">
            <div className="ReactModal__Footer-Actions">
              {this.toggleButton()}
              <button type="button" className="btn btn-secondary" onClick={this.props.handleCancel}>{I18n.t("Cancel")}</button>
            </div>
          </div>
        </div>
      )
    }
  });

});