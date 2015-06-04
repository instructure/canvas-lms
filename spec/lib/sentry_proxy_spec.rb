require_relative "../spec_helper"

describe SentryProxy do
  let(:data){ {a: 'b', c: 'd'} }

  it "forwards exceptions on to raven" do
    e = StandardError.new
    Raven.expects(:capture_exception).with(e, data)
    SentryProxy.capture(e, data)
  end

  it "passes messages to the capture_message raven method" do
    e = "Some Message"
    Raven.expects(:capture_message).with(e, data)
    SentryProxy.capture(e, data)
  end

  it "changes symbols to strings because raven chokes otherwise" do
    e = :some_exception_type
    Raven.expects(:capture_message).with("some_exception_type", data)
    SentryProxy.capture(e, data)
  end
end
