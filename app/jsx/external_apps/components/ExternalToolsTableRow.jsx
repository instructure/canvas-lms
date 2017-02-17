define([
  'underscore',
  'i18n!external_tools',
  'react',
  'jsx/external_apps/components/EditExternalToolButton',
  'jsx/external_apps/components/ManageUpdateExternalToolButton',
  'jsx/external_apps/components/ExternalToolPlacementButton',
  'jsx/external_apps/components/DeleteExternalToolButton',
  'jsx/external_apps/components/ConfigureExternalToolButton',
  'jsx/external_apps/components/ReregisterExternalToolButton',
  'jsx/external_apps/lib/classMunger',
  'jquery.instructure_misc_helpers'
], function(_, I18n, React, EditExternalToolButton, ManageUpdateExternalToolButton, ExternalToolPlacementButton, DeleteExternalToolButton, ConfigureExternalToolButton, ReregisterExternalToolButton, classMunger) {

  return React.createClass({
    displayName: 'ExternalToolsTableRow',

    propTypes: {
      tool: React.PropTypes.object.isRequired,
      canAddEdit: React.PropTypes.bool.isRequired
    },

    renderButtons() {
      if (this.props.tool.installed_locally && !this.props.tool.restricted_by_master_course) {
        var configureButton, updateBadge, updateOption, dimissUpdateOption = null;
        var reregistrationButton = null;

        if (this.props.tool.tool_configuration) {
          configureButton = <ConfigureExternalToolButton ref="configureExternalToolButton" tool={this.props.tool} />;
        }

        if(this.props.tool.has_update) {
          var badgeAriaLabel = I18n.t('An update is available for %{toolName}', { toolName: this.props.tool.name });


          updateBadge = <i className="icon-upload tool-update-badge" aria-label={badgeAriaLabel}></i>;
        }

        return (
          <td className="links text-right" nowrap="nowrap">
            {updateBadge}
            <div className={"al-dropdown__container"} >
              <a className={"al-trigger btn"} role="button" href="#">
                <i className={"icon-settings"}></i>
                <i className={"icon-mini-arrow-down"}></i>
                <span className={"screenreader-only"}>{ this.props.tool.name + ' ' + I18n.t('Settings') }</span>
              </a>
              <ul className={"al-options"} role="menu" tabIndex="0" aria-hidden="true" aria-expanded="false" >
                {configureButton}
                <ManageUpdateExternalToolButton tool={this.props.tool} />
                <EditExternalToolButton ref="editExternalToolButton" tool={this.props.tool} canAddEdit={this.props.canAddEdit}/>
                <ExternalToolPlacementButton ref="externalToolPlacementButton" tool={this.props.tool} />
                <ReregisterExternalToolButton ref="reregisterExternalToolButton" tool={this.props.tool}/>
                <DeleteExternalToolButton ref="deleteExternalToolButton" tool={this.props.tool} />
              </ul>
            </div>
          </td>
        )
      } else {
        return (
          <td className="links text-right e-tool-table-data" nowrap="nowrap" >
            <ExternalToolPlacementButton ref="externalToolPlacementButton" tool={this.props.tool} type="button"/>
          </td>
        );
      }
    },

    nameClassNames() {
      return classMunger('external_tool', {'muted': this.props.tool.enabled === false});
    },

    disabledFlag() {
      if (this.props.tool.enabled === false) {
        return I18n.t('(disabled)');
      }
    },

    locked() {
      if (!this.props.tool.installed_locally) {
        return (
          <span className="text-muted">
            <i className="icon-lock"
               ref="lockIcon"
               data-tooltip="top"
               title={I18n.t('Installed by Admin')}></i>
          </span>
        );
      } else if (this.props.tool.is_master_course_content) {
        if (this.props.tool.restricted_by_master_course) {
          return (
            <span className="master-course-cell">
              <i className="icon-lock"></i>
            </span>
          );
        } else {
          return (
            <span className="master-course-cell">
              <i className="icon-unlock icon-Line"></i>
            </span>
          );
        }
      }
    },

    render() {
      return (
        <tr className="ExternalToolsTableRow external_tool_item">
          <td className="e-tool-table-data center-text">{this.locked()}</td>
          <td scope="row" nowrap="nowrap" className={this.nameClassNames() + " e-tool-table-data"} title={this.props.tool.name}>
            {this.props.tool.name} {this.disabledFlag()}
          </td>
          {this.renderButtons()}
        </tr>
      );
    }
  });
});
