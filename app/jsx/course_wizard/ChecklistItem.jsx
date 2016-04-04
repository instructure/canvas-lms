define([
  'react',
  'i18n!course_wizard',
  'classnames'
], function(React, I18n, classnames) {

  var ChecklistItem = React.createClass({
      displayName: 'ChecklistItem',

      propTypes: {
        onClick: React.PropTypes.func.isRequired,
        stepKey: React.PropTypes.string.isRequired,
        title: React.PropTypes.string.isRequired,
        complete: React.PropTypes.bool.isRequired,
        isSelected: React.PropTypes.bool.isRequired,
        id: React.PropTypes.string.isRequired
      },

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
        this.props.onClick(this.props.stepKey);
      },

      setClassName: function (props) {
        this.setState({
          classNameString: classnames({
            "ic-wizard-box__content-trigger": true,
            "ic-wizard-box__content-trigger--checked": props.complete,
            "ic-wizard-box__content-trigger--active": props.isSelected
          })
        });
      },

      render: function () {
          var completionMessage = (this.props.complete) ? I18n.t('(Item Complete)') : I18n.t('(Item Incomplete)');

        return (
          <li>
            <a href='#' id={this.props.id} className={this.state.classNameString} onClick={this.handleClick} aria-label={"Select task: " + this.props.title}>
              <span>
                {this.props.title}
                <span className='screenreader-only'>{completionMessage}</span>
              </span>
            </a>
          </li>
        );
      }

  });

  return ChecklistItem;

});
