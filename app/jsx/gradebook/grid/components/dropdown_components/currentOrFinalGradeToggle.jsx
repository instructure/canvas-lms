/** @jsx React.DOM */
define([
  'react',
  'bower/reflux/dist/reflux',
  'i18n!gradebook',
  'jsx/gradebook/grid/stores/gradebookToolbarStore',
  'jsx/gradebook/grid/actions/gradebookToolbarActions',
  'jsx/gradebook/grid/components/dropdown_components/headerDropdownOption'
], function (React, Reflux, I18n, GradebookToolbarStore, GradebookToolbarActions, HeaderDropdownOption) {

  var CurrentOrFinalGradeToggle = React.createClass({
    mixins: [
      Reflux.connect(GradebookToolbarStore, 'toolbarOptions'),
    ],

    showFinalGrade() {
      return this.state.toolbarOptions.treatUngradedAsZero;
    },

    toggle(event) {
      event.preventDefault();
      var showFinalGrade = !this.showFinalGrade();
      GradebookToolbarActions.toggleTreatUngradedAsZero(showFinalGrade);
    },

    render() {
      var text = this.showFinalGrade() ? I18n.t('Show Current Grade') : I18n.t('Show Final Grade');
      return (
        <HeaderDropdownOption title={text} handleClick={this.toggle} ref='gradeToggle'/>
      );
    }
  });

  return CurrentOrFinalGradeToggle;
});
