const cypress = require("cypress")
const Webpack = require("webpack")
const WebpackDevServer = require("webpack-dev-server/lib/Server")
const webpackConfig = require("../webpack.config")

const compiler = Webpack(webpackConfig)

const server = new WebpackDevServer(compiler, webpackConfig.devServer)

server.listen(8080, "127.0.0.1", () => {
  const config = {
    video: false
  }
  cypress.run({ config }).then(results => {
    server.close()
    // Exit non-zero if there were any failures
    return process.exit(results.failures)
  })
})
