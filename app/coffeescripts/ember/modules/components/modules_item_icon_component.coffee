define ['ember'], (Ember) ->

  map =
    Assignment: 'assignment'
    Discussion: 'discussion'
    ExternalTool: 'link'
    ExternalUrl: 'link'
    File: 'download'
    Page: 'document'
    Quiz: 'quiz'
    #SubHeader: ''

  ModulesItemIconComponent = Ember.Component.extend

    tagName: 'i'

    classNameBindings: ['iconClass']

    type: 'Page'

    iconClass: (->
      "icon-#{map[@get('type')] or 'page'}"
    ).property('type')

