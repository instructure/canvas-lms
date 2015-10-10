/** @jsx React.DOM */
define([
  'react',
  'bower/reflux/dist/reflux',
  'i18n!gradebook',
  'jsx/gradebook/grid/components/dropdown_components/headerDropdownOption',
  'jsx/gradebook/grid/stores/gradebookToolbarStore',
  'jsx/gradebook/grid/actions/gradebookToolbarActions'
], function (React, Reflux, I18n, HeaderDropdownOption, GradebookToolbarStore, GradebookToolbarActions) {

  const TO_END = I18n.t("Move to end"),
        TO_FRONT = I18n.t("Move to front");

  var MoveTotalColumnToggle = React.createClass({
    mixins: [
      Reflux.connect(GradebookToolbarStore, 'toolbarOptions'),
    ],

    isTotalColumnInFront() {
      return this.state.toolbarOptions.totalColumnInFront;
    },

    handleClick(event) {
      GradebookToolbarActions.toggleTotalColumnInFront(!this.isTotalColumnInFront());
    },

    render() {
      var title = (this.isTotalColumnInFront()) ? TO_END : TO_FRONT;
      return <HeaderDropdownOption key="moveToFront"
                                   title={title}
                                   handleClick={this.handleClick}
                                   ref="moveToFront"/>
    }
  });

  return MoveTotalColumnToggle;
});
