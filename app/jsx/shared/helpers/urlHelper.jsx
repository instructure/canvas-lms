define([], () => ({
  encodeSpecialChars: url =>
    url.replace(/%/g, '&#37;'),
  decodeSpecialChars: url =>
    url.split('/').map(component =>
      encodeURIComponent(decodeURIComponent(component).replace(/&#37;/, '%'))
    ).join('/'),
}))
