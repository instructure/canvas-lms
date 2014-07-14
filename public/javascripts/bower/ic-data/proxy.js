var http = require('http');
var httpProxy = require('http-proxy');
var path = require('path');

main();

function main() {
  var config = readConfig();
  validate(config);
  createServer(config);
}

function createServer(config) {
  var proxy = httpProxy.createProxyServer({});
  var server = require('http').createServer(function(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    res.setHeader('Access-Control-Expose-Headers', 'link');
    if ('OPTIONS' == req.method) {
      res.writeHead(200);
      res.end();
    } else {
      req.headers['Authorization'] = 'Bearer '+config.token;
      proxy.web(req, res, { target: config.host });
    }
  });
  console.log("Canvas proxy server listening on port "+config.port)
  server.listen(config.port);
}

function readConfig() {
  try {
    var config = require(path.resolve('proxy-config.json'));
    config.port = config.port || 8080;
  } catch (e) {
    console.log('Please create a proxy-config.json');
    process.exit();
  }
  return config;
}

function validate(config) {
  if (!config.token) {
    console.log('Please add a "token" to proxy-config.json');
    process.exit();
  }
  if (!config.host) {
    console.log('Please add a "host" to proxy-config.json');
    process.exit();
  }
}

