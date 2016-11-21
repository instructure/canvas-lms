# gergich capture custom:./build/gergich/xsslint:Gergich::XSSLint "node script/xsslint.js"
class Gergich::XSSLint
  def run(output)
    # e.g. alerts.js:110: possibly XSS-able argument to `append()`
    pattern = /^([^:\n]+):(\d+): (.*)$/

    output.scan(pattern).map { |file, line, error|
      { path: "public/javascripts/#{file}", message: "[xsslint] #{error}", position: line.to_i, severity: "error" }
    }.compact
  end
end
