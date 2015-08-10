/** @jsx React.DOM */

define([
  'underscore',
  'i18n!external_tools',
  'react',
  'jsx/external_apps/components/EditExternalToolButton',
  'jsx/external_apps/components/ExternalToolPlacementButton',
  'jsx/external_apps/components/DeleteExternalToolButton',
  'jsx/external_apps/components/ConfigureExternalToolButton',
  'jsx/external_apps/lib/classMunger',
  'jquery.instructure_misc_helpers'
], function(_, I18n, React, EditExternalToolButton, ExternalToolPlacementButton, DeleteExternalToolButton, ConfigureExternalToolButton, classMunger) {

  return React.createClass({
    displayName: 'ExternalToolsTableRow',

    propTypes: {
      tool: React.PropTypes.object.isRequired
    },

    renderButtons() {
      if (this.props.tool.installed_locally) {
        var configureButton = null;
        if (this.props.tool.tool_configuration) {
          configureButton = <ConfigureExternalToolButton ref="configureExternalToolButton" tool={this.props.tool} />;
        }
        return (
          <td className="links text-right" nowrap="nowrap">
            <div className={"al-dropdown__container"} >
              <a className={"al-trigger btn"} role="button" href="#">
                <i className={"icon-settings"}></i>
                <i className={"icon-mini-arrow-down"}></i>
                <span className={"screenreader-only"}>{ this.props.tool.name + ' ' + I18n.t('Settings') }</span>
              </a>
              <ul className={"al-options"} role="menu" tabindex="0" aria-hidden="true" aria-expanded="false" >
                {configureButton}
                <EditExternalToolButton ref="editExternalToolButton" tool={this.props.tool} />
                <ExternalToolPlacementButton ref="externalToolPlacementButton" tool={this.props.tool} />
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