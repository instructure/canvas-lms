const i18nRegex = /["']vendor\/i18n['"]/

module.exports = function nonAmdLoader(input){
  this.cacheable()

  return input.replace(i18nRegex, match =>
    // Make I18n available on the window so that libraries
    // that expect to find it there don't die
    match.replace('vendor', 'expose?I18n!exports?I18n!vendor')
  )
}
