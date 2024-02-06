/* eslint-disable import/no-unresolved */
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
const {EmberHandlebars} = require('ember-template-compiler')
const ScopedHbsExtractor = require('@instructure/i18nliner-canvas/scoped_hbs_extractor')
const ScopedHbsPreProcessor = require('@instructure/i18nliner-canvas/scoped_hbs_pre_processor')
const {readI18nScopeFromJSONFile} = require('@instructure/i18nliner-canvas/scoped_hbs_resolver')
const nodePath = require('path')
const loaderUtils = require('loader-utils')
const {canvasDir} = require('../params')

const {contriveId, config: brandableCSSConfig} = requireBrandableCSS()

const compileHandlebars = data => {
  const path = data.path
  const source = data.source
  try {
    let translationCount = 0
    const ast = Handlebars.parse(source)
    const scope = readI18nScopeFromJSONFile(path)
    const extractor = new ScopedHbsExtractor(ast, {path, scope})
    ScopedHbsPreProcessor.processWithScope(scope, ast)
    extractor.forEach(() => translationCount++)

    const precompiler = data.ember ? EmberHandlebars : Handlebars
    const template = precompiler.precompile(ast).toString()
    return {template, scope, translationCount}
  } catch (e) {
    console.error(e.message || e)
    throw e
  }
}

const emitTemplate = ({name, template, dependencies, cssRegistration, partialRegistration}) => {
  return `
    import _Handlebars from 'handlebars/runtime';

    var Handlebars = _Handlebars.default;
    ${dependencies.map(d => `import ${JSON.stringify(d)};`).join('\n')}

    var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
    var name = '${name}';
    templates[name] = template(${template});
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

// inject the template with the css file specified in the "brandableCSSBundle"
// property of the accompanying .json metadata file, if any
const buildCssReference = (path, _name) => {
  let bundle

  try {
    // eslint-disable-next-line import/no-dynamic-require
    bundle = require(`${path}.json`).brandableCSSBundle
  } catch (_) {
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

  const cssRegistration =
    options.injectBrandableStylesheet !== false ? buildCssReference(this.resourcePath, name) : ''
  const partials = findReferencedPartials(source)
  const partialRequirements = partials.map(x => nodePath.resolve(canvasDir, x))
  partialRequirements.forEach(requirement => dependencies.push(requirement))

  const result = compileHandlebars({path: this.resourcePath, source})
  if (result.error) {
    console.log('THERE WAS AN ERROR IN PRECOMPILATION', result)
    throw result
  }

  if (result.translationCount > 0) {
    dependencies.push('@canvas/i18n')
  }

  // make sure the template has access to all our handlebars helpers
  dependencies.push('@canvas/handlebars-helpers/index.js')

  return emitTemplate({
    name,
    template: result.template,
    dependencies,
    cssRegistration,
    partialRegistration,
  })
}

function requireBrandableCSS() {
  const {cwd} = require('process')
  const oldCWD = cwd()

  // it looks for "config/brandable_css.yml" from cwd
  process.chdir(canvasDir)

  try {
    return require('@instructure/brandable_css')
  } finally {
    process.chdir(oldCWD)
  }
}

module.exports = i18nLinerHandlebarsLoader

module.exports.compile = (source, path, query) => {
  const context = {
    cacheable: () => {},
    resourcePath: path,
    query,
  }
  return i18nLinerHandlebarsLoader.call(context, source)
}
