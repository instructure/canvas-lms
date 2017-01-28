// Webpack wants to be able to resolve every module before
// building.  Because we use a pitching loader for i18n tags,
// we never make it to the resource itself (or shouldn't). However,
// We need to give webpack a resource that exists on the Filesystem
// before the pitching i18n loader catches it, so we replace
// i18n!some-scope requires with i18n?some-scope!dummyI18nResource,
// and that file actually does exist over in
// public/javascripts/dummyI18nResource

class I18nPlugin {
  apply (compiler) {
    compiler.plugin('normal-module-factory', nmf => {
      nmf.plugin('before-resolve', (result, callback) => {
        if (/^i18n!/.test(result.request)) {
          const scopeName = result.request.split('!')[1]
          const newRequest = `i18n?${scopeName}!dummyI18nResource`
          result.request = newRequest
        }
        return callback(null, result)
      })
    })
  }
}

module.exports = I18nPlugin
