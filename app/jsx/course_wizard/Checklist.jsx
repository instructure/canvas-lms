/** @jsx React.DOM */

define([
  'react',
  './ChecklistItem',
  './ListItems'
], function(React, ChecklistItem, ListItems) {

  var Checklist = React.createClass({
      displayName: 'Checklist',

      getInitialState: function () {
        return {
          selectedItem: this.props.selectedItem || ''
        }
      },

      componentWillReceiveProps: function (newProps) {
        this.setState({
          selectedItem: newProps.selectedItem
        });
      },

      renderChecklist: function () {
        return ListItems.map((item) => {
          var isSelected = this.state.selectedItem === item.key;
          var id = 'wizard_' + item.key;
          return (
            <ChecklistItem complete={item.complete}
                           id={id}
                           key={item.key}
                           stepKey={item.key}
                           title={item.title}
                           onClick={this.props.clickHandler}
                           isSelected={isSelected}
            />
          );
        });
      },

      render: function () {
        var checklist = this.renderChecklist();
          return (
            <div className={this.props.className}>{checklist}</div>
          );
      }

  });

  return Checklist;

});