const XSSLint      = require("xsslint");
const Linter       = require("xsslint/linter");
const globby       = require("gglobby");
const fs           = require("fs");
const CoffeeScript = require("coffee-script");
const glob         = require("glob");
const babylon      = require("babylon");

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
const origIsSafeString = Linter.prototype.isSafeString;
Linter.prototype.isSafeString = function(node) {
  const result = origIsSafeString.call(this, node);
  if (result) return result;

  if (node.type !== "CallExpression") return false;

  const { type, object, property } = node.callee;
  if (type !== "MemberExpression") return false;
  if (object.type !== "Identifier" || object.name !== "I18n") return false;
  if (property.type !== "Identifier" || property.name !== "t" && property.name !== "translate") return false;

  const lastArg = node.arguments[node.arguments.length - 1];
  if (lastArg.type !== "ObjectExpression") return false;

  const hasWrapper = lastArg.properties.some((prop) => prop.key.name === "wrapper" || prop.key.name === "wrappers");
  return hasWrapper;
};

function getFilesAndDirs(root, files = [], dirs = []) {
  root = root === "." ? "" : root + "/";

  const entries = fs.readdirSync(root || ".");
  entries.forEach((entry) => {
    const stats = fs.lstatSync(root + entry);
    if (stats.isSymbolicLink()) {
    } else if (stats.isDirectory()) {
      dirs.push(root + entry + "/");
      getFilesAndDirs(root + entry, files, dirs);
    } else {
      files.push(root + entry);
    }
  });

  return [files, dirs];
}

function methodDescription(method) {
  switch(method) {
    case "+": return "HTML string concatenation";
    case "`": return "HTML template literal";
    default:  return `argument to \`${method}\``;
  }
}

const cwd = process.cwd();
let warningCount = 0;

const allPaths = [
  {
    paths: ["app/coffeescripts"].concat(glob.sync("gems/plugins/*/app/coffeescripts")),
    glob: "*.coffee",
    transform: (source) => CoffeeScript.compile(source, {})
  },
  {
    paths: ["app/jsx"].concat(glob.sync("gems/plugins/*/app/jsx")),
    glob: "*.jsx"
  },
  {
    paths: ["public/javascripts"].concat(glob.sync("gems/plugins/*/public/javascripts")),
    defaultIgnores: ['/compiled', '/jst', '/vendor'],
    glob: "*.js"
  }
]

allPaths.forEach(function({paths, glob, defaultIgnores = [], transform}) {
  paths.forEach(function(path) {
  process.chdir(path);
    const ignores = defaultIgnores.concat(
      fs.existsSync(".xssignore") ?
      fs.readFileSync(".xssignore").toString().trim().split(/\r?\n|\r/) :
      []
    );
    let candidates = getFilesAndDirs(".");
    candidates = {files: candidates[0], dirs: candidates[1]};

    const files = globby.select([glob], candidates).reject(ignores).files;

    console.log(`Checking ${path} (${files.length} files) for potential XSS vulnerabilities...`);

    files.forEach(function(file) {
      let source = fs.readFileSync(file).toString();
      if (transform) source = transform(source);
      source = babylon.parse(source, { plugins: ["jsx", "classProperties", "objectRestSpread"], sourceType: "module" });

      const warnings = XSSLint.run({source});
      warningCount += warnings.length;
      warnings.forEach(({line, method}) => {
        console.error(`${path}/${file}:${line}: possibly XSS-able ${methodDescription(method)}`);
      })
    });

    process.chdir(cwd);
  })
});

if (warningCount) {
  console.error(`\u{1b}[31mFound ${warningCount} potential vulnerabilities\u{1b}[0m`);
  process.exit(1)
} else {
  console.log("No problems found!")
}
