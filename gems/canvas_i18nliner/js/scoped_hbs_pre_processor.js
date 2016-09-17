var I18nlinerHbs = require("i18nliner-handlebars");
var PreProcessor = require("i18nliner-handlebars/dist/lib/pre_processor");
var Handlebars = require("handlebars");
var AST = Handlebars.AST;
var StringNode = AST.StringNode;
var HashNode = AST.HashNode;

// slightly more lax interpolation key format for hbs to support any
// existing translations (camel case and dot syntax, e.g. "foo.bar.baz")
PreProcessor.normalizeInterpolationKey = function(key) {
  key = key.replace(/[^a-z0-9.]/gi, ' ');
  key = key.trim();
  key = key.replace(/ +/g, '_');
  return key.substring(0, 32);
};

// add explicit scope to all t calls (post block -> inline transformation)
var _processStatement = PreProcessor.processStatement;
PreProcessor.processStatement = function(statement) {
  statement = _processStatement.call(this, statement) || statement;
  if (statement.type === 'mustache' && statement.id.string === 't')
    return this.injectScope(statement);
}

PreProcessor.injectScope = function(node) {
  var pairs;
  if (!node.hash)
    node.hash = node.sexpr.hash = new HashNode([]);
  pairs = node.hash.pairs;
  // to match our .rb scoping behavior, don't scope inferred keys...
  // if inferred, it's always the last option
  if (!pairs.length || pairs[pairs.length - 1][0] !== "i18n_inferred_key") {
    node.hash.pairs = pairs.concat([["scope", new StringNode(this.scope)]]);
  }
  return node;
}
