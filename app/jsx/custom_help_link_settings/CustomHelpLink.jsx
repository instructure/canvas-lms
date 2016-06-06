 define([
  'react',
  'react-dom',
  'i18n!custom_help_link',
  './CustomHelpLinkPropTypes',
  './CustomHelpLinkHiddenInputs',
  './CustomHelpLinkAction'
], function(
    React,
    ReactDOM,
    I18n,
    CustomHelpLinkPropTypes,
    CustomHelpLinkHiddenInputs,
    CustomHelpLinkAction
  ) {
  const CustomHelpLink = React.createClass({
    propTypes: {
      link: CustomHelpLinkPropTypes.link.isRequired,
      onMoveUp: React.PropTypes.func,
      onMoveDown: React.PropTypes.func,
      onEdit: React.PropTypes.func,
      onRemove: React.PropTypes.func
    },
    getInitialState () {
      return {
        shouldFocus: this.props.shouldFocus
      };
    },
    focus (action) {
      const ref = this.actions[action];

      if (ref) {
        ref.focus();
      } else { // focus the first focusable element
        const focusable = this.focusable();
        if (focusable) {
          focusable.focus();
        }
      }
    },
    focusable () {
      const focusable = ReactDOM.findDOMNode(this).querySelectorAll('button:not([aria-disabled])');
      return focusable[0];
    },
    render () {
      const {
        text
      } = this.props.link;

      this.actions = {};

      return (
        <li className="ic-Sortable-item">
          <div className="ic-Sortable-item__Text">
            {text}
          </div>
          <div className="ic-Sortable-item__Actions">
            <div className="ic-Sortable-sort-controls">
              <CustomHelpLinkAction
                ref={(c) => this.actions['moveUp'] = c}
                link={this.props.link}
                label={I18n.t('Move %{text} up', { text })}
                onClick={this.props.onMoveUp}
                iconClass="icon-mini-arrow-up"
              />
              <CustomHelpLinkAction
                ref={(c) => this.actions['moveDown'] = c}
                link={this.props.link}
                label={I18n.t('Move %{text} down', { text })}
                onClick={this.props.onMoveDown}
                iconClass="icon-mini-arrow-down"
              />
            </div>
            <CustomHelpLinkAction
              ref={(c) => this.actions['edit'] = c}
              link={this.props.link}
              label={I18n.t('Edit %{text}', { text })}
              onClick={this.props.onEdit}
              iconClass="icon-edit"
            />
            <CustomHelpLinkAction
              ref={(c) => this.actions['remove'] = c}
              link={this.props.link}
              label={I18n.t('Remove %{text}', { text })}
              onClick={this.props.onRemove}
              iconClass="icon-trash"
            />
          </div>
          <CustomHelpLinkHiddenInputs link={this.props.link} />
        </li>
      )
    }
  });

  return CustomHelpLink;
});
