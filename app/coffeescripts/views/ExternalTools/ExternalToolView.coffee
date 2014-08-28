define [
  'jquery'
  'jst/ExternalTools/ExternalToolView'
  'i18n!external_tools'
], ($, template, I18n) ->

  class ExternalToolView extends Backbone.View

    template: template
    tagName: 'tr'
    className: 'external_tool_item'

    afterRender: ->
      @$el.attr('id', 'external_tool_' + @model.get('id'))
      this

    toJSON: ->
      extras = [
        {extension_type: 'editor_button', text: I18n.t 'editor_button_configured', 'Editor button configured'}
        {extension_type: 'resource_selection', text: I18n.t 'resource_selection_configured', 'Resource selection configured'}
        {extension_type: 'course_navigation', text: I18n.t 'course_navigation_configured', 'Course navigation configured'}
        {extension_type: 'account_navigation', text: I18n.t 'account_navigation_configured', 'Account navigation configured'}
        {extension_type: 'user_navigation', text: I18n.t 'user_navigation_configured', 'User navigation configured'}
        {extension_type: 'homework_submission', text: I18n.t 'homework_submission_configured', 'Homework submission configured'}
        {extension_type: 'migration_selection', text: I18n.t 'migration_selection_configured', 'Migration selection configured'}
        {extension_type: 'course_home_sub_navigation', text: I18n.t 'course_home_sub_navigation_configured', 'Course home sub navigation configured'}
        {extension_type: 'course_settings_sub_navigation', text: I18n.t 'course_settings_sub_navigation_configured', 'Course settings sub navigation configured'}
        {extension_type: 'global_navigation', text: I18n.t 'global_navigation_configured', 'Global navigation configured'}
        {extension_type: 'assignment_menu', text: I18n.t 'assignment_menu_configured', 'Assignment menu configured'}
        {extension_type: 'module_menu', text: I18n.t 'module_menu_configured', 'Module menu configured'}
        {extension_type: 'quiz_menu', text: I18n.t 'quiz_menu_configured', 'Quiz menu configured'}
        {extension_type: 'wiki_page_menu', text: I18n.t 'wiki_page_menu_configured', 'Wiki page menu configured'}
      ]

      json = super
      json.extras = (extra for extra in extras when json[extra.extension_type]?)
      json
