define [ 'ember' ], (Ember) ->
  QuizzesView = Ember.View.extend
    ensureGroupVisibility: (->
      Ember.run.scheduleOnce 'afterRender', this, ->
        for itemGroup in this.$('.item-group-condensed')
          $itemGroup = Ember.$(itemGroup)
          $header = $itemGroup.find('.ig-header-title[aria-expanded="false"]')
          isEmpty = $itemGroup.find('.ig-row-empty').length
          isCollapsed = $header.length

          if !isEmpty && isCollapsed
            $header.click()
    ).observes(
      'controller.assignments.length',
      'controller.practices.length',
      'controller.surveys.length'
    )