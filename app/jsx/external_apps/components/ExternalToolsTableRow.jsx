/** @jsx React.DOM */

define([
  'underscore',
  'i18n!external_tools',
  'react',
  'jsx/external_apps/components/EditExternalToolButton',
  'jsx/external_apps/components/DeleteExternalToolButton',
  'jquery.instructure_misc_helpers'
], function(_, I18n, React, EditExternalToolButton, DeleteExternalToolButton) {
  return React.createClass({
    displayName: 'ExternalToolsTableRow',

    propTypes: {
      tool: React.PropTypes.object.isRequired
    },

    tags() {
      var extras = [
        {extension_type: 'editor_button', text: I18n.t('Editor button configured') },
        {extension_type: 'resource_selection', text: I18n.t('Resource selection configured') },
        {extension_type: 'course_navigation', text: I18n.t('Course navigation configured') },
        {extension_type: 'account_navigation', text: I18n.t('Account navigation configured') },
        {extension_type: 'user_navigation', text: I18n.t('User navigation configured') },
        {extension_type: 'homework_submission', text: I18n.t('Homework submission configured') },
        {extension_type: 'migration_selection', text: I18n.t('Migration selection configured') },
        {extension_type: 'course_home_sub_navigation', text: I18n.t('Course home sub navigation configured') },
        {extension_type: 'course_settings_sub_navigation', text:I18n.t('Course settings sub navigation configured') },
        {extension_type: 'global_navigation', text: I18n.t('Global navigation configured') },
        {extension_type: 'assignment_menu', text: I18n.t('Assignment menu configured') },
        {extension_type: 'discussion_topic_menu', text: I18n.t('Discussion Topic menu configured') },
        {extension_type: 'module_menu', text: I18n.t( 'Module menu configured') },
        {extension_type: 'quiz_menu', text: I18n.t('Quiz menu configured') },
        {extension_type: 'wiki_page_menu', text: I18n.t('Wiki page menu configured') }
      ];

      var tags = [];

      _.forEach(extras, function(extra, index) {
        if (!_.isEmpty(this.props.tool.attributes[extra.extension_type])) {
          var cls = "label label-primary " + extra.extension_type;
          var lbl = $.titleize(extra.extension_type);
          tags.push(<span key={index} className={cls} style={{ 'margin-right': '3px'}}>{lbl}</span>);
        }
      }.bind(this));

      return tags;
    },

    fixBrokenIcon(event) {
      img = $(event.currentTarget);
      img.attr('src', '/images/transparent_16x16.png');
    },

    render() {
      return (
        <tr className="ExternalToolsTableRow external_tool_item">
          <td scope="row" nowrap="nowrap" className="external_tool" title={this.props.tool.attributes.name}>
            <img onError={this.fixBrokenIcon} src={this.props.tool.attributes.icon_url || '/images/transparent_16x16.png'} />&nbsp;&nbsp;
            {this.props.tool.attributes.name}
          </td>
          <td>{this.tags()}</td>
          <td className="links text-right" nowrap="nowrap">
            <EditExternalToolButton tool={this.props.tool} />
            <DeleteExternalToolButton tool={this.props.tool} />
          </td>
        </tr>
      );
    }
  });
});