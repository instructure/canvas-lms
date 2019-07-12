import 'babel-polyfill'
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

// make sure we don't try to cache JSX assets when building for production
productionWebpackConfig.module.loaders.forEach(function(loader){
  if(loader.loaders){
    var babelCacheIndex = loader.loaders.indexOf("babel?cacheDirectory=tmp")
    if(babelCacheIndex > -1){
      loader.loaders[babelCacheIndex] = "babel"
    }
  }else if(loader.loader == "babel?cacheDirectory=tmp"){
    loader.loader = "babel"
  }
})

if (!process.env.JS_BUILD_NO_UGLIFY) {
  productionWebpackConfig.plugins.push(new webpack.optimize.UglifyJsPlugin({
    sourceMap: false,
    mangle: false,
    comments: false
  }));
}

module.exports = productionWebpackConfig;
