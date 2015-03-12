/** @jsx React.DOM */

define([
  'old_unsupported_dont_use_react',
  'i18n!course_wizard'
], function(React, I18n) {

  var ChecklistItem = React.createClass({
      displayName: 'ChecklistItem',

      classNameString: '',

      getInitialState: function () {
        return {classNameString: ''};
      },

      componentWillMount: function () {
        this.setClassName(this.props);
      },

      componentWillReceiveProps: function (nextProps) {
        this.setClassName(nextProps);
      },

      handleClick: function (event) {
        event.preventDefault();
        this.props.onClick(this.props.key)
      },

      setClassName: function (props) {
        this.setState({
          classNameString: React.addons.classSet({
            "ic-wizard-box__content-trigger": true,
            "ic-wizard-box__content-trigger--checked": props.complete,
            "ic-wizard-box__content-trigger--active": props.isSelected
          })
        });
      },

      render: function () {
          var completionMessage = (this.props.complete) ? I18n.t('(Item Complete)') : I18n.t('(Item Incomplete)');

          return (
              <a href="#" id={this.props.id} className={this.state.classNameString} onClick={this.handleClick}>
                <span>
                  {this.props.title}
                  <span className="screenreader-only">{completionMessage}</span>
                </span>
              </a>
          );
      }

  });

  return ChecklistItem;

});