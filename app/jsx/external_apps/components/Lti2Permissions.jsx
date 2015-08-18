/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'react',
  'str/htmlEscape'
], function (I18n, React, htmlEscape) {

  return React.createClass({
    displayName: 'Lti2Permissions',

    propTypes: {
      tool: React.PropTypes.object.isRequired,
      handleCancelLti2: React.PropTypes.func.isRequired,
      handleActivateLti2: React.PropTypes.func.isRequired
    },

    render() {
      var p1 = I18n.t(
        '*name* has been successfully installed but has not yet been enabled.',
        { wrappers: [
          '<strong>' + htmlEscape(this.props.tool.name) + '</strong>'
        ]}
      );
      return (
        <div className="Lti2Permissions">
          <div className="ReactModal__InnerSection ReactModal__Body--force-no-corners ReactModal__Body">
            <p dangerouslySetInnerHTML={{ __html: p1 }}></p>
            <p>{I18n.t('Would you like to enable this app?')}</p>
          </div>
          <div className="ReactModal__InnerSection ReactModal__Footer">
            <div className="ReactModal__Footer-Actions">
              <button type="button" className="btn btn-primary" onClick={this.props.handleActivateLti2}>{I18n.t('Enable')}</button>
              <button type="button" className="btn btn-secondary" onClick={this.props.handleCancelLti2}>{I18n.t("Delete")}</button>
            </div>
          </div>
        </div>
      )
    }
  });

});