require_relative '../../spec_helper.rb'

describe Canvas::RequestForgeryProtection do
  before :each do
    # default setup is a protected non-GET non-API session-authenticated request with bogus tokens
    raw_headers = { 'X-CSRF-Token' => "bogus" }
    raw_headers = ActionDispatch::Request.new(raw_headers) unless CANVAS_RAILS4_2
    headers = ActionDispatch::Http::Headers.new(raw_headers)
    cookies = ActionDispatch::Cookies::CookieJar.new(nil)
    request = stub("request",
      host_with_port: "example.com:80",
      headers: headers,
      get?: false,
      head?: false)
    @controller = stub("controller",
      request: request,
      cookies: cookies,
      protect_against_forgery?: true,
      api_request?: false,
      in_app?: true,
      form_authenticity_param: "bogus")
    @controller.extend(Canvas::RequestForgeryProtection)
  end

  describe "form_authenticity_token" do
    it "should give a different token on each call" do
      token1 = @controller.form_authenticity_token
      token2 = @controller.form_authenticity_token
      expect(token2).not_to equal(token1)
    end

    it "should give equivalently valid tokens on each call" do
      token1 = @controller.form_authenticity_token
      token2 = @controller.form_authenticity_token
      expect(CanvasBreachMitigation::MaskingSecrets.valid_authenticity_token?(@controller.cookies, token1)).to be_truthy
      expect(CanvasBreachMitigation::MaskingSecrets.valid_authenticity_token?(@controller.cookies, token2)).to be_truthy
    end
  end

  describe "verified_request?" do
    it "should verify token" do
      expect(@controller.verified_request?).to be_falsey
    end

    it "should not verify token if protect_against_forgery? is false" do
      @controller.stubs(:protect_against_forgery?).returns(false)
      expect(@controller.verified_request?).to be_truthy
    end

    it "should not verify token if request.get? is true" do
      @controller.request.stubs(:get?).returns(true)
      expect(@controller.verified_request?).to be_truthy
    end

    it "should not verify token if request.head? is true" do
      @controller.request.stubs(:head?).returns(true)
      expect(@controller.verified_request?).to be_truthy
    end

    it "should not verify token if api_request? is true and in_app? is false" do
      @controller.stubs(:api_request?).returns(true)
      @controller.stubs(:in_app?).returns(false)
      expect(@controller.verified_request?).to be_truthy
    end

    it "should verify token if api_request? is true but in_app? is also true" do
      @controller.stubs(:api_request?).returns(true)
      @controller.stubs(:in_app?).returns(true)
      expect(@controller.verified_request?).to be_falsey
    end

    it "should count token as verified if form_authenticity_param is valid" do
      token = @controller.form_authenticity_token
      @controller.stubs(:form_authenticity_param).returns(token)
      expect(@controller.verified_request?).to be_truthy
    end

    it "should count token as verified if X-CSRF-Token header is valid" do
      token = @controller.form_authenticity_token
      @controller.request.headers['X-CSRF-Token'] = token
      expect(@controller.verified_request?).to be_truthy
    end
  end
end
