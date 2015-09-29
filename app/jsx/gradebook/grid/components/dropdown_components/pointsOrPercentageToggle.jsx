/** @jsx React.DOM */
define([
  'react',
  'bower/reflux/dist/reflux',
  'i18n!gradebook',
  'jsx/gradebook/grid/components/dropdown_components/headerDropdownOption',
  'jsx/gradebook/grid/stores/gradebookToolbarStore',
  'jsx/gradebook/grid/actions/gradebookToolbarActions',
  'compiled/gradebook2/GradeDisplayWarningDialog',
], function (React, Reflux, I18n, HeaderDropdownOption, GradebookToolbarStore, GradebookToolbarActions, GradeDisplayWarningDialog) {

  var PointsOrPercentageToggle = React.createClass({
    propTypes: {},

    mixins:[Reflux.connect(GradebookToolbarStore, 'toolbarOptions')],

    totalShowingAsPoints() {
      return this.state.toolbarOptions.showTotalGradeAsPoints;
    },

    toggle() {
      var showAsPoints = !this.totalShowingAsPoints();
      GradebookToolbarActions.showTotalGradeAsPoints(showAsPoints);
    },

    toggleAndHideWarning() {
      this.toggle();
      GradebookToolbarActions.hideTotalDisplayWarning(true);
    },

    changeTotalDisplay(event) {
      event.preventDefault();
      var showWarning = !this.state.toolbarOptions.warnedAboutTotalsDisplay,
          dialogOptions;
      if (showWarning) {
        dialogOptions = { showing_points: this.totalShowingAsPoints(),
          unchecked_save: this.toggle, checked_save: this.toggleAndHideWarning };
        new GradeDisplayWarningDialog(dialogOptions);
      } else {
        this.toggle();
      }
    },

    render() {
      var title = this.totalShowingAsPoints() ?
        I18n.t('Switch to Percentage') : I18n.t('Switch to Points');
      return(
        <HeaderDropdownOption key='pointsOrPercentage'
          title={title} dataAction='pointsOrPercentage'
          handleClick={this.changeTotalDisplay}
          ref='dropdownOption'/>
      );
    }
  });

  return PointsOrPercentageToggle;
});
