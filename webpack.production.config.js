var webpack = require("webpack");
var baseWebpackConfig = require("./frontend_build/baseWebpackConfig");
var productionWebpackConfig = baseWebpackConfig;

var publicPath = "/webpack-dist-optimized/"
if(process.env.NODE_ENV == 'production'){
  var yaml = require('js-yaml');
  var fs   = require('fs');
  try {
    var doc = yaml.safeLoad(fs.readFileSync(__dirname + '/config/canvas_cdn.yml', 'utf8'));
    publicPath = doc.production.host + "/dist" + publicPath;
    console.log(publicPath);
  } catch (e) {
    console.log("NO CDN FILE, USING LOCAL ASSETS");
  }
}

productionWebpackConfig.devtool = undefined;
productionWebpackConfig.output.path = __dirname + '/public/webpack-dist-optimized';
productionWebpackConfig.output.publicPath = publicPath;
productionWebpackConfig.plugins.push(new webpack.optimize.UglifyJsPlugin({
  sourceMap: false,
  mangle: false,
  comments: false
}));


module.exports = productionWebpackConfig;
