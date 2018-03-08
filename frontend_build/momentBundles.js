const glob = require('glob')
const path = require('path')

// Put any custom moment locales here:
const customMomentLocales = ['de', 'fa', 'fr', 'fr-ca', 'he', 'ht-ht', 'hy-am', 'mi-nz', 'pl']

const momentLocaleBundles = glob
  .sync('moment/locale/**/*.js', {cwd: 'node_modules'})
  .reduce((memo, filename) => {
    const parsed = path.parse(filename)
    if (!customMomentLocales.includes(parsed.name)) {
      memo[`${parsed.dir}/${parsed.name}`] = filename
    }
    return memo
  }, {})

customMomentLocales.forEach(locale => {
  const filename = `custom_moment_locales/${locale.replace('-', '_')}.js`
  momentLocaleBundles[`moment/locale/${locale}`] = filename
})

module.exports = momentLocaleBundles
