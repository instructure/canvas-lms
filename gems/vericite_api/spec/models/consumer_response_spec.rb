=begin
VeriCiteV1
=end

require 'spec_helper'
require 'json'
require 'date'

describe 'ConsumerResponse' do
  before do
    # run before each test
    @instance = VeriCiteClient::ConsumerResponse.new
  end

  after do
    # run after each test
  end

  describe 'test an instance of ConsumerResponse' do
    it 'should create an instact of ConsumerResponse' do
      @instance.should be_a(VeriCiteClient::ConsumerResponse) 
    end
  end
  describe 'test attribute "consumer_key"' do
    it 'should work' do
       # assertion here
       # should be_a()
       # should be_nil
       # should ==
       # should_not ==
    end
  end

  describe 'test attribute "consumer_secret"' do
    it 'should work' do
       # assertion here
       # should be_a()
       # should be_nil
       # should ==
       # should_not ==
    end
  end

end

