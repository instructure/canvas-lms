/** @jsx React.DOM */

define([
  'react',
  'jsx/shared/SVGWrapper'
], (React, SVGWrapper) => {

  var MenuItem = React.createClass({
    propTypes: {
      id: React.PropTypes.string.isRequired,
      href: React.PropTypes.string.isRequired,
      icon: React.PropTypes.string,
      text: React.PropTypes.string.isRequired,
      haspopup: React.PropTypes.bool,
      onClick: React.PropTypes.func,
      onKeyPress: React.PropTypes.func,
      isActive: React.PropTypes.bool,
      showBadge: React.PropTypes.bool,
      badgeCount: React.PropTypes.number,
      avatar: React.PropTypes.string
    },

    getDefaultProps() {
      return {
        haspopup: false,
        onClick: null,
        onKeyPress: null,
        isActive: false,
        showBadge: false,
        badgeCount: 0,
        avatar: null
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
      var classes = 'menu-item ic-app-header__menu-list-item';

      if (this.props.isActive) {
        classes += ' ic-app-header__menu-list-item--active';
      }

      return (
        <li id={this.props.id} role="menuitem" className={classes}>
          <a href={this.props.href}
             aria-haspopup={this.props.haspopup}
             className="menu-item-no-drop ic-app-header__menu-list-link"
             onClick={this.handleLinkClick}
             onKeyPress={this.handleLinkKeyPress}
             onMouseOver={this.props.onHover}
          >
            <div className="menu-item-icon-container">
              {!this.props.avatar && !!this.props.icon && (
                <SVGWrapper url={this.props.icon}/>
              )}

              {!!this.props.avatar && (
                <div className="ic-avatar">
                  <img src={this.props.avatar} className="ic-avatar__image" alt=""/>
                </div>
              )}

              {this.props.showBadge && (
                <span className="menu-item__badge" style={{display: this.props.badgeCount === 0 ? 'none' : ''}}>{this.props.badgeCount}</span>
              )}

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
