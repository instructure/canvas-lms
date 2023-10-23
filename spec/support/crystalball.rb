# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require "rspec/core"
require "crystalball/rspec/prediction_builder"
require "crystalball/rspec/filtering"
require "crystalball/rspec/prediction_pruning"

require "crystalball/predictor/strategy"
require "crystalball/predictor/helpers/affected_example_groups_detector"

module Crystalball
  module RSpec
    # Our custom RSpec runner to generate and save predictions to a file, i.e. "dry-run"
    # TODO: make DryRunner class NOT inherit ::RSpec::Core::Runner because we don"t need it
    class DryRunner < ::RSpec::Core::Runner
      include PredictionPruning

      class << self
        def run(args, err = $stderr, out = $stdout)
          return config["runner_class"].run(args, err, out) unless config["runner_class"] == self

          Crystalball.log :info, "Crystalball starts to glow..."
          prediction = build_prediction
          dry_run(prediction) if args.include?("--dry-run")

          Crystalball.log :debug, "Prediction: #{prediction.first(5).join(" ")}#{"..." if prediction.size > 5}"
          Crystalball.log :info, "Starting RSpec."

          super(args + prediction, err, out)
        end

        def dry_run(prediction)
          prediction_file_path = config["dry_run_output_file_path"]
          # remove leading ./ and trailing brackets [], then uniq
          prediction = prediction.map do |s|
            s.gsub(/\[.*?\]/, "").sub("./", "")
          end.uniq

          if prediction.size > 10
            prediction = compress_prediction(prediction)
          end

          Crystalball.log :info, "Prediction: #{prediction.first(5).join(" ")}#{"..." if prediction.size > 5}"

          File.write(prediction_file_path, prediction.flatten.join(","))
          Crystalball.log :info, "Saved RSpec prediction to #{prediction_file_path}"
          exit # rubocop:disable Rails/Exit
        end

        def compress_prediction(prediction)
          Crystalball.log :info, "Compressing Tests..........."
          # create array of parents
          parents = []
          prediction.flat_map do |name|
            parents << File.dirname(name.to_s)
          end
          # each parent, if all children present, remove children from prediction
          # and add parent to prediction.
          parents.each do |parent|
            actual_files = Dir["#{parent}/*spec.rb"]
            next unless (actual_files - prediction).none?

            prediction -= actual_files
            prediction << "#{parent}/*spec.rb"
          end
          prediction
        end

        def reset!
          self.prediction_builder = nil
          self.config = nil
        end

        def prepare
          config["runner_class"].load_execution_map
        end

        def prediction_builder
          @prediction_builder ||= config["prediction_builder_class"].new(config)
        end

        def config
          @config ||= begin
            config_src = if config_file
                           require "yaml"
                           YAML.safe_load(config_file.read)
                         else
                           {}
                         end

            Crystalball::RSpec::Runner::Configuration.new(config_src)
          end
        end

        protected

        def load_execution_map
          check_map
          prediction_builder.execution_map
        end

        private

        attr_writer :config, :prediction_builder

        def config_file
          file = Pathname.new(ENV.fetch("CRYSTALBALL_CONFIG", "config/crystalball.yml"))
          file.exist? ? file : nil
        end

        def build_prediction
          check_map
          prune_prediction_to_limit(prediction_builder.prediction.sort_by(&:length))
        end

        def check_map
          Crystalball.log :warn, "Maps are outdated!" if prediction_builder.expired_map?
        end
      end

      def setup(err, out)
        configure(err, out)
        @configuration.load_spec_files

        Filtering.remove_unnecessary_filters(@configuration, @options.options[:files_or_directories_to_run])

        if reconfiguration_needed?
          Crystalball.log :warn, "Prediction examples size #{@world.example_count} is over the limit (#{examples_limit})"
          Crystalball.log :warn, "Prediction is pruned to fit the limit!"

          reconfigure_to_limit
          @configuration.load_spec_files
        end

        @world.announce_filters
      end

      # Backward compatibility for RSpec < 3.7
      def configure(err, out)
        @configuration.error_stream = err
        @configuration.output_stream = out if @configuration.output_stream == $stdout
        @options.configure(@configuration)
      end
    end

    class CanvasPredictionBuilder < Crystalball::RSpec::PredictionBuilder
      def predictor
        super do |p|
          p.use Crystalball::Predictor::ModifiedSpecs.new
          p.use Crystalball::Predictor::ModifiedExecutionPaths.new
          p.use Crystalball::Predictor::ChangedFiles.new
        end
      end
    end
  end

  class Predictor
    module Helpers
      module AffectedExampleGroupsDetector
        def detect_examples(files, map)
          # prepend CRYSTALBALL_REPO_PATH to each file in files for plugins
          if ENV["CRYSTALBALL_REPO_PATH"]&.include?("gems/plugins")
            files = files.map do |file|
              if file.include?(ENV["CRYSTALBALL_REPO_PATH"][/gems.+/])
                file
              else
                ENV["CRYSTALBALL_REPO_PATH"][/gems.+/] + file
              end
            end
            Crystalball.log :info, "Modified Plugin Filepath: #{files}"
          end

          map.example_groups.filter_map do |uid, example_group_map|
            uid if files.any? { |file| example_group_map.include?(file) }
          end
        end
      end
    end
  end

  class Predictor
    # Queues a total re-run if any files are added. If no new files, don't add any predictions
    # Possible git operation types for SourceDiff include: ['new', 'modified', 'moved', 'deleted]
    class ChangedFiles
      include Helpers::AffectedExampleGroupsDetector
      include Strategy

      CONFIG_CHANGES = [%r{config/.*.rb$}, %r{config/feature_flags/.*yml}, /Dockerfile/, /Jenkinsfile/, %r{build/new-jenkins/}].freeze
      GEMFILE_CHANGES = [/Gemfile.lock/].freeze
      PLUGINS_GEMFILE_CHANGES = [%r{Gemfile.d/.*.rb}, /.*.gemspec/].freeze
      PACKAGE_CHANGES = [/package.json/, /yarn.lock/].freeze

      # @param [Crystalball::SourceDiff] diff - the diff from which to predict
      #   which specs should run
      # @param [Crystalball::ExampleGroupMap] map - the map with the relations of
      #   examples and used files
      # @return [Array<String>] the spec paths associated with the changes
      def call(diff, map)
        super do
          file_change_types = diff.map { |source_diff| [source_diff.relative_path, source_diff.type] }
          # Create a map of git operations to files
          # Hash["new"] = ["new_file1.rb", "new_file2.rb"]
          # Hash["modified"] = ["modified_file1.rb", "modified_file2.rb"]
          # etc...
          file_changes = file_change_types.each_with_object(Hash.new { |h, k| h[k] = [] }) do |arr, change_map|
            change_path = arr[0]
            change_type = arr[1]
            change_map[change_type] << change_path
          end
          Crystalball.log :warn, "Crystalball changes: #{file_changes.slice("new", "modified")}"
          if ENV["FORCE_CRYSTALBALL"] == "1"
            Crystalball.log :warn, "Crystalball force enabled despite config changes or new files"
            []
          elsif file_changes["new"].count.positive?
            Crystalball.log :warn, "Crystalball detected new .git files: #{file_changes["new"]}"
            Crystalball.log :warn, "Crystalball requesting entire suite re-run"
            ["."]
          elsif file_changes["modified"].find { |path| CONFIG_CHANGES.any? { |config_path| path =~ config_path } }
            Crystalball.log :warn, "Crystalball detected ruby config/ file changes!"
            Crystalball.log :warn, "Crystalball requesting entire suite re-run"
            ["."]
          elsif file_changes["modified"].find { |path| GEMFILE_CHANGES.any? { |gemfile_path| path =~ gemfile_path } }
            Crystalball.log :warn, "Crystalball detected Gemfile.lock changes!"
            Crystalball.log :warn, "Crystalball requesting entire suite re-run"
            ["."]
          elsif file_changes["modified"].find { |path| PACKAGE_CHANGES.any? { |package_path| path =~ package_path } }
            Crystalball.log :warn, "Crystalball detected package.json or yarn.lock changes!"
            Crystalball.log :warn, "Crystalball requesting entire suite re-run"
            ["."]
          elsif ENV["CRYSTALBALL_REPO_PATH"]&.include?("gems/plugins") && file_changes["modified"].find { |path| PLUGINS_GEMFILE_CHANGES.any? { |gemfile_path| path =~ gemfile_path } }
            Crystalball.log :warn, "Crystalball detected Plugin Gemfile/Gemfile.lock changes!"
            Crystalball.log :warn, "Crystalball requesting entire suite re-run"
            ["."]
          else
            []
          end
        end
      end
    end
  end

  # Override prediction mechanism based on ChangedFiles predictor. If we requeue an entire suite re-run
  # ENV["CRYSTALBALL_TEST_SUITE_ROOT"] should point to the root of selenium specs or whatever is deemed
  #  relevant for a "complete crystalball-predicted run"
  class Predictor
    # @return [Crystalball::Prediction] list of examples which may fail
    def prediction
      root_suite_path = ENV["CRYSTALBALL_TEST_SUITE_ROOT"] || "."
      raw_prediction = raw_prediction(diff)
      prediction_list = includes_root?(raw_prediction) ? [root_suite_path] : raw_prediction
      prediction_list = filter_out_specs(prediction_list)
      Prediction.new(filter(prediction_list))
    end

    private

    def filter(example_groups)
      example_groups.compact.select do |example_group|
        # Example_group filepath is realtive to the root of the repo, so we need to chdir to the root
        Dir.chdir("/usr/src/app") do
          if Pathname.new(example_group.split("[").first).exist?
            true
          else
            Crystalball.log :info, "Filepath does not exist, removing from prediction: #{Pathname.new(example_group.split("[").first)}"
            false
          end
        end
      end.uniq
    end

    def includes_root?(prediction_list)
      prediction_list.include?(".") ||
        prediction_list.include?("./.") ||
        prediction_list.include?(ENV["CRYSTALBALL_TEST_SUITE_ROOT"])
    end

    def filter_out_specs(prediction_list)
      prediction_list.reject do |spec|
        if spec =~ %r{gems/.*spec\.rb} && spec !~ %r{gems/plugins/.*/spec_canvas/.*spec\.rb}
          Crystalball.log :info, "Filtering out #{spec}"
          true
        else
          false
        end
      end
    end
  end

  class MapStorage
    # YAML persistence adapter for execution map storage
    class YAMLStorage
      def dump(data)
        path.dirname.mkpath
        # Any keys longer than 128 chars will have a yaml output starting with "? <value>\n:" instead of "<value>:\n", which crystalball doesn't like
        data_dump = if %i[type commit timestamp version].all? { |header| data.key? header }
                      YAML.dump(data)
                    else
                      YAML.dump(data).gsub("? ", "").gsub("\n:", ":\n").gsub("\n  -", "\n-").gsub("\n -", "\n-")
                    end
        path.open("a") { |f| f.write data_dump }
      end
    end
  end

  class MapGenerator
    def start!
      self.map = nil
      configuration.reset_map_storage!
      map_storage.clear!
      map_storage.dump(map.metadata.to_h)

      strategies.reverse.each(&:after_start)
      self.started = true
    end

    class Configuration
      def generate_unique_map_filename
        "log/results/crystalball_results/#{SecureRandom.uuid}_#{ENV.fetch("PARALLEL_INDEX", "0")}_map.yml"
      end

      def reset_map_storage!
        self.map_storage_path = generate_unique_map_filename
        @map_storage = MapStorage::YAMLStorage.new(map_storage_path)
      end
    end
  end
end

require "crystalball/rspec/runner/configuration"
