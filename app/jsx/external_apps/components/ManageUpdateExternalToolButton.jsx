import $ from 'jquery'
import I18n from 'i18n!external_tools'
import React from 'react'
import Lti2ReregistrationUpdateModal from 'jsx/external_apps/components/Lti2ReregistrationUpdateModal'
import store from 'jsx/external_apps/lib/ExternalAppsStore'

export default React.createClass({
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
