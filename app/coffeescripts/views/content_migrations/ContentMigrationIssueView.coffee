define [
  'Backbone'
  'jst/content_migrations/ContentMigrationIssue'
], (Backbone, template) -> 
  class ContentMigrationIssueView extends Backbone.View
    className: 'clearfix row-fluid top-padding'
    template: template

    toJSON: -> 
      json = super
      json.description = @model.get('description')
      json.fix_issue_url = @model.get('fix_issue_html_url')
      json
