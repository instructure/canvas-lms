define([
  'i18n!react_files',
  'react',
  'react-dom',
  'compiled/react_files/modules/customPropTypes',
  'compiled/models/Folder',
  'compiled/react_files/modules/filesEnv',
  'jsx/files/UsageRightsDialog'
], function (I18n, React, ReactDOM, customPropTypes, Folder, filesEnv, UsageRightsDialog) {

  var UsageRightsIndicator = React.createClass({
    displayName: 'UsageRightsIndicator',

    warningMessage: I18n.t('Before publishing this file, you must specify usage rights.'),

    propTypes: {
      model: customPropTypes.filesystemObject.isRequired,
      userCanManageFilesForContext: React.PropTypes.bool.isRequired,
      usageRightsRequiredForContext: React.PropTypes.bool.isRequired,
      modalOptions: React.PropTypes.object.isRequired
    },

    handleClick (event) {
      event.preventDefault();
      var contents = (
        <UsageRightsDialog
          closeModal={this.props.modalOptions.closeModal}
          itemsToManage={[this.props.model]}
        />
      );
      this.props.modalOptions.openModal(contents, () => {
        React.findDOMNode(this).focus();
      });
    },

    getIconData (useJustification) {
      switch (useJustification) {
        case 'own_copyright':
          return {iconClass: 'icon-files-copyright', text: I18n.t('Own Copyright')};
        case 'public_domain':
          return {iconClass: 'icon-files-public-domain', text: I18n.t('Public Domain')};
        case 'used_by_permission':
          return {iconClass: 'icon-files-obtained-permission', text: I18n.t('Used by Permission')};
        case 'fair_use':
          return {iconClass: 'icon-files-fair-use', text: I18n.t('Fair Use')};
        case 'creative_commons':
          return {iconClass: 'icon-files-creative-commons', text: I18n.t('Creative Commons')};
      }
    },

    render () {
      if ((this.props.model instanceof Folder) || (!this.props.usageRightsRequiredForContext && !this.props.model.get('usage_rights'))) {
        return null;
      } else if (this.props.usageRightsRequiredForContext && !this.props.model.get('usage_rights')) {
        if (this.props.userCanManageFilesForContext) {
          return (
            <button
              className='UsageRightsIndicator__openModal btn-link'
              onClick={this.handleClick}
              title={this.warningMessage}
              data-tooltip='top'
            >
              <span className='screenreader-only'>
                {this.warningMessage}
              </span>
              <i className='UsageRightsIndicator__warning icon-warning' />
            </button>
          );
        } else {
          return null;
        }
      } else {
        var useJustification = this.props.model.get('usage_rights').use_justification;
        var iconData = this.getIconData(useJustification);

        return (
          <button
            className='UsageRightsIndicator__openModal btn-link'
            onClick={this.handleClick}
            disabled={!this.props.userCanManageFilesForContext}
            title={this.props.model.get('usage_rights').license_name}
            data-tooltip='top'
          >
            <span
              ref='screenreaderText'
              className='screenreader-only'
            >
              {iconData.text}
            </span>
            <span className='screenreader-only'>
              {this.props.model.get('usage_rights').license_name}
            </span>
            <i ref='icon' className={iconData.iconClass} />
          </button>
        );
      }
    }
  });

  return UsageRightsIndicator;
});
