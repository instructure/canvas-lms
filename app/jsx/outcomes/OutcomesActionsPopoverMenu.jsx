define([
  'react',
  'react-dom',
  'i18n!outcomes',
  'instructure-ui/PopoverMenu',
  'instructure-ui/Button',
  'instructure-ui/Menu',
  'instructure-ui/ScreenReaderContent',
  'jsx/outcomes/AddToCourseModal'
], (React, ReactDOM, I18n, { default: PopoverMenu }, { default: Button }, { default: Menu, MenuItem, MenuItemSeparator }, { default: ScreenReaderContent }, AddToCourseModal) => {

  return React.createClass({
    propTypes: {
      contextUrlRoot: React.PropTypes.string,
      permissions: React.PropTypes.object
    },
    getInitialState: function () {
      this._applicationContainer = document.querySelector("#application");
      var menuItems = [];
      if (this._hasPermission(this.props.permissions, "manage_rubrics")) {
        menuItems.push({
          key: "manage-rubrics",
          onSelect: this.onManageRubricsSelected,
          name: I18n.t("Manage Rubrics")
        });
      }

      // TODO Enable this option once we continue work on OUT-402
      // if (this._hasPermission(this.props.permissions, "manage_courses")) {
      //   menuItems.push({
      //     key: "add-to-course",
      //     onSelect: this.onAddToCourseSelected,
      //     name: I18n.t("Add to course...")
      //   });
      // }

      return {
        menuItems: menuItems
      };
    },
    render: function () {
      if (this.state.menuItems.length > 0) {
        var renderedMenuItems = this.state.menuItems.map(function (menuItem) {
          return <MenuItem key={menuItem.key} onSelect={menuItem.onSelect}>{menuItem.name}</MenuItem>
        });

        return (
          <span>
            <PopoverMenu ref="popovermenu" trigger={<Button><ScreenReaderContent>{I18n.t("Additional outcomes options")}</ScreenReaderContent>&hellip;</Button>}>
              {renderedMenuItems}
            </PopoverMenu>
            <AddToCourseModal ref={this._saveModal} onClose={this._handleModalClose} onReady={this._handleModalReady} />
          </span>
        );
      }
      return null;
    },
    onManageRubricsSelected: function () {
      window.location.href = this.props.contextUrlRoot + "/rubrics";
    },
    onAddToCourseSelected: function () {
      this._addToCourseModal.open();
    },
    _hasPermission: function (permissions, permissionName) {
      return permissions && permissions[permissionName];
    },
    _saveModal: function (modal) {
      this._addToCourseModal = modal;
    },
    _handleModalReady: function () {
      this._applicationContainer.setAttribute('aria-hidden', 'true')
    },
    _handleModalClose: function () {
      this._applicationContainer.removeAttribute('aria-hidden');
      this.refs.popovermenu.focus();
    }
  });
});