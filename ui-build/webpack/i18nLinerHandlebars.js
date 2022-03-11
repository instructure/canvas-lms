/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// This is basically one big port of what we do in ruby-land in the
// handlebars-tasks gem.  We need to run handlebars source through basic
// compilation to extract i18nliner scopes, and then we wrap the resulting
// template in an AMD module, giving it dependencies on handlebars, it's scoped
// i18n object if it needs one.
const Handlebars = require('handlebars')
const {pick} = require('lodash')
const {EmberHandlebars} = require('ember-template-compiler')
const ScopedHbsExtractor = require('i18nliner-canvas/js/scoped_hbs_extractor')
const PreProcessor = require('@instructure/i18nliner-handlebars/dist/lib/pre_processor').default
const nodePath = require('path')
const loaderUtils = require('loader-utils')
const { canvasDir } = require('#params')
const { contriveId, config: brandableCSSConfig } = requireBrandableCSS()
require('i18nliner-canvas/js/scoped_hbs_pre_processor')

// In this main file, we do a bunch of stuff to monkey-patch the default behavior of
// i18nliner's HbsProcessor (specifically, we set the the `directories` and define a
// `normalizePath` function so that translation keys stay relative to canvas root dir).
// By requiring it here the code here will use that monkeypatched behavior.
require('i18nliner-canvas/js/main')


const compileHandlebars = data => {
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
    console.error(e.message || e)
    throw e
  }
}

const emitTemplate = (path, name, result, dependencies, cssRegistration, partialRegistration) => {
  return `
    import _Handlebars from 'handlebars/runtime';
    var Handlebars = _Handlebars.default;
    ${dependencies.map(d => `import ${JSON.stringify(d)};`).join('\n')}

    var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
    var name = '${name}';
    templates[name] = template(${result.template});
    ${partialRegistration};
    ${cssRegistration};
    export default templates[name];
  `
}

const resourceName = path =>
  path
    .replace(/^.+\/app\/views\/jst\/(?:plugins\/[^\/]*\/)?/, '')
    .replace(/\.handlebars$/, '')
    .replace(/_/g, '-')

// given an object, returns a new object with just the 'combinedChecksum' property of each item
const getCombinedChecksums = obj =>
  Object.keys(obj).reduce((accumulator, key) => {
    accumulator[key] = pick(obj[key], 'combinedChecksum')
    return accumulator
  }, {})

// inject the template with the css file specified in the "brandableCSSBundle"
// property of the accompanying .json metadata file, if any
const buildCssReference = (path, name) => {
  let bundle

  try {
    bundle = require(`${path}.json`).brandableCSSBundle
  }
  catch (_) {
    bundle = null
  }

  if (!bundle) {
    // no css file specified in json, just return a blank string
    return ''
  }

  return `
    import brandableCss from '@canvas/brandable-css';

    brandableCss.loadStylesheetForJST({
      id: '${contriveId(bundle, brandableCSSConfig.indices.handlebars.keysz)}',
      bundle: '${bundle}'
    });
  `
}

const partialRegexp = /\{\{>\s?\[?(.+?)\]?( .*?)?}}/g
const findReferencedPartials = source => {
  const partials = []
  let match
  while ((match = partialRegexp.exec(source))) {
    partials.push(match[1].trim())
  }

  const uniquePartials = partials.filter((elem, pos) => partials.indexOf(elem) == pos)

  return uniquePartials
}

const emitPartialRegistration = (path, resourceName) => {
  const baseName = path.split('/').pop()
  if (baseName.startsWith('_')) {
    const virtualPath = path.slice(canvasDir.length + 1)
    return `
      Handlebars.registerPartial('${virtualPath}', templates['${resourceName}']);
    `
  }
  return ''
}

function i18nLinerHandlebarsLoader(source) {
  this.cacheable()
  const options = loaderUtils.getOptions(this) || {}
  const name = resourceName(this.resourcePath)
  const dependencies = []

  const partialRegistration = emitPartialRegistration(this.resourcePath, name)

  const cssRegistration = options.injectBrandableStylesheet !== false ?
    buildCssReference(this.resourcePath, name) :
    ''
  ;

  const partials = findReferencedPartials(source)
  const partialRequirements = partials.map(x => nodePath.resolve(canvasDir, x))
  partialRequirements.forEach(requirement => dependencies.push(requirement))

  const result = compileHandlebars({path: this.resourcePath, source})
  if (result.error) {
    console.log('THERE WAS AN ERROR IN PRECOMPILATION', result)
    throw result
  }

  if (result.translationCount > 0) {
    dependencies.push(`i18n!${result.scope}`)
  }

  // make sure the template has access to all our handlebars helpers
  dependencies.push('@canvas/handlebars-helpers/index.coffee')

  const compiledTemplate = emitTemplate(
    this.resourcePath,
    name,
    result,
    dependencies,
    cssRegistration,
    partialRegistration
  )
  return compiledTemplate
}

function requireBrandableCSS() {
  const { cwd, chdir } = require('process')
  const oldCWD = cwd()

  // it looks for "config/brandable_css.yml" from cwd
  process.chdir(canvasDir)

  try {
    return require('@instructure/brandable_css')
  }
  finally {
    process.chdir(oldCWD)
  }
}

module.exports = i18nLinerHandlebarsLoader

module.exports.compile = (source, path, query) => {
  const context = {
    cacheable: () => {},
    resourcePath: path,
    query
  }
  return i18nLinerHandlebarsLoader.call(context, source)
}
