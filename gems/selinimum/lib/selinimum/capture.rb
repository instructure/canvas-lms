module Selinimum
  class Capture
    # hooks so we know which templates are rendered in each selenium spec
    module TemplateExtensions
      def render_with_selinimum(template, *args, &block)
        Selinimum::Capture.log_template_render inspect
        render_without_selinimum(template, *args, &block)
      end

      def self.included(klass)
        klass.alias_method_chain :render, :selinimum
      end
    end

    # hooks so we know which controllers, js and css are used in each
    # selenium spec
    module ControllerExtensions
      def render_with_selinimum(*args)
        Selinimum::Capture.log_render self.class
        render_without_selinimum(*args)
      end

      def css_bundle_with_selinimum(*args)
        Selinimum::Capture.log_bundle :css, *args
        css_bundle_without_selinimum(*args)
      end

      def js_bundle_with_selinimum(*args)
        Selinimum::Capture.log_bundle :js, *args
        js_bundle_without_selinimum(*args)
      end

      def self.included(klass)
        klass.alias_method_chain :render, :selinimum
        klass.alias_method_chain :css_bundle, :selinimum
        klass.alias_method_chain :js_bundle, :selinimum
      end
    end

    class << self
      def install!
        ActionView::Template.send :include, TemplateExtensions
        ApplicationController.send :include, ControllerExtensions
      end

      def dependencies
        @dependencies ||= Hash.new { |h, k| h[k] = Set.new }
      end

      attr_reader :current_example

      def current_example=(example)
        @current_file = nil
        @current_example = example
      end

      def current_file
        @current_file ||= current_example.metadata[:example_group][:file_path].sub(/\A\.\//, '')
      end

      def report!(batch_name)
        data = Hash[dependencies.map { |k, v| [k, v.to_a] }].to_json

        StatStore.save_stats(data, batch_name)
      end

      def finalize!
        StatStore.finalize!
      end

      def log_render(controller)
        classes = controller.ancestors - controller.included_modules
        classes = classes.take_while { |klass| klass < ApplicationController }
        classes.each do |klass|
          dependencies[current_file] << "file:app/controllers/#{klass.name.underscore}.rb"
        end
      end

      def log_template_render(file)
        unless file =~ Selinimum::Detectors::RubyDetector::GLOBAL_FILES
          dependencies[current_file] << "file:#{file}"
        end
      end

      def log_bundle(type, *args)
        args.each do |bundle|
          dependencies[current_file] << "#{type}:#{bundle}"
        end
      end
    end
  end
end
