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
          File.write(prediction_file_path, prediction.to_a.join(","))
          Crystalball.log :info, "Saved RSpec prediction to #{prediction_file_path}"
          exit # rubocop:disable Rails/Exit
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
          file = Pathname.new(ENV.fetch("CRYSTALBALL_CONFIG", "crystalball.yml"))
          file = Pathname.new("config/crystalball.yml") unless file.exist?
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
  end
end

require "crystalball/rspec/runner/configuration"
