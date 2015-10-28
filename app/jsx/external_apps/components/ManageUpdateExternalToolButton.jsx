define([
  'jquery',
  'i18n!external_tools',
  'react',
  'jsx/external_apps/components/Lti2ReregistrationUpdateModal',
  'jsx/external_apps/lib/ExternalAppsStore'
], function ($, I18n, React, Lti2ReregistrationUpdateModal, store) {

  return React.createClass({
    displayName: 'ManageUpdateExternalToolButton',

    propTypes: {
      tool: React.PropTypes.object.isRequired
    },

    openReregModal(e) {
      this.refs.reregModal.openModal(e)
    },

    render() {
      var updateAriaLabel = I18n.t('Manage update for %{toolName}', { toolName: this.props.tool.name });

      var cssClassName = this.props.tool.has_update ? "" : " hide"
      return (
        <li role="presentation" className={"EditExternalToolButton ui-menu-item" + cssClassName}  >
          <a href="#" ref="updateButton" tabIndex="-1" role="menuitem" aria-label={updateAriaLabel} className="icon-upload" onClick={this.openReregModal}>
            {I18n.t('Manage Update')}
          </a>
          <Lti2ReregistrationUpdateModal ref="reregModal" tool={this.props.tool}  />
        </li>
      )
    }
  });
});
