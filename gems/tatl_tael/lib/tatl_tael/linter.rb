require_relative 'git_proxy'
require 'forwardable'

module TatlTael
  class Linter
    extend ::Forwardable

    attr_reader :git
    private :git
    def_delegator :git, :wip?

    attr_reader :git_dir
    private :git_dir

    def initialize(git_dir: ".", git: nil)
      @git_dir = git_dir
      @git = git || TatlTael::GitProxy.new(git_dir)
    end

    def ban_new_erb
      yield if new_erb?
    end

    def ensure_specs
      yield if needs_specs? && !spec_changes?
    end

    private

    ERB_REGEX = /\.erb$/
    def new_erb?
      changes.any? do |change|
        change.path =~ ERB_REGEX &&
          change.added?
      end
    end

    NEED_SPECS_REGEX = /(app|lib|public)\/.*\.(coffee|js|jsx|html|erb|rb)$/
    EXCLUDED_SUB_DIR_REGEX = /(bower|mediaelement|shims|vendor)\//
    def needs_specs?
      changes.any? do |change|
        change.path =~ NEED_SPECS_REGEX &&
          change.path !~ EXCLUDED_SUB_DIR_REGEX &&
          !change.deleted?
      end
    end

    SPEC_REGEX = /\/(spec|spec_canvas|test)\//
    def spec_changes?
      changes.any? do |change|
        change.path =~ SPEC_REGEX &&
          !change.deleted?
      end
    end

    def changes
      @changes ||= git.changes
    end
  end
end
