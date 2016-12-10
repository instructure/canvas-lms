var XSSLint    = require("xsslint");
var Linter     = require("xsslint/linter");
var globby     = require("gglobby");
var fs         = require("fs");

XSSLint.configure({
  "xssable.receiver.whitelist": ["formData"],
  "jqueryObject.identifier": [/^\$/],
  "jqueryObject.property":   [/^\$/],
  "safeString.identifier":   [/(_html|Html|View|Template)$/, "html", "id"],
  "safeString.function":     ["h", "htmlEscape", "template", /(Template|View|Dialog)$/],
  "safeString.property":     ["template", "id", "height", "width", /_id$/],
  "safeString.method":       ["$.raw", "template", /(Template|Html)$/, "toISOString", "friendlyDatetime", /^(date|(date)?time)String$/]
});

// treat I18n.t calls w/ wrappers as html-safe, since they are
var origIsSafeString = Linter.prototype.isSafeString;
Linter.prototype.isSafeString = function(node) {
  var result = origIsSafeString.call(this, node);
  if (result) return result;

  if (node.type !== "CallExpression") return false;
  var callee = node.callee;
  if (callee.type !== "MemberExpression") return false;
  if (callee.object.type !== "Identifier" || callee.object.name !== "I18n") return false;
  if (callee.property.type !== "Identifier" || callee.property.name !== "t" && callee.property.name !== "translate") return false;
  var lastArg = node.arguments[node.arguments.length - 1];
  if (lastArg.type !== "ObjectExpression") return false;
  var wrapperOption = lastArg.properties.filter(function(prop){
    return prop.key.name === "wrapper" || prop.key.name === "wrappers";
  });
  return (wrapperOption.length > 0)
}

function getFilesAndDirs(root, files, dirs) {
  root = root === "." ? "" : root + "/";
  files = files || [];
  dirs = dirs || [];
  var entries = fs.readdirSync(root || ".");
  var entry;
  var i;
  var len;
  for (i = 0, len = entries.length; i < len; i++) {
    entry = entries[i];
    var stats = fs.lstatSync(root + entry);
    if (stats.isSymbolicLink()) {
    } else if (stats.isDirectory()) {
      dirs.push(root + entry + "/");
      getFilesAndDirs(root + entry, files, dirs);
    } else {
      files.push(root + entry);
    }
  }
  return [files, dirs];
}

process.chdir("public/javascripts");
var ignores = fs.readFileSync(".xssignore").toString().trim().split(/\r?\n|\r/);
var candidates = getFilesAndDirs(".");
candidates = {files: candidates[0], dirs: candidates[1]};
var files = globby.select(["*.js"], candidates).reject(ignores).files;
var warningCount = 0;

console.log("Checking for potential XSS vulnerabilities...");
files.forEach(function(file) {
  var warnings = XSSLint.run(file);
  warningCount += warnings.length;
  for (var i = 0, len = warnings.length; i < len; i++) {
    var warning = warnings[i];
    console.error(file + ":" + warning.line + ": possibly XSS-able " + (warning.method == "+" ? "HTML string concatenation" : "argument to `" + warning.method + "`"));
  }
});

if (warningCount) {
  console.error("\033[31mFound " + warningCount + " potential vulnerabilities\033[0m");
  process.exit(1)
} else {
  console.log("No problems found!")
}
