require 'webrick'

class SpecFriendlyWEBrickServer < ::WEBrick::HTTPServlet::AbstractServlet
  MAX_SERVER_START_TIME = 30

  def initialize(server, app)
    super server
    @app = Rack::ContentLength.new(app)
  end

  def self.run(app, options = {})
    @server = WEBrick::HTTPServer.new(options)
    @server.mount "/", Rack::Handler::WEBrick, app
    Thread.new { @server.start }
    for i in 0..MAX_SERVER_START_TIME
      begin
        s = TCPSocket.open('127.0.0.1', options[:Port])
      rescue
        nil
      end
      break if s
      sleep 1
    end
  end

  def self.shutdown
    @server.shutdown if @server
    @server = nil
  end

  def service(req, res)
    env = req.meta_vars
    env.delete_if { |_k, v| v.nil? }

    rack_input = StringIO.new(req.body.to_s)
    rack_input.set_encoding(Encoding::BINARY) if rack_input.respond_to?(:set_encoding)

    env.update({"rack.version" => Rack::VERSION,
                 "rack.input" => rack_input,
                 "rack.errors" => $stderr,

                 "rack.multithread" => true,
                 "rack.multiprocess" => false,
                 "rack.run_once" => false,

                 "rack.url_scheme" => ["yes", "on", "1"].include?(ENV["HTTPS"]) ? "https" : "http"
               })

    env["HTTP_VERSION"] ||= env["SERVER_PROTOCOL"]
    env["QUERY_STRING"] ||= ""
    env["REQUEST_PATH"] ||= "/"
    unless env["PATH_INFO"] == ""
      path, n = req.fullpath.path, env["SCRIPT_NAME"].length
      env["PATH_INFO"] = path[n, path.length-n]
    end

    status, headers, body = @app.call(env)
    begin
      res.status = status.to_i
      headers.each { |k, vs|
        if k.downcase == "set-cookie"
          res.cookies.concat vs.split("\n")
        else
          vs.split("\n").each { |v|
            res[k] = v
          }
        end
      }
      body.each { |part|
        res.body << part
      }
    ensure
      body.close  if body.respond_to? :close
    end
  end
end
