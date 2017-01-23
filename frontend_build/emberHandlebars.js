// This is basically one big port of what we do in ruby-land in the
// handlebars-tasks gem.  We need to run handlebars source through basic
// compilation to extract i18nliner scopes, and then we wrap the resulting
// template in an AMD module, giving it dependencies on handlebars, it's scoped
// i18n object if it needs one, and any brandableCss variant stuff it needs.

const Handlebars = require('handlebars');
const EmberHandlebars = require('ember-template-compiler').EmberHandlebars;
const ScopedHbsExtractor = require(`${__dirname}/../gems/canvas_i18nliner/js/scoped_hbs_extractor`);
const PreProcessor = require(`${__dirname}/../gems/canvas_i18nliner/node_modules/i18nliner-handlebars/dist/lib/pre_processor`);
const fs = require('fs');
const child_process = require('child_process');

const compileHandlebars = function (data) {
  const path = data.path;
  const source = data.source;
  try {
    let translationCount = 0;
    const ast = Handlebars.parse(source);
    const extractor = new ScopedHbsExtractor(ast, { path });
    const scope = extractor.scope;
    PreProcessor.scope = scope;
    PreProcessor.process(ast);
    extractor.forEach(() => { translationCount++; });

    const precompiler = data.ember ? EmberHandlebars : Handlebars;
    const result = precompiler.precompile(ast).toString();
    const payload = { template: result, scope, translationCount };
    return payload;
  } catch (e) {
    e = e.message || e;
    console.log(e);
    throw { error: e };
  }
};

const resourceName = function (path) {
  return path
    .replace(/^.+?\/templates\//, '')
    .replace(/\.hbs$/, '');
};

const emitTemplate = function (path, name, result, dependencies) {
  return `${'' +
    'define('}${JSON.stringify(dependencies)}, function(Ember){\n` +
      `Ember.TEMPLATES['${name}'] = ` +
        `Ember.Handlebars.template(${result.template});\n` +
    '});';
};

module.exports = function (source) {
  this.cacheable();
  const name = resourceName(this.resourcePath)
  const dependencies = ['ember', 'coffeescripts/ember/shared/helpers/common'];

  const result = compileHandlebars({ path: this.resourcePath, source, ember: true });

  if (result.error) {
    console.log('THERE WAS AN ERROR IN PRECOMPILATION', result);
    throw result;
  }

  if (result.translationCount > 0) {
    dependencies.push(`i18n!${result.scope}`);
  }
  const compiledTemplate = emitTemplate(this.resourcePath, name, result, dependencies);
  return compiledTemplate;
};
