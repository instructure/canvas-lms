const fs = require('fs')
const mkdirp = require('mkdirp')
const sass = require('node-sass')
const path = require('path')
const yaml = require('js-yaml')
const _ = require('lodash')

const browserSupport = _.map(yaml.safeLoad(fs.readFileSync('config/browsers.yml')).minimums, function(version, browserName) {
  return browserName.replace('Internet Explorer', 'Explorer') + ' >= ' + version
})
const autoprefixer = require('autoprefixer')(browserSupport)

// if you want compressed output (eg: in production), set the environment variable  CANVAS_SASS_STYLE=compressed
const outputStyle = process.env.CANVAS_SASS_STYLE || 'nested'

process.on('message', function(variantAndSassFile){
  var variant = variantAndSassFile[0],
      sassFile = variantAndSassFile[1],
      cssFolder = path.dirname(sassFile).replace(/^app\/stylesheets/, 'public/stylesheets_compiled/' + variant),
      cssFile = cssFolder + '/' + path.basename(sassFile).replace(/.s[ac]ss$/, '.css')

  // make sure the folder is there before we try to write the css file to it
  mkdirp.sync(cssFolder)

  sass.render({
    file: sassFile,
    success: function(css){
      css = autoprefixer.process(css, {cascade: false})
      fs.writeFile(cssFile, css, function(err) {
        if (err) return console.log(err)
        process.send('complete')
      })
    },
    includePaths: ['app/stylesheets', 'app/stylesheets/variants/' + variant],
    imagePath: '/images',
    outputStyle: outputStyle,
    sourceComments: (outputStyle === 'compressed' ? 'none' : 'normal'), // one of 'none', 'normal', 'map'
    sourceMap: false
  })
})