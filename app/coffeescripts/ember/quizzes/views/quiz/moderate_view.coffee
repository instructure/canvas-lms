define ['ember'], (Em) ->

  Em.View.extend

    allowReloading: ( ->
      @controller.set('okayToReload', true)
    ).on('didInsertElement')

    denyReloading: ( ->
      @controller.set('okayToReload', false)
    ).on('willDestroyElement')
