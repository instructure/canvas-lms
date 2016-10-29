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
          <li className="ic-NavMenu-list-item ic-NavMenu-list-item--loading-message">
            {I18n.t('Loading')} &hellip;
          </li>
        );
      }
      var accounts = this.props.accounts.map((account) => {
        return (
          <li key={account.id} className='ic-NavMenu-list-item'>
            <a href={`/accounts/${account.id}`} className='ic-NavMenu-list-item__link'>{account.name}</a>
          </li>
        );
      });
      accounts.push(
        <li key='allAccountLink' className='ic-NavMenu-list-item ic-NavMenu-list-item--feature-item'>
          <a href='/accounts' className='ic-NavMenu-list-item__link'>{I18n.t('All Accounts')}</a>
        </li>
      );
      return accounts;
    },

    render() {
      return (
        <div>
          <div className="ic-NavMenu__header">
            <h1 className="ic-NavMenu__headline">{I18n.t('Admin')}</h1>
            <button className="Button Button--icon-action ic-NavMenu__closeButton" type="button" onClick={this.props.closeTray}>
              <i className="icon-x"></i>
              <span className="screenreader-only">{I18n.t('Close')}</span>
            </button>
          </div>
          <ul className="ic-NavMenu__link-list">
            {this.renderAccounts()}
          </ul>
        </div>
      );
    }
  });

  return AccountsTray;

});
