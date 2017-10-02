const Url = require("url")
const Path = require("path")
const formatMessage = require("../format-message")

function filename(url) {
  const parsedURL = Url.parse(url)
  return Path.basename(parsedURL.pathname)
}

module.exports = function describe(elem) {
  switch (elem.tagName) {
    case "IMG":
      return formatMessage("Image with filename {file}", {
        file: filename(elem.href)
      })
  }
}
