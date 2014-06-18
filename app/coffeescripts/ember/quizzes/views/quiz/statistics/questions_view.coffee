define [ 'ember' ], (Ember) ->
  Ember.View.extend
    classNames: [ 'question-statistics' ]
    toggleDetails: (->
      Ember.run.schedule 'afterRender', this, ->
        isOn = @get('controller.detailsVisible')
        @$().toggleClass('with-details', !!isOn)
    ).observes('controller.detailsVisible')