/** @jsx React.DOM */
define([
  'react',
  'underscore',
  'i18n!gradebook',
  './headerDropdownOption',
  './currentOrFinalGradeToggle',
  './moveTotalColumnToggle'
], function (React, _, I18n, HeaderDropdownOption, CurrentOrFinalGradeToggle, MoveTotalColumnToggle) {

  var TotalHeaderDropdownOptions = React.createClass({

    propTypes: {
      idAttribute: React.PropTypes.string.isRequired
    },

    render() {
      return (
        <ul id={this.props.idAttribute} className="gradebook-header-menu">
          <HeaderDropdownOption ref="switchToPoints" key='switchToPoints' title={I18n.t('Switch to Points')} />
          <MoveTotalColumnToggle ref="moveToFront" key='moveTotalColumn' />
          <CurrentOrFinalGradeToggle key='currentOrFinalToggle' ref='currentOrFinalToggle'/>
        </ul>
      );
    }
  });

  return TotalHeaderDropdownOptions;
});
