/** @jsx React.DOM */
define([
  'react',
  'bower/reflux/dist/reflux',
  'i18n!gradebook',
  '../stores/gradebookToolbarStore',
  '../actions/gradebookToolbarActions'

], function (React, Reflux, I18n, GradebookToolbarStore, GradebookToolbarActions) {

  var CurrentOrFinalGradeToggle = React.createClass({
    mixins: [
      Reflux.connect(GradebookToolbarStore, 'toolbarOptions'),
    ],

    showFinalGrade() {
      return this.state.toolbarOptions.treatUngradedAsZero;
    },

    toggleShowFinalGrade(event) {
      event.preventDefault();
      var showFinalGrade = !this.showFinalGrade();
      GradebookToolbarActions.toggleTreatUngradedAsZero(showFinalGrade);
    },

    render() {
      var text = this.showFinalGrade() ? I18n.t('Show Current Grade') : I18n.t('Show Final Grade');
      return (
        <li>
          <a onClick={this.toggleShowFinalGrade} href='#' ref='gradeToggle'>
            {text}
          </a>
        </li>
      );
    }
  });

  return CurrentOrFinalGradeToggle;
});
