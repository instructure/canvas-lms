/** @jsx React.DOM */
define([
  'react',
  'i18n!gradebook',
  'jsx/gradebook/grid/components/dropdown_components/currentOrFinalGradeToggle',
  'jsx/gradebook/grid/components/dropdown_components/pointsOrPercentageToggle',
  'jsx/gradebook/grid/components/dropdown_components/moveTotalColumnToggle',
  'jsx/gradebook/grid/constants'
], function (React, I18n, CurrentOrFinalGradeToggle, PointsOrPercentageToggle, MoveTotalColumnToggle, GradebookConstants) {

  var TotalHeaderDropdownOptions = React.createClass({

    propTypes: {
      idAttribute: React.PropTypes.string.isRequired
    },

    render() {
      var moveToFrontToggle = { title: I18n.t('Move to Front'), action: 'moveToFront' },
          showPointsToggle  = GradebookConstants.group_weighting_scheme !== 'percent';
      return (
        <ul id={this.props.idAttribute} className="gradebook-header-menu">
          {showPointsToggle &&
            <PointsOrPercentageToggle key='pointsOrPercentageToggle' ref='switchToPoints'/>}
          <MoveTotalColumnToggle key='moveTotalColumn' ref='moveToFront'/>
          <CurrentOrFinalGradeToggle key='currentOrFinalToggle' ref='currentOrFinalToggle'/>
        </ul>
      );
    }
  });

  return TotalHeaderDropdownOptions;
});
