import React from 'react'
import ChecklistItem from './ChecklistItem'
import ListItems from './ListItems'
import I18n from 'i18n!course_wizard'

  var Checklist = React.createClass({
      displayName: 'Checklist',

      propTypes: {
        selectedItem: React.PropTypes.string.isRequired,
        clickHandler: React.PropTypes.func.isRequired,
        className: React.PropTypes.string.isRequired
      },

      getInitialState: function () {
        return {
          selectedItem: this.props.selectedItem || ''
        };
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
          <div className={this.props.className}>
            <h2 className='screenreader-only'>{I18n.t('Setup Checklist')}</h2>
            <ul className='ic-wizard-box__nav-checklist'>{checklist}</ul>
          </div>
        );
      }

  });

export default Checklist
