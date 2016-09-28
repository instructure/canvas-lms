var webpack = require("webpack");
var baseWebpackConfig = require("./frontend_build/baseWebpackConfig");
var productionWebpackConfig = baseWebpackConfig;

var publicPath = "/webpack-dist-optimized/"

var yaml = require('js-yaml');
var fs   = require('fs');
try {
  var doc = yaml.safeLoad(fs.readFileSync(__dirname + '/config/canvas_cdn.yml', 'utf8'));
  var cdnHost = doc.production.host
  if(cdnHost !== undefined && cdnHost !== null){
    publicPath = cdnHost + "/dist" + publicPath;
    console.log(publicPath);
  }else{
    console.log("NO CDN HOST, USING LOCAL ASSETS");
  }
} catch (e) {
  console.log("NO CDN FILE, USING LOCAL ASSETS");
}

productionWebpackConfig.devtool = 'cheap-source-map';
productionWebpackConfig.output.path = __dirname + '/public/webpack-dist-optimized';
productionWebpackConfig.output.publicPath = publicPath;



if (!process.env.JS_BUILD_NO_UGLIFY) {
  productionWebpackConfig.plugins.push(new webpack.optimize.UglifyJsPlugin({
    compress: {
      screw_ie8: true,
      warnings: true
    },
    mangle: {
      screw_ie8: true
    },
    output: {
      comments: false,
      screw_ie8: true
    }
  }));
}

module.exports = productionWebpackConfig;
