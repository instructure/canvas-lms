require 'ritex'

module Latex
  class MathMl
    def initialize(latex:)
      @latex = latex
    end
    attr_reader :latex

    def parse
      CanvasStatsd::Statsd.time("#{strategy}.parse_attempt") do
        CanvasStatsd::Statsd.increment("#{strategy}.parse_attempt.count")
        begin
          send(:"#{strategy}_parse")
        rescue Racc::ParseError, Ritex::LexError, Ritex::Error,
          CanvasHttp::Error, Timeout::Error
          CanvasStatsd::Statsd.increment("#{strategy}.parse_failure.count")
          return ""
        end
      end
    end

    private
    def mathman_parse
      url = MathMan.url_for(latex: CGI.escape(latex), target: :mml)
      request_id = RequestContextGenerator.request_id
      request_id_signature = Canvas::Security.sign_hmac_sha512(request_id)
      Canvas.timeout_protection("mathman") do
        response = CanvasHttp.get(url, {
          'X-Request-Context-Id' => Canvas::Security.base64_encode(request_id),
          'X-Request-Context-Signature' => Canvas::Security.base64_encode(request_id_signature)
        })
        if response.code.to_i == 200
          response.body
        else
          Canvas::Errors.capture_exception(
            :mathman_request,
            CanvasHttp::InvalidResponseCodeError.new(response.code.to_i)
          )
          return ""
        end
      end
    end

    def ritex_parse
      Ritex::Parser.new.parse(latex)
    end

    def strategy
      MathMan.use_for_mml? ? :mathman : :ritex
    end
  end
end
