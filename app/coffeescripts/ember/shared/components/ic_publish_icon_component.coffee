define [
  'i18n!publish_icon_component'
  'ember'
  '../register'
  '../templates/components/ic-publish-icon'
], (I18n, Ember, register) ->


  # example usage:
  #
  #   {{ic-publish-icon
  #     disabled=disabled
  #     disabled-message=disabledMessage
  #     is-published=isPublished
  #     on-publish="publish"
  #     on-unpublish="unpublish"
  #   }}


  register 'component', 'ic-publish-icon', Ember.Component.extend

    # public published property the controller binds to
    'is-published': false

    tagName: 'span'

    role: 'button'

    attributeBindings: ['data-tooltip', 'aria-label', 'title', 'tabindex', 'aria-disabled']

    classNames: ['publish-icon']

    classNameBindings: ['wrapperClass', 'disabled']

    'data-tooltip': 'top'

    # internal state that determines what is rendered
    publishState: null

    mouseIsHovered: false

    iconClass: (->
      switch @get('publishState')
        when 'published'            then 'icon-publish'
        when 'unpublished'          then 'icon-unpublished'
        when 'hoverPublished'       then 'icon-unpublish'
        when 'hoverUnpublished'     then 'icon-unpublished'
        when 'publishing'           then 'icon-publish'
        when 'unpublishing'         then 'icon-unpublished'
        when 'hoverJustUnpublished' then 'icon-unpublished'
        when 'hoverJustPublished'   then 'icon-publish'
    ).property('publishState')

    wrapperClass: (->
      switch @get('publishState')
        when 'published'            then 'publish-icon-published'
        when 'unpublished'          then 'publish-icon-unpublished'
        when 'hoverPublished'       then 'publish-icon-unpublish'
        when 'hoverUnpublished'     then 'publish-icon-publish'
        when 'publishing'           then 'publish-icon-publish'
        when 'unpublishing'         then 'publish-icon-unpublish'
        when 'hoverJustUnpublished' then 'publish-icon-publish'
        when 'hoverJustPublished'   then 'publish-icon-published'
    ).property('publishState')

    mouseEnter: ->
      return if @get('disabled')
      @set('mouseIsHovered', true)
      return if @get('publishState') in ['publishing', 'unpublishing']
      if @get('is-published')
        @set('publishState', 'hoverPublished')
      else
        @set('publishState', 'hoverUnpublished')

    mouseLeave: (->
      return if @get('disabled') and @get('state') is 'inDOM'
      @set('mouseIsHovered', false)
      return if @get('publishState') in ['publishing', 'unpublishing']
      if @get('is-published')
        @set('publishState', 'published')
      else
        @set('publishState', 'unpublished')
    ).on('init')

    setPublishStateOnIsPublished: (->
      return if @get('is-published') is null
      if @get('is-published') and @get('mouseIsHovered')
        @set('publishState', 'hoverJustPublished')
      else if !@get('is-published') and @get('mouseIsHovered')
        @set('publishState', 'hoverJustUnpublished')
      else if @get('is-published')
        @set('publishState', 'published')
      else
        @set('publishState', 'unpublished')
    ).observes('is-published')

    title: (->
      if @get('disabled')
        @get('disabled-message')
      else if @get('is-published')
        I18n.t('unpublish', 'Unpublish')
      else
        I18n.t('publish', 'Publish')
    ).property('is-published')

    'aria-disabled': (->
      @get('disabled')+''
    ).property('disabled')

    'aria-label': (->
      if @get('is-published')
        I18n.t('unpublish_click', 'unpublished, click to publish')
      else
        I18n.t('publish_click', 'published, click to unpublish')
    ).property('is-published')

    click: ->
      return if @get('disabled')
      if @get('is-published')
        @set('publishState', 'unpublishing')
        @sendAction 'on-unpublish'
      else
        @set('publishState', 'publishing')
        @sendAction 'on-publish'
      @set('is-published', null)

