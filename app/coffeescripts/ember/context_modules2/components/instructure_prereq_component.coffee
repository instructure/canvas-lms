define [
  'ember'
], (Ember) ->
  Ember.Component.extend
    tagName: 'ul'
    classNames: 'pill'
    attributeBindings: ['customStyles:style']
    customStyles: (->
      if !this.get('module').get('onePrereq') and !this.get('module').get('moreThanOnePrereq')
        "display: none"
    ).property() 
