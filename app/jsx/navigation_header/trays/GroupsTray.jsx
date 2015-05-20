/** @jsx React.DOM */

define([
  'i18n!new_nav',
  'react',
  'jsx/shared/SVGWrapper'
], (I18n, React, SVGWrapper) => {

  var GroupsTray = React.createClass({
    propTypes: {
      groups: React.PropTypes.array.isRequired,
      closeTray: React.PropTypes.func.isRequired
    },

    getDefaultProps() {
      return {
        groups: []
      };
    },

    renderGroups() {
      return this.props.groups.map((group) => {
        return <li key={group.id}><a href={`/groups/${group.id}`}>{group.name}</a></li>;
      });
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
            {this.renderGroups()}
          </ul>
        </div>
      );
    }
  });

  return GroupsTray;

});
