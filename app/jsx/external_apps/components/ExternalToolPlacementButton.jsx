/** @jsx React.DOM */

define([
  'jquery',
  'underscore',
  'i18n!external_tools',
  'react',
  'react-modal',
  'jsx/external_apps/lib/ExternalAppsStore',
  'compiled/jquery.rails_flash_notifications'
], function ($, _, I18n, React, ReactModal, store) {

  return React.createClass({
    displayName: 'ExternalToolPlacementButton',

    componentDidUpdate: function() {
      var _this = this;
      window.requestAnimationFrame(function() {
        var node = document.getElementById('close' + _this.state.tool.name);
        if (node) {
          node.focus();
        }
      });
    },

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
        "post_grades":I18n.t("Post Grades"),
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
        if (tool[key] || (tool["resource_selection"] && key == "assignment_selection") ||
          (tool["resource_selection"] && key == "link_selection")) {
          hasPlacements = true;
          return <div>{ value }</div>;
        }
      });
      return hasPlacements ? appliedPlacements : null;
    },

    getModal() {
      return(
        <ReactModal
          ref='reactModal'
          isOpen={this.state.modalIsOpen}
          onRequestClose={this.closeModal}
          className='ReactModal__Content--canvas ReactModal__Content--mini-modal'
          overlayClassName='ReactModal__Overlay--canvas'
          >
          <div id={this.state.tool.name + "Heading"}
               className="ReactModal__Layout"
            >
            <div className="ReactModal__Header">
              <div className="ReactModal__Header-Title">
                <h4 tabindex="-1">{I18n.t('App Placements')}</h4>
              </div>
              <div className="ReactModal__Header-Actions">
                <button  className="Button Button--icon-action" type="button"  onClick={this.closeModal} >
                  <i className="icon-x"></i>
                  <span className="screenreader-only">Close</span>
                </button>
              </div>
            </div>
            <div tabindex="-1" className="ReactModal__Body" >
              <div id={ this.state.tool.name.replace(/\s/g,'') + 'Placements' } >
                { this.placements() || I18n.t("No Placements Enabled")}
              </div>
            </div>
            <div className="ReactModal__Footer">
              <div className="ReactModal__Footer-Actions">
                <button
                  ref="btnClose" type="button" className="btn btn-default"
                  id={ 'close' + this.state.tool.name }
                  aria-describedby={ this.state.tool.name.replace(/\s/g,'') + 'Placements' }
                  aria-labelledby={ this.state.tool.name.replace(/\s/g,'') + 'Placements' }
                  onClick={this.closeModal}>
                  {I18n.t('Close')}
                </button>
              </div>
            </div>
          </div>
        </ReactModal>
      );
    },

    getButton() {
      var editAriaLabel = I18n.t('View %{toolName} Placements', { toolName: this.state.tool.name });

      if (this.props.type === "button") {
        return(
          <a href="#" tabindex="-1" ref="placementButton" role="menuitem" aria-label={editAriaLabel} className="btn long" onClick={this.openModal} >
            <i className="icon-info" data-tooltip="left" title={I18n.t('Tool Placements')}></i>
            { this.getModal() }
          </a>
        );
      } else {
        return(
          <li role="presentation" className="ExternalToolPlacementButton">
            <a href="#" tabindex="-1" ref="placementButton" role="menuitem" aria-label={editAriaLabel} className="icon-info" onClick={this.openModal}>
              {I18n.t('Placements')}
            </a>
            { this.getModal() }
          </li>
        );
      }
    },

    render() {
      if (this.state.tool.app_type === 'ContextExternalTool') {
        return (
          this.getButton()
        );
      }
      return false;
    }
  });
});
