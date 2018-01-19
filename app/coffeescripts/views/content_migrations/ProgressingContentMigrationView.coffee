#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'Backbone'
  'i18n!content_migrations'
  'jst/content_migrations/ProgressingContentMigration'
  'jst/content_migrations/ProgressingIssues'
  '../PaginatedCollectionView'
  './ContentMigrationIssueView'
  './ProgressBarView'
  './ProgressStatusView'
  './SelectContentView'
  './SourceLinkView'
], ($, Backbone, I18n, template, progressingIssuesTemplate, PaginatedCollectionView, ContentMigrationIssueView, ProgressBarView, ProgressStatusView, SelectContentView, SourceLinkView) ->
  class ProgressingContentMigrationView extends Backbone.View
    template: template
    tagName: 'li'
    className: 'clearfix migrationProgressItem'

    events: 
      'click .showIssues'       : 'toggleIssues'
      'click .selectContentBtn' : 'showSelectContentDialog'

    els:
      '.showIssues'                          : '$showIssues'
      '.migrationIssues'                     : '$migrationIssues'
      '.changable'                           : '$changable'
      '.progressStatus'                      : '$progressStatus'
      '.selectContentDialog'                 : '$selectContentDialog'
      '[data-bind=migration_issues_count]'  : '$issuesCount'
      '.sourceLink'                         : '$sourceLink'

    initialize: -> 
      super
      @issuesLoaded = false

      @progress = @model.progressModel
      @issues   = @model.issuesCollection

      # Continue looking for progress after content is selected.
      @model.on 'continue', =>
        @progress?.poll()
        @render()

      # Render the progress bar if workflow_state changes to running
      @progress.on 'change:workflow_state', (event) => 
        @renderProgressBar() if @progress.get('workflow_state') == "running"

      # When progress is complete, update
      @progress.on 'complete', (event) => @updateMigrationModel()

    toJSON: -> 
      json = super
      json.display_name = @displayName()
      json.created_at = @createdAt()
      json.issuesCount = @model.get('migration_issues_count')

      switch @model.get('workflow_state')
        when "waiting_for_select"
          json.waiting_for_select = true
        when "completed", "failed"
          json.migration_issues = true if @model.get('migration_issues_count') > 0
        when "failed"
          json.message = @model.get('message') || @progress.get('message')
        when "running"
          json.loading = true

      json

    displayName: ->          @model.get('migration_type_title')  ||  I18n.t('content_migration', 'Content Migration')
    createdAt:   ->          @model.get('created_at')            ||  (new Date()).toISOString()

    # Render a collection view that represents issues for this migration. 
    #
    # @backbone override

    render: => 
      super
      issuesCollectionView = new PaginatedCollectionView
                         collection: @issues
                         itemView: ContentMigrationIssueView
                         template: progressingIssuesTemplate
                         autoFetch: true
      @$migrationIssues.html issuesCollectionView.render().el

      progressStatus = new ProgressStatusView
                         model: @model
                         el: @$progressStatus

      progressStatus.render()

      sourceLink = new SourceLinkView
                         model: @model
                         el: @$sourceLink

      sourceLink.render()

      this

    # Render the initial progress bar after it renders, if its in a running state
    #
    # @expects void
    # @api backbone override

    afterRender: -> 
      if @model.get('workflow_state') == "running"
        @renderProgressBar() if @progress.get('workflow_state') == "running"

    # Create a new progress bar with the @progress model. Replace the changable html 
    # with this progress information. 
    #
    # @expects void 
    # @api private

    renderProgressBar: -> 
      progressBarView = new ProgressBarView 
                          model: @progress
                          el: @$changable
      progressBarView.render()

    # Does a fetch on the migration model. If successful it will re-render the progress
    # view. 
    #
    # @api private

    updateMigrationModel: -> 
      @model.fetch
              error: (model, response, option) => @model.set('status', 'failed')
              success: (model, response, options) => @render()

    # When clicking on the issues button for the first time it needs to fetch all of the issues.
    # This progress view keeps track of if it's fetched issues for this migration with the 
    # @issueLoaded class variable. If this is false more issues need to be fetched from the 
    # server. Also, when toggled the text should change on the button.
    #
    # @expects event
    # @api private

    toggleIssues: (event) -> 
      event.preventDefault()

      if @issuesLoaded
        @$migrationIssues.toggle()
        @$migrationIssues.attr('aria-expanded', @$migrationIssues.attr('aria-expanded') != 'true')
        @setIssuesButtonText()
      else
        dfd = @fetchIssues()
        dfd.done => 
          @issuesLoaded = true
          @toggleIssues(event)

    # Fetches issues and adds a loading icon and text to the button.
    # @api private

    fetchIssues: () -> 
      @model.set('issuesButtonText', I18n.t('loading', 'Loading...'))
      dfd = @issues.fetch()
      @$el.disableWhileLoading dfd
      dfd

    # Determines which text to add to the issues button. This is so when you click
    # the issues button it changes from Show Issues to Hide Issues as well as 
    # handles a case where loading text is still there an needs to be removed.
    #
    # @api private

    setIssuesButtonText: ->
      btnText = @model.get('issuesButtonText')
      if !@hiddenIssues
        @$issuesCount.hide()
        @model.set('issuesButtonText', I18n.t('hide_issues', 'Hide Issues'))
        @$showIssues.attr('aria-label', I18n.t('hide_issues', 'Hide Issues'))
        @$showIssues.attr('title', I18n.t('hide_issues', 'Hide Issues'))
        @$showIssues.blur().focus() if $(document.activeElement).is(@$showIssues)
        @hiddenIssues = true
      else 
        @$issuesCount.show()
        @$showIssues.attr('aria-label', I18n.t('show_issues', 'Show Issues'))
        @$showIssues.attr('title', I18n.t('show_issues', 'Show Issues'))
        @$showIssues.blur().focus() if $(document.activeElement).is(@$showIssues)
        @model.set('issuesButtonText', I18n.t('issues', 'issues'))
        @hiddenIssues = false

    # Render's a new SelectContentDialog which allows someone to select the migration
    # content to be migrated. 
    #
    # @api private

    showSelectContentDialog: (event) => 
      event.preventDefault()

      @selectContentView ||= new SelectContentView 
                              model: @model
                              el: @$selectContentDialog
                              title: I18n.t('#select_content', 'Select Content')
                              width: 900
                              height: 700

      @selectContentView.open()
