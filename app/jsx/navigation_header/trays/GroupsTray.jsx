/** @jsx React.DOM */

define([
  'i18n!new_nav',
  'react',
  'jsx/shared/SVGWrapper'
], (I18n, React, SVGWrapper) => {

  var GroupsTray = React.createClass({
    propTypes: {
      groups: React.PropTypes.array.isRequired,
      closeTray: React.PropTypes.func.isRequired,
      hasLoaded: React.PropTypes.bool.isRequired
    },

    getDefaultProps() {
      return {
        groups: []
      };
    },

    renderCurrentGroups() {
      if (!this.props.hasLoaded) {
        return (
          <li className="ReactTray__loading-list-item">
            {I18n.t('Loading')} &hellip;
          </li>
        );
      }
      var groups =  this.props.groups.map((group) => {
        if (!group.concluded) {
          return <li key={group.id}><a href={`/groups/${group.id}`}>{group.name}</a></li>;
        };
      });
      groups.push(<li key='allGroupsLink' className='ReactTray__feature-list-item'><a href='/groups'>{I18n.t('All Groups')}</a></li>);
      return groups;
    },

    render() {
      return (
        <div>
          <div className="ReactTray__header">
            <h1 className="ReactTray__headline">{I18n.t('Groups')}</h1>
            <button className="Button Button--icon-action ReactTray__closeBtn" type="button" onClick={this.props.closeTray}>
              <i className="icon-x"></i>
              <span className="screenreader-only">{I18n.t('Close')}</span>
            </button>
          </div>
          <ul className="ReactTray__link-list">
            {this.renderCurrentGroups()}
          </ul>
        </div>
      );
    }
  });

  return GroupsTray;

});
