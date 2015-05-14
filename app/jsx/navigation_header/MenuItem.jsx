/** @jsx React.DOM */

define([
  'react',
  'jsx/shared/SVGWrapper'
], (React, SVGWrapper) => {

  SVGWrapper = React.createFactory(SVGWrapper);

  var MenuItem = React.createClass({
    propTypes: {
      id: React.PropTypes.string.isRequired,
      href: React.PropTypes.string.isRequired,
      icon: React.PropTypes.string.isRequired,
      text: React.PropTypes.string.isRequired,
      haspopup: React.PropTypes.bool,
      onClick: React.PropTypes.func,
      onKeyPress: React.PropTypes.func
    },

    getDefaultProps() {
      return {
        haspopup: false,
        onClick: null,
        onKeyPress: null
      };
    },

    handleLinkClick(e) {
      if (typeof this.props.onClick === 'function') {
        e.preventDefault();
        this.props.onClick();
      }
    },

    handleLinkKeyPress(e) {
      if (typeof this.props.onKeyPress === 'function' &&
          (e.which === 13 || e.which === 32)) {
        e.preventDefault();
        this.props.onKeyPress();
      }
    },

    render() {
      return (
        <li id={this.props.id} role="menuitem" className="menu-item ic-app-header__menu-list-item">
          <a href={this.props.href}
             aria-haspopup={this.props.haspopup}
             className="menu-item-no-drop ic-app-header__menu-list-link"
             onClick={this.handleLinkClick}
             onKeyPress={this.handleLinkKeyPress}
          >
            <div className="menu-item-icon-container">
              <SVGWrapper url={this.props.icon}/>
            </div>
            <div className="menu-item__text">
              {this.props.text}
            </div>
          </a>
        </li>
      );
    }
  });

  return MenuItem;

});
