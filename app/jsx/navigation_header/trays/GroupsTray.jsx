/** @jsx React.DOM */

define([
  'i18n!new_nav',
  'react',
  'jsx/shared/SVGWrapper'
], (I18n, React, SVGWrapper) => {

  SVGWrapper = React.createFactory(SVGWrapper);

  var GroupsTray = React.createClass({
    propTypes: {
      groups: React.PropTypes.array.isRequired
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
          <h1>{I18n.t('Groups')}</h1>
          <ul>
            {this.renderGroups()}
          </ul>
        </div>
      );
    }
  });

  return GroupsTray;

});
