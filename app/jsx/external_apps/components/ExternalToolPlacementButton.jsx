/** @jsx React.DOM */

define([
  'jquery',
  'underscore',
  'i18n!external_tools',
  'react',
  'react-modal',
  'jsx/external_apps/lib/ExternalAppsStore',
  'jsx/external_apps/components/ConfigurationForm',
  'jsx/external_apps/components/Lti2Edit',
  'compiled/jquery.rails_flash_notifications'
], function ($, _, I18n, React, Modal, store, ConfigurationForm, Lti2Edit) {

  return React.createClass({
    displayName: 'ExternalToolPlacementButton',

    propTypes: {
      tool: React.PropTypes.object.isRequired
    },

    getInitialState() {
      return {
        tool: this.props.tool,
        modalIsOpen: false
      }
    },

    openModal(e) {
      e.preventDefault();
      if (this.props.tool.app_type === 'ContextExternalTool') {
        store.fetchWithDetails(this.props.tool).then(function(data) {
          var tool = _.extend(data, this.props.tool);
          this.setState({
            tool: tool,
            modalIsOpen: true
          });
        }.bind(this));
      } else {
        this.setState({
          tool: this.props.tool,
          modalIsOpen: true
        });
      }
    },

    closeModal() {
      this.setState({ modalIsOpen: false });
    },

    placements() {
      var allPlacements = {
        "account_navigation":I18n.t("Account Navigation"),
        "assignment_menu":I18n.t("Assignment Menu"),
        "course_home_sub_navigation":I18n.t("Course Home Sub Navigation"),
        "course_navigation":I18n.t("Course Navigation"),
        "course_settings_sub_navigation":I18n.t("Course Settings Sub Navigation"),
        "discussion_topic_menu":I18n.t("Discussion Topic Menu"),
        "editor_button":I18n.t("Editor Button"),
        "file_menu":I18n.t("File Menu"),
        "global_navigation":I18n.t("Global Navigation"),
        "homework_submission":I18n.t("Homework Submission"),
        "migration_selection":I18n.t("Migration Selection"),
        "module_menu":I18n.t("Module Menu"),
        "quiz_menu":I18n.t("Quiz Menu"),
        "user_navigation":I18n.t("User Navigation"),
        "assignment_selection":I18n.t("Assignment Selection"),
        "link_selection":I18n.t("Link Selection"),
        "wiki_page_menu":I18n.t("Wiki Page Menu"),
        "tool_configuration":I18n.t("Tool Configuration")
      };

      var tool = this.state.tool;
      var hasPlacements = false;
      var appliedPlacements = _.map(allPlacements, function(value, key){
        if (tool[key]) {
          hasPlacements = true;
          return <div aria-label={ value } >{ value }</div>;
        }
      });

      return (
        <div className="app_placements">
          { hasPlacements ? appliedPlacements : I18n.t('No Placements Enabled') }
        </div>
      );
    },

    render() {
      var editAriaLabel = I18n.t('View %{toolName} Placements', { toolName: this.state.tool.name });
      if (this.state.tool.app_type === 'ContextExternalTool') {
        return (
          <li role="presentation" className="ExternalToolPlacementButton">
          <a href="#" tabindex="-1" ref="placementButton" role="menuitem" aria-label={editAriaLabel} className="icon-info" onClick={this.openModal}>
            {I18n.t('Placements')}
          </a>
          <Modal className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
                 overlayClassName="ReactModal__Overlay--canvas"
                 isOpen={this.state.modalIsOpen}
                 onRequestClose={this.closeModal}>
            <div className="ReactModal__Layout">
              <div className="ReactModal__InnerSection ReactModal__Header ReactModal__Header--force-no-corners">
                <div className="ReactModal__Header-Title">
                  <h4>{I18n.t('App Placements')}</h4>
                </div>
                <div className="ReactModal__Header-Actions">
                  <button className="Button Button--icon-action" type="button" onClick={this.closeModal}>
                    <i className="icon-x"></i>
                    <span className="screenreader-only">Close</span>
                  </button>
                </div>
              </div>
              <div className="ReactModal__InnerSection ReactModal__Body">
                {this.placements()}
              </div>
              <div className="ReactModal__InnerSection ReactModal__Footer">
                <div className="ReactModal__Footer-Actions">
                  <button ref="btnClose" type="button" className="btn btn-default" onClick={this.closeModal}>{I18n.t('Close')}</button>
                </div>
              </div>
            </div>
          </Modal>
        </li>
        );
      }
      return false;
    }
  });
});
