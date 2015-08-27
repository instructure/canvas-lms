/** @jsx React.DOM */
define([
  'react',
  'jquery',
], function (React, $) {

  var GradebookKyleMenu = React.createClass({

    propTypes: {
      dropdownOptionsId: React.PropTypes.string.isRequired,
      idToAppendTo: React.PropTypes.string.isRequired,
      screenreaderText: React.PropTypes.string.isRequired,
      defaultClassNames: React.PropTypes.string.isRequired,
      children: React.PropTypes.element.isRequired,
      options: React.PropTypes.object
    },

    getInitialState() {
      return { showMenu: false, menuOpen: false };
    },

    handleMenuPopup(event) {
      this.setState({ menuOpen: event.type === 'popupopen' });
    },

    handleDropdownClick(event) {
      var $link = $(event.target);
      var idToAppendTo = '#' + this.props.idToAppendTo;
      var kyleMenuOptions = this.props.options || {};
      var menuId = '#' + this.props.children.props.idAttribute;
      this.setState({ showMenu: true }, function(){
        var $menu = $(menuId);
        $link.kyleMenu(kyleMenuOptions);
        $menu.appendTo(idToAppendTo).bind('popupopen popupclose', (event) => {
          this.handleMenuPopup(event);
        }).popup('open');
      });
    },

    cssClassNames() {
      var classNames = this.props.defaultClassNames;
      if (this.state.menuOpen) classNames += ' ui-menu-trigger-menu-is-open';
      return classNames;
    },

    render() {
      return (
        <div>
          <a className={this.cssClassNames()}
             href='#'
             ref='dropdownLink'
             onClick={this.handleDropdownClick}>
            {this.props.screenreaderText}
          </a>
          {this.state.showMenu && this.props.children}
        </div>
      );
    }
  });

  return GradebookKyleMenu;
});
