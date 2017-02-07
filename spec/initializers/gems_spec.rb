require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'Gemfile' do
  it 'should not include libxml-ruby' do
    libxml = Bundler.locked_gems.specs.find { |s| s.name == 'libxml-ruby' }
    expect(libxml).to be_nil,
      "libxml-ruby is incompatible with nokogiri and causes heap corruption"
  end
end
