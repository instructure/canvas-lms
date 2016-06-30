define([
  'i18n!new_nav',
  'react',
  'jsx/help_dialog/HelpDialog'
], (I18n, React, HelpDialog) => {

  var HelpTray = React.createClass({
    propTypes: {
      closeTray: React.PropTypes.func.isRequired,
      links: React.PropTypes.array,
      hasLoaded: React.PropTypes.bool
    },

    getDefaultProps() {
      return {
        hasLoaded: false,
        links: []
      };
    },

    render() {
      return (
        <div id="help_tray">
          <div className="ic-NavMenu__header">
            <h1 className="ic-NavMenu__headline">
              {I18n.t('Help')}
            </h1>
            <button
              className="Button Button--icon-action ic-NavMenu__closeButton"
              type="button"
              onClick={this.props.closeTray}
            >
              <i className="icon-x" aria-hidden="true"></i>
              <span className="screenreader-only">
                {I18n.t('Close')}
              </span>
            </button>
          </div>
          <HelpDialog links={this.props.links} onFormSubmit={this.props.closeTray} />
        </div>
      );
    }
  });

  return HelpTray;
});
