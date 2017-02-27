require_relative 'git_proxy'

module TatlTael
  class Linter

    attr_reader :git
    private :git

    attr_reader :git_dir
    private :git_dir

    def initialize(git_dir: ".", git: nil)
      @git_dir = git_dir
      @git = git || TatlTael::GitProxy.new(git_dir)
    end

    def ban_new_erb
      yield if new_erb?
    end

    def ensure_coffee_specs
      yield if needs_coffee_specs? && !coffee_specs?
    end

    def ensure_jsx_specs
      yield if needs_jsx_specs? && !jsx_specs?
    end

    def ensure_public_js_specs
      yield if needs_public_js_specs? && !public_js_specs
    end

    def ensure_ruby_specs
      yield if needs_ruby_specs? && !ruby_specs?
    end

    def ensure_no_unnecessary_selenium_specs
      yield if selenium_specs? && (
        needs_public_js_specs? && !public_js_specs ||
        needs_coffee_specs? && !coffee_specs? ||
        needs_jsx_specs? && !jsx_specs? ||
        needs_ruby_specs? && !ruby_specs?
      )
    end

    def wip?
      git.wip?
    end

    ERB_REGEX = /app\/views\/.*\.erb$/
    def new_erb?
      changes.any? do |change|
        change.path =~ ERB_REGEX &&
          change.added?
      end
    end

    NEED_SPEC_PUBLIC_JS_REGEX = /public\/javascripts\/.*\.js$/
    EXCLUDED_PUBLIC_SUB_DIRS_REGEX = /(bower|mediaelement|shims|vendor|symlink_to_node_modules)\//
    def needs_public_js_specs?
      changes.any? do |change|
        !change.deleted? &&
          change.path =~ NEED_SPEC_PUBLIC_JS_REGEX &&
          change.path !~ EXCLUDED_PUBLIC_SUB_DIRS_REGEX
      end
    end

    PUBLIC_JS_SPEC_REGEX = /spec\/(coffeescripts|javascripts)\//
    def public_js_specs
      changes.any? do |change|
        !change.deleted? &&
          change.path =~ PUBLIC_JS_SPEC_REGEX
      end
    end

    NEED_COFFEE_SPECS_REGEX = /app\/coffeescripts\/.*\.coffee$/
    EXCLUDED_COFFEE_SUB_DIRS_REGEX = /bundles\//
    def needs_coffee_specs?
      changes.any? do |change|
        !change.deleted? &&
          change.path =~ NEED_COFFEE_SPECS_REGEX &&
          change.path !~ EXCLUDED_COFFEE_SUB_DIRS_REGEX
      end
    end

    COFFEE_SPEC_REGEX = /spec\/coffeescripts\//
    JSX_SPEC_REGEX = /spec\/(coffeescripts|javascripts)\/jsx\//
    def coffee_specs?
      changes.any? do |change|
        !change.deleted? &&
          (change.path =~ COFFEE_SPEC_REGEX ||
           change.path =~ JSX_SPEC_REGEX)
      end
    end

    NEED_JSX_SPECS_REGEX = /app\/jsx\/.*\.jsx/
    def needs_jsx_specs?
      changes.any? do |change|
        !change.deleted? &&
          change.path =~ NEED_JSX_SPECS_REGEX
      end
    end

    def jsx_specs?
      changes.any? do |change|
        !change.deleted? &&
          change.path =~ JSX_SPEC_REGEX
      end
    end

    NEED_RUBY_SPECS_REGEX = /(app|lib)\/.*\.rb$/
    def needs_ruby_specs?
      changes.any? do |change|
        !change.deleted? &&
          change.path =~ NEED_RUBY_SPECS_REGEX
      end
    end

    RUBY_SPEC_REGEX = /(spec|spec_canvas|test)\/.*\.rb$/
    SELENIUM_SPEC_REGEX = /(spec|spec_canvas|test)\/selenium\//
    def ruby_specs?
      changes.any? do |change|
        !change.deleted? &&
          change.path =~ RUBY_SPEC_REGEX &&
          change.path !~ SELENIUM_SPEC_REGEX
      end
    end

    def selenium_specs?
      changes.any? do |change|
        !change.deleted? &&
          change.path =~ SELENIUM_SPEC_REGEX
      end
    end

    def changes
      @changes ||= git.changes
    end
  end
end
