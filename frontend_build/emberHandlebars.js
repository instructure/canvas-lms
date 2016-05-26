// This is basically one big port of what we do in ruby-land in the
// handlebars-tasks gem.  We need to run handlebars source through basic
// compilation to extract i18nliner scopes, and then we wrap the resulting
// template in an AMD module, giving it dependencies on handlebars, it's scoped
// i18n object if it needs one, and any brandableCss variant stuff it needs.

var Handlebars = require('handlebars');
var EmberHandlebars = require('ember-template-compiler').EmberHandlebars;
var ScopedHbsExtractor = require(__dirname + '/../gems/canvas_i18nliner/js/scoped_hbs_extractor');
var PreProcessor = require(__dirname + '/../gems/canvas_i18nliner/node_modules/i18nliner-handlebars/dist/lib/pre_processor');
var fs = require('fs');
var child_process = require('child_process');

var compileHandlebars = function(data){
  var path = data.path;
  var source = data.source;
  try {
    var translationCount = 0;
    var ast = Handlebars.parse(source);
    var extractor = new ScopedHbsExtractor(ast, {path: path});
    var scope = extractor.scope;
    PreProcessor.scope = scope;
    PreProcessor.process(ast);
    extractor.forEach(function() { translationCount++; });

    var precompiler = data.ember ? EmberHandlebars : Handlebars;
    var result = precompiler.precompile(ast).toString();
    var payload = {template: result, scope: scope, translationCount: translationCount};
    return payload;
  }
  catch (e) {
    e = e.message || e;
    console.log(e);
    throw {error: e};
  }
};

var resourceName = function(path){
  return path
    .replace(/^.+?\/templates\//, '')
    .replace(/\.hbs$/, '');
};

var emitTemplate = function(path, name, result, dependencies){
  return "" +
    "define(" + JSON.stringify(dependencies) + ", function(Ember){\n" +
      "Ember.TEMPLATES['" + name + "'] = " + 
        "Ember.Handlebars.template(" + result['template']+ ");\n" + 
    "});";
};

module.exports = function (source) {
  this.cacheable();
  var name = resourceName(this.resourcePath)
  var dependencies = ['shims/ember', 'coffeescripts/ember/shared/helpers/common'];

  var result = compileHandlebars({path: this.resourcePath, source: source, ember: true});

  if(result['error']){
    console.log("THERE WAS AN ERROR IN PRECOMPILATION", result);
    throw result;
  }

  if(result["translationCount"] > 0){
    dependencies.push("i18n!" + result["scope"] +"");
  }
  var compiledTemplate = emitTemplate(this.resourcePath, name, result, dependencies);
  return compiledTemplate;
};
