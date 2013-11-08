define [
  'ember'
  ], (Ember) ->
    Ember.Handlebars.registerBoundHelper 'moduleIcon', (type) ->

      iconClasses =
        'ModuleItem'   : "icon-module"
        'File'         : "icon-download"
        'Page'         : "icon-document"
        'Discussion'   : "icon-discussion"
        'Assignment'   : "icon-assignment"
        'Quiz'         : "icon-quiz"
        'ExternalTool' : "icon-link"

      new Ember.Handlebars.SafeString "<i class='#{iconClasses[type]}'></i>"
