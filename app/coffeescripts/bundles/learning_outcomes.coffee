require [
  'compiled/views/outcomes/ToolbarView'
  'compiled/views/outcomes/SidebarView'
  'compiled/views/outcomes/ContentView'
  'compiled/views/outcomes/FindDialog'
  'compiled/models/OutcomeGroup'
  'jst/outcomes/browser'
  'jst/outcomes/mainInstructions'
], (ToolbarView, SidebarView, ContentView, FindDialog, OutcomeGroup, browserTemplate, instructionsTemplate) ->

  $el = $ '#outcomes'
  $el.html browserTemplate
    canManageOutcomes: ENV.PERMISSIONS.manage_outcomes
    contextUrlRoot: ENV.CONTEXT_URL_ROOT

  toolbar = new ToolbarView
    el: $el.find('.toolbar')

  sidebar = new SidebarView
    el: $el.find('.outcomes-sidebar .wrapper')
    rootOutcomeGroup: new OutcomeGroup ENV.ROOT_OUTCOME_GROUP

  content = new ContentView
    el: $el.find('.outcomes-content')
    instructionsTemplate: instructionsTemplate

  # toolbar events
  toolbar.on 'goBack', sidebar.goBack
  toolbar.on 'goBack', content.show
  toolbar.on 'add', sidebar.addAndSelect
  toolbar.on 'add', content.add
  toolbar.on 'find', -> sidebar.findDialog FindDialog
  # sidebar events
  sidebar.on 'select', content.show
  sidebar.on 'select', toolbar.resetBackButton
  # content events
  content.on 'addSuccess', sidebar.refreshSelection

  app =
    toolbar: toolbar
    sidebar: sidebar
    content: content
