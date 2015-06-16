require 'minitest/autorun'
require 'autoextend'

describe Autoextend do
  let(:klass) do
    Class.new do
      include Autoextend

      def instance_method_with_feature
        instance_method_without_feature + 'extended'
      end

      def self.class_method_with_feature
        'extended' + class_method_without_feature
      end
    end
  end

  def add_instance_method
    klass.class_eval do
      def instance_method
        'instance'
      end
    end
  end

  def add_class_method
    klass.class_eval do
      def self.class_method
        'class'
      end
    end
  end

  it "should autoextend an instance method afterwards" do
    klass.autoextend(:instance_method, :feature)
    add_instance_method
    klass.new.instance_method.must_equal "instanceextended"
  end

  it "should autoextend an already defined instance method" do
    add_instance_method
    klass.autoextend(:instance_method, :feature)
    klass.new.instance_method.must_equal "instanceextended"
  end

  it "should autoextend a class method afterwards" do
    klass.autoextend_singleton(:class_method, :feature)
    add_class_method
    klass.class_method.must_equal "extendedclass"
  end

  it "should autoextend an already defined class method" do
    add_class_method
    klass.autoextend_singleton(:class_method, :feature)
    klass.class_method.must_equal "extendedclass"
  end
end
