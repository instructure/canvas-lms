# encoding: utf-8

require File.expand_path('../spec_helper', File.dirname( __FILE__ ))

describe 'rails2 compatibility' do
  before :each do
    pending "only for rails2 compatibility" unless CANVAS_RAILS2
  end

  describe 'validate :on' do
    before :each do
      @klass = Class.new(ActiveRecord::Base)
    end

    it "should turn on: :create into a validate_on_create call" do
      @klass.expects(:validate_on_create).with(:method, on: :create)
      @klass.validate :method, on: :create
    end

    it "should turn on: :update into a validate_on_update call" do
      @klass.expects(:validate_on_update).with(:method, on: :update)
      @klass.validate :method, on: :update
    end

    it "should let on: :save through" do
      @klass.expects(:validate_without_rails3_compatibility).with(:method, on: :save)
      @klass.validate :method, on: :save
    end

    it "should let absent :on through" do
      @klass.expects(:validate_without_rails3_compatibility).with(:method)
      @klass.validate :method
    end

    it "should preserve other options/arguments" do
      @klass.expects(:validate_on_create).with(:method, {on: :create, foo: 'bar'})
      @klass.validate :method, on: :create, foo: 'bar'
    end

    it "should preserve blocks" do
      block = lambda{}
      @klass.expects(:validate_on_create).with(:method, block, on: :create)
      @klass.validate(:method, on: :create, &block)
    end
  end

  describe 'before_validation :on' do
    before :each do
      @klass = Class.new(ActiveRecord::Base)
    end

    it "should turn on: :create into a before_validation_on_create call" do
      @klass.expects(:before_validation_on_create).with(:method, on: :create)
      @klass.before_validation :method, on: :create
    end

    it "should turn on: :update into a before_validation_on_update call" do
      @klass.expects(:before_validation_on_update).with(:method, on: :update)
      @klass.before_validation :method, on: :update
    end

    it "should let on: :save through" do
      @klass.expects(:before_validation_without_rails3_compatibility).with(:method, on: :save)
      @klass.before_validation :method, on: :save
    end

    it "should let absent :on through" do
      @klass.expects(:before_validation_without_rails3_compatibility).with(:method)
      @klass.before_validation :method
    end

    it "should preserve other options/arguments" do
      @klass.expects(:before_validation_on_create).with(:method, {on: :create, foo: 'bar'})
      @klass.before_validation :method, on: :create, foo: 'bar'
    end

    it "should preserve blocks" do
      block = lambda{}
      @klass.expects(:before_validation_on_create).with(:method, block, on: :create)
      @klass.before_validation(:method, on: :create, &block)
    end
  end

  describe "Rails.env=" do
    before :each do
      @current_rails_env = Rails.env
    end

    after :each do
      Rails.env = @current_rails_env if CANVAS_RAILS2
    end

    it "should set the env" do
      Rails.env = "development"
      Rails.env.should == "development"
    end

    it "should work cast the value to an 'inquirer'" do
      Rails.env = "development"
      Rails.env.development?.should == true
    end
  end
end
