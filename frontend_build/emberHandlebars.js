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
// i18n object if it needs one, and any brandableCss variant stuff it needs.

const Handlebars = require('handlebars')
const EmberHandlebars = require('ember-template-compiler').EmberHandlebars
const ScopedHbsExtractor = require('i18nliner-canvas/js/scoped_hbs_extractor')
const PreProcessor = require('i18nliner-handlebars/dist/lib/pre_processor').default

function compileHandlebars(data) {
  const {path, source} = data
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
    const payload = {template, scope, translationCount}
    return payload
  } catch (e) {
    e = e.message || e
    console.log(e)
    throw {error: e}
  }
}

function resourceName(path) {
  return path.replace(/^.+?\/templates\//, '').replace(/\.hbs$/, '')
}

function emitTemplate(path, name, result, dependencies) {
  return `define(${JSON.stringify(dependencies)}, function(Ember){
    Ember.TEMPLATES['${name}'] = Ember.Handlebars.template(${result.template});
  });`
}

module.exports = function(source) {
  this.cacheable()
  const name = resourceName(this.resourcePath)
  const dependencies = ['ember', 'coffeescripts/ember/shared/helpers/common']

  const result = compileHandlebars({path: this.resourcePath, source, ember: true})

  if (result.error) {
    console.log('THERE WAS AN ERROR IN PRECOMPILATION', result)
    throw result
  }

  if (result.translationCount > 0) {
    dependencies.push(`i18n!${result.scope}`)
  }
  const compiledTemplate = emitTemplate(this.resourcePath, name, result, dependencies)
  return compiledTemplate
}
