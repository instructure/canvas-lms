define ->
  loadedStylesheets = {}

  brandableCss =
    getCssVariant: ->
      variant = if window.ENV.k12
        'k12'
      else if window.ENV.use_new_styles
        'new_styles'
      else
        'legacy'

      contrast = if window.ENV.use_high_contrast
        '_high_contrast'
      else
        '_normal_contrast'

      variant + contrast


    urlFor: (bundleName) ->
      brandPart = if window.ENV.active_brand_config
        '/' + window.ENV.active_brand_config
      else
        ''
      return [
        window.ENV.ASSET_HOST || '',
        'dist'
        'brandable_css' + brandPart,
        brandableCss.getCssVariant(),
        bundleName + '.css'
      ].join('/')

    # bundleName needs to include the 'combinedChecksum'
    # eg: 'jst/foo-65ed0284f8f911179a6d5655ebbb8498'
    # 'jst/foo' will not work.
    loadStylesheet: (bundleName) ->
      return if bundleName of loadedStylesheets
      linkElement = document.createElement("link")
      linkElement.rel = "stylesheet"
      linkElement.href = brandableCss.urlFor(bundleName)

      # give the person trying to track down a bug a hint on how
      # this link tag got on the page
      linkElement.setAttribute('data-loaded-by-brandableCss', true)
      document.head.appendChild(linkElement)
