define [
  'ember'
], (Ember) ->
  Ember.Controller.extend
    editable: true
    togglePreview: ->
      if this.get 'editable'
        this.set 'editable', false
      else
        this.set 'editable', true

    filterItems: (->
      exp = new RegExp this.searchQuery,'g'
      this.get('content').map (module) ->
        if exp.test module.get('name')
          module.set 'hidden', false
          module.get('items').map (item) ->
            item.set 'visible', true
            item
        else
          moduleHidden = true
          module.get('items').map (item) ->
            if exp.test item.get('title')
              item.set 'visible', true
              moduleHidden = false
            else
              item.set 'visible', false
            item
          module.set 'hidden', moduleHidden
        module
    ).observes('searchQuery')