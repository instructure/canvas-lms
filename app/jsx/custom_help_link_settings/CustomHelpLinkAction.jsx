 define([
  'react',
  'react-dom',
  './CustomHelpLinkPropTypes'
], function(React, ReactDOM, CustomHelpLinkPropTypes) {
  const CustomHelpLinkAction = React.createClass({
    propTypes: {
      link: CustomHelpLinkPropTypes.link.isRequired,
      label: React.PropTypes.string.isRequired,
      iconClass: React.PropTypes.string.isRequired,
      onClick: React.PropTypes.func
    },
    handleClick (e) {
      if (typeof this.props.onClick === 'function') {
        this.props.onClick(this.props.link)
      } else {
        e.preventDefault();
      }
    },
    focus () {
      const node = ReactDOM.findDOMNode(this);

      if (node && !node['aria-disabled']) {
        node.focus();
      }
    },
    render () {
      return (
        <button
          type="button"
          className="Button Button--icon-action ic-Sortable-sort-controls__button"
          onClick={this.handleClick}
          aria-disabled={this.props.onClick ? null : true}
        >
          <span className="screenreader-only">
            {this.props.label}
          </span>
          <i className={this.props.iconClass} aria-hidden="true"></i>
        </button>
      )
    }
  });

  return CustomHelpLinkAction;
});
