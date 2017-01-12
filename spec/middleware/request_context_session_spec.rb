require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "RequestContextSession" do
  it "should find the session_id from the rack session and add it a cookie" do
    env = { 'rack.session.options' => { id: 'abc' } }
    _, headers, _ = RequestContextSession.new(->(env) {
      [200, {}, []]
    }).call(env)
    expect(env['action_dispatch.cookies']['log_session_id']).to eq 'abc'
  end
end
