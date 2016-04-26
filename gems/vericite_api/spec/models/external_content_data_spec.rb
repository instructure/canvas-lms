=begin
VeriCiteV1
=end

require 'spec_helper'
require 'json'
require 'date'

describe 'ExternalContentData' do
  before do
    # run before each test
    @instance = VeriCiteClient::ExternalContentData.new
  end

  after do
    # run after each test
  end

  describe 'test an instance of ExternalContentData' do
    it 'should create an instact of ExternalContentData' do
      @instance.should be_a(VeriCiteClient::ExternalContentData) 
    end
  end
  describe 'test attribute "file_name"' do
    it 'should work' do
       # assertion here
       # should be_a()
       # should be_nil
       # should ==
       # should_not ==
    end
  end

  describe 'test attribute "upload_content_type"' do
    it 'should work' do
       # assertion here
       # should be_a()
       # should be_nil
       # should ==
       # should_not ==
    end
  end

  describe 'test attribute "upload_content_length"' do
    it 'should work' do
       # assertion here
       # should be_a()
       # should be_nil
       # should ==
       # should_not ==
    end
  end

  describe 'test attribute "external_content_id"' do
    it 'should work' do
       # assertion here
       # should be_a()
       # should be_nil
       # should ==
       # should_not ==
    end
  end

end

