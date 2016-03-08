=begin
VeriCiteV1
=end

require 'spec_helper'
require 'json'
require 'date'

describe 'Error' do
  before do
    # run before each test
    @instance = VeriCiteClient::Error.new
  end

  after do
    # run after each test
  end

  describe 'test an instance of Error' do
    it 'should create an instact of Error' do
      @instance.should be_a(VeriCiteClient::Error) 
    end
  end
  describe 'test attribute "message"' do
    it 'should work' do
       # assertion here
       # should be_a()
       # should be_nil
       # should ==
       # should_not ==
    end
  end

end

