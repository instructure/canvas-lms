// This is basically one big port of what we do in ruby-land in the
// handlebars-tasks gem.  We need to run handlebars source through basic
// compilation to extract i18nliner scopes, and then we wrap the resulting
// template in an AMD module, giving it dependencies on handlebars, it's scoped
// i18n object if it needs one, and any brandableCss variant stuff it needs.

var Handlebars = require('handlebars');
var EmberHandlebars = require('ember-template-compiler').EmberHandlebars;
var ScopedHbsExtractor = require(__dirname + '/../gems/canvas_i18nliner/js/scoped_hbs_extractor');
var PreProcessor = require(__dirname + '/../gems/canvas_i18nliner/node_modules/i18nliner-handlebars/dist/lib/pre_processor')['default'];
var fs = require('fs');
var brandableCss = require(__dirname + "/brandableCss")

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



var emitTemplate = function(path, name, result, dependencies, cssRegistration, partialRegistration){
  var moduleName = "jst/" + path.replace(/.*\/\jst\//, '').replace(/\.handlebars/, "");
  return "" +
    "define('"+ moduleName +"', " + JSON.stringify(dependencies) + ", function(Handlebars){\n" +
      "var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};\n" +
      "templates['" + name + "'] = template("+ result['template'] +");\n" +
      partialRegistration + "\n" +
      cssRegistration + "\n" +
      "return templates['"+ name +"'];\n" +
    "});";
};

var resourceName = function(path){
  return path
    .replace(/^.+\/app\/views\/jst\/(?:plugins\/[^\/]*\/)?/, '')
    .replace(/\.handlebars$/, '')
    .replace(/_/g, '-');
};

var buildCssReference = function(name){
  var matchingCssPath = __dirname + "/../app/stylesheets/jst/" + name + ".scss";
  try {
    var cssStat = fs.statSync(matchingCssPath);
    if(cssStat.isFile()){
      var bundle = "jst/" + name;
      var cached = brandableCss.allFingerprintsFor(bundle)
      var firstVariant = Object.keys(cached)[0];
      var options = "";
      if(cached[firstVariant]['includesNoVariables']){
        options = JSON.stringify(cached[firstVariant]);
      }else{
        options = JSON.stringify(cached) + "[arguments[1].getCssVariant()]";
      }
      var css_registration = "\n"+
        "var options = " + options + ";\n" +
        "arguments[1].loadStylesheet('" + bundle + "', options);\n";
      return css_registration;
    }
  } catch(e) {
    if(e.code == 'ENOENT'){
      // no matching css file, just return a blank string;
      return "";
    }else{
      throw e;
    }
  }
}

var findReferencedPartials = function(source){
  var partialRegexp = /\{\{>\s?\[?(.+?)\]?( .*?)?}}/g;
  var partials = [];
  var match;
  while(match = partialRegexp.exec(source)){
    partials.push(match[1].trim());
  }

  var uniquePartials = partials.filter(function(elem, pos) {
    return partials.indexOf(elem) == pos;
  });

  return uniquePartials;
};

var emitPartialRegistration = function(path, resourceName){
  var baseName = path.split("/").pop();
  if(baseName.indexOf("_") == 0){
    var partialName = baseName.replace(/^_/, "");
    var partialPath = path.replace(baseName, partialName).replace(/.*\/\jst\//, '').replace(/\.handlebars/, "");
    var partialRegistration = "" +
      "\nHandlebars.registerPartial('" + partialPath + "', "+
                                 "templates['" + resourceName +"']);\n";
    return partialRegistration;
  } else {
    return "";
  }
};

var buildPartialRequirements = function(partialPaths){
  var requirements = [];
  partialPaths.forEach(function(partial){
    var partialParts = partial.split("/");
    partialParts[partialParts.length - 1] = "_" + partialParts[partialParts.length - 1];
    var requirePath = partialParts.join("/");
    requirements.push("jst/" + requirePath);
  });
  return requirements;
};

module.exports = function (source) {
  this.cacheable();
  var name = resourceName(this.resourcePath)
  var dependencies = ['handlebars'];

  var partialRegistration = emitPartialRegistration(this.resourcePath, name);

  var cssRegistration = buildCssReference(name);
  if(cssRegistration != ""){
    // arguments[1] will be brandableCss
    dependencies.push("compiled/util/brandableCss");
  }

  var partials = findReferencedPartials(source);
  var partialRequirements = buildPartialRequirements(partials);
  partialRequirements.forEach(function(requirement){
    dependencies.push(requirement);
  });

  var result = compileHandlebars({path: this.resourcePath, source: source});

  if(result['error']){
    console.log("THERE WAS AN ERROR IN PRECOMPILATION", result);
    throw result;
  }

  if(result["translationCount"] > 0){
    dependencies.push("i18n!" + result["scope"] +"");
  }
  var compiledTemplate = emitTemplate(this.resourcePath, name, result, dependencies, cssRegistration, partialRegistration);
  return compiledTemplate;
};
