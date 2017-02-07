// This is basically one big port of what we do in ruby-land in the
// handlebars-tasks gem.  We need to run handlebars source through basic
// compilation to extract i18nliner scopes, and then we wrap the resulting
// template in an AMD module, giving it dependencies on handlebars, it's scoped
// i18n object if it needs one, and any brandableCss variant stuff it needs.
const Handlebars = require('handlebars')
const {pick} = require('lodash')
const {EmberHandlebars} = require('ember-template-compiler')
const ScopedHbsExtractor = require('./../gems/canvas_i18nliner/js/scoped_hbs_extractor')
const {allFingerprintsFor} = require('brandable_css/lib/main')
const PreProcessor = require('./../gems/canvas_i18nliner/node_modules/i18nliner-handlebars/dist/lib/pre_processor')
require('./../gems/canvas_i18nliner/js/scoped_hbs_pre_processor')

const compileHandlebars = (data) => {
  const path = data.path
  const source = data.source
  try {
    let translationCount = 0
    const ast = Handlebars.parse(source)
    const extractor = new ScopedHbsExtractor(ast, {path})
    const scope = extractor.scope
    PreProcessor.scope = scope
    PreProcessor.process(ast)
    extractor.forEach(() => translationCount++)

    const precompiler = data.ember ? EmberHandlebars : Handlebars
    const template = precompiler.precompile(ast).toString()
    return {template, scope, translationCount}
  } catch (e) {
    e = e.message || e
    console.log(e)
    throw {error: e}
  }
}

const emitTemplate = (path, name, result, dependencies, cssRegistration, partialRegistration) => {
  const moduleName = `jst/${path.replace(/.*\/\jst\//, '').replace(/\.handlebars/, '')}`
  return `
    define('${moduleName}', ${JSON.stringify(dependencies)}, function(Handlebars){
      var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
      var name = '${name}';
      templates[name] = template(${result['template']});
      ${partialRegistration};
      ${cssRegistration};
      return templates[name];
    });
  `
}

const resourceName = (path) => {
  return path
    .replace(/^.+\/app\/views\/jst\/(?:plugins\/[^\/]*\/)?/, '')
    .replace(/\.handlebars$/, '')
    .replace(/_/g, '-')
}

// given an object, returns a new object with just the 'combinedChecksum' property of each item
const getCombinedChecksums = (obj) => {
  return Object.keys(obj).reduce((accumulator, key) => {
    accumulator[key] = pick(obj[key], 'combinedChecksum')
    return accumulator
  }, {})
}

const buildCssReference = (name) => {
  const bundle = 'jst/' + name
  const cached = allFingerprintsFor(bundle + '.scss')
  const firstVariant = Object.keys(cached)[0]
  if (!firstVariant) {
    // no matching css file, just return a blank string
    return ''
  }

  const options = cached[firstVariant].includesNoVariables ?
    // there is no branding / high contrast specific variables in this file,
    // all users will use the same file.
    JSON.stringify(pick(cached[firstVariant], 'combinedChecksum', 'includesNoVariables'))
  :
    // Spit out all the combinedChecksums into the compiled js file and use brandableCss.getCssVariant()
    // at runtime to determine which css variant to load, based on the user & account's settings
    JSON.stringify(getCombinedChecksums(cached)) + '[brandableCss.getCssVariant()]'

  return `
    var brandableCss = arguments[1];
    brandableCss.loadStylesheet('${bundle}', ${options});
  `
}

const partialRegexp = /\{\{>\s?\[?(.+?)\]?( .*?)?}}/g
const findReferencedPartials = (source) => {
  let partials = []
  let match
  while (match = partialRegexp.exec(source)){
    partials.push(match[1].trim())
  }

  const uniquePartials = partials.filter((elem, pos) => partials.indexOf(elem) == pos)

  return uniquePartials
}

const emitPartialRegistration = (path, resourceName) => {
  const baseName = path.split('/').pop()
  if (baseName.startsWith('_')) {
    const partialName = baseName.replace(/^_/, '')
    const partialPath = path.replace(baseName, partialName).replace(/.*\/\jst\//, '').replace(/\.handlebars/, '')
    return `
      Handlebars.registerPartial('${partialPath}', templates['${resourceName}']);
    `
  }
  return ''
}

const buildPartialRequirements = (partialPaths) => {
  const requirements = partialPaths.map(partial => {
    const partialParts = partial.split('/')
    partialParts[partialParts.length - 1] = '_' + partialParts[partialParts.length - 1]
    const requirePath = partialParts.join('/')
    return 'jst/' + requirePath
  })
  return requirements
}

module.exports = function i18nLinerHandlebarsLoader (source) {
  this.cacheable()
  const name = resourceName(this.resourcePath)
  const dependencies = ['handlebars']

  const partialRegistration = emitPartialRegistration(this.resourcePath, name)

  const cssRegistration = buildCssReference(name)
  if (cssRegistration) {
    // arguments[1] will be brandableCss
    dependencies.push('compiled/util/brandableCss')
  }

  const partials = findReferencedPartials(source)
  const partialRequirements = buildPartialRequirements(partials)
  partialRequirements.forEach(requirement => dependencies.push(requirement))

  const result = compileHandlebars({path: this.resourcePath, source})
  if (result.error) {
    console.log('THERE WAS AN ERROR IN PRECOMPILATION', result)
    throw result
  }

  if (result.translationCount > 0) {
    dependencies.push('i18n!' + result.scope)
  }
  const compiledTemplate = emitTemplate(this.resourcePath, name, result, dependencies, cssRegistration, partialRegistration)
  return compiledTemplate
}
