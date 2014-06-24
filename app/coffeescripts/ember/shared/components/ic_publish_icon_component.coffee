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

    # public property to determine if this is an icon based publish button
    'icon-only': false

    role: 'button'

    attributeBindings: ['data-tooltip', 'aria-label', 'title', 'tabindex', 'aria-disabled']

    classNameBindings: ['buttonClass', 'wrapperClass', 'disabled']

    buttonClassStates:
      'button': 'btn'
      'span':   'publish-icon'

    iconClassStates:
      'published':            'icon-publish'
      'unpublished':          'icon-unpublished'
      'hoverPublished':       'icon-unpublish'
      'hoverUnpublished':     'icon-unpublished'
      'publishing':           'icon-publish'
      'unpublishing':         'icon-unpublished'
      'hoverJustUnpublished': 'icon-unpublished'
      'hoverJustPublished':   'icon-publish'

    iconStates:
      'published':            'publish-icon-published'
      'unpublished':          'publish-icon-unpublished'
      'hoverPublished':       'publish-icon-unpublish'
      'hoverUnpublished':     'publish-icon-publish'
      'publishing':           'publish-icon-publish'
      'unpublishing':         'publish-icon-unpublish'
      'hoverJustUnpublished': 'publish-icon-publish'
      'hoverJustPublished':   'publish-icon-published'

    buttonStates:
      'published':            'btn-published'
      'unpublished':          'btn-publish'
      'hoverPublished':       'btn-unpublish'
      'hoverUnpublished':     'btn-publish'
      'publishing':           'btn-publish'
      'unpublishing':         'btn-unpublish'
      'hoverJustUnpublished': 'btn-publish'
      'hoverJustPublished':   'btn-published'

    textStates:
      'published':            I18n.t('published',    'Published')
      'unpublished':          I18n.t('publish',      'Publish')
      'hoverPublished':       I18n.t('unpublish',    'Unpublish')
      'hoverUnpublished':     I18n.t('publish',      'Publish')
      'publishing':           I18n.t('publishing',   'Publishing...')
      'unpublishing':         I18n.t('unpublishing', 'Unpublishing...')
      'hoverJustUnpublished': I18n.t('publish',      'Publish')
      'hoverJustPublished':   I18n.t('published',    'Published')

    'data-tooltip': 'top'

    # internal state that determines what is rendered
    publishState: null

    mouseIsHovered: false

    tagName: (->
      if @get('icon-only') then 'span' else 'button'
    ).property('icon-only')

    iconClass: (->
      @iconClassStates[@get('publishState')]
    ).property('publishState')

    buttonClass: (->
      @buttonClassStates[@get('tagName')]
    ).property('tagName')

    wrapperClass: (->
      states = if @get("tagName") is "span" then @iconStates else @buttonStates
      states[@get('publishState')]
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

    text: (->
      @textStates[@get('publishState')]
    ).property('publishState')

    'aria-disabled': (->
      @get('disabled')+''
    ).property('disabled')

    'aria-label': (->
      if @get('disabled')
        @get('disabled-message')
      else if @get('is-published')
        I18n.t('unpublish_click', 'unpublished, click to publish')
      else
        I18n.t('publish_click', 'published, click to unpublish')
    ).property('disabled', 'is-published')

    click: ->
      return if @get('disabled')
      if @get('is-published')
        @set('publishState', 'unpublishing')
        @sendAction 'on-unpublish'
      else
        @set('publishState', 'publishing')
        @sendAction 'on-publish'
      @set('is-published', null)

