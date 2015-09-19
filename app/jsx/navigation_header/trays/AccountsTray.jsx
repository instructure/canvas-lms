/** @jsx React.DOM */

define([
  'i18n!new_nav',
  'react',
  'jsx/shared/SVGWrapper'
], (I18n, React, SVGWrapper) => {

  var AccountsTray = React.createClass({
    propTypes: {
      accounts: React.PropTypes.array.isRequired,
      closeTray: React.PropTypes.func.isRequired,
      hasLoaded: React.PropTypes.bool.isRequired
    },

    getDefaultProps() {
      return {
        accounts: []
      };
    },

    renderAccounts() {
      if (!this.props.hasLoaded) {
        return (
          <li className="ReactTray__loading-list-item">
            {I18n.t('Loading')} &hellip;
          </li>
        );
      }
      var accounts = this.props.accounts.map((account) => {
        return <li key={account.id}><a href={`/accounts/${account.id}`}>{account.name}</a></li>;
      });
      accounts.push(<li key='allAccountLink' className='ReactTray__feature-list-item'><a href='/accounts'>{I18n.t('All Accounts')}</a></li>);
      return accounts;
    },

    render() {
      return (
        <div>
          <div className="ReactTray__header">
            <h1 className="ReactTray__headline">{I18n.t('Admin')}</h1>
            <button className="Button Button--icon-action ReactTray__closeBtn" type="button" onClick={this.props.closeTray}>
              <i className="icon-x"></i>
              <span className="screenreader-only">{I18n.t('Close')}</span>
            </button>
          </div>
          <ul className="ReactTray__link-list">
            {this.renderAccounts()}
          </ul>
        </div>
      );
    }
  });

  return AccountsTray;

});
