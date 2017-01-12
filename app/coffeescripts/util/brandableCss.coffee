define ->
  loadedStylesheets = {}

  brandableCss =
    getCssVariant: ->
      variant = if window.ENV.use_new_styles
        'new_styles'
      else
        'legacy'

      contrast = if window.ENV.use_high_contrast
        '_high_contrast'
      else
        '_normal_contrast'

      variant + contrast


    # combinedChecksum should be like '09f833ef7a'
    # and includesNoVariables should be true if this bundle does not
    # "@include" variables.scss, brand_variables.scss or variant_variables.scss
    urlFor: (bundleName, {combinedChecksum, includesNoVariables}) ->
      brandAndVariant = if includesNoVariables
        'no_variables'
      else
        (if window.ENV.active_brand_config
          "#{window.ENV.active_brand_config}/"
        else
          ''
        ) + brandableCss.getCssVariant()
      return [
        window.ENV.ASSET_HOST || '',
        'dist'
        'brandable_css',
        brandAndVariant,
        "#{bundleName}-#{combinedChecksum}.css"
      ].join('/')


    # bundleName should be something like 'jst/foo'
    loadStylesheet: (bundleName, opts) ->
      return if bundleName of loadedStylesheets
      linkElement = document.createElement("link")
      linkElement.rel = "stylesheet"
      linkElement.href = brandableCss.urlFor(bundleName, opts)

      # give the person trying to track down a bug a hint on how
      # this link tag got on the page
      linkElement.setAttribute('data-loaded-by-brandableCss', true)
      document.head.appendChild(linkElement)
