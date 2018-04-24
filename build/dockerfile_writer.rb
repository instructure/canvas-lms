#!/usr/bin/env ruby
#
# Copyright (C) 2017 - present Instructure, Inc.
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

require "erubi"
require_relative "./docker_utils"

class DockerfileWriter
  attr_reader :env, :compose_files

  def initialize(env:, compose_files:)
    @env = env
    @compose_files = compose_files
  end

  def production?
    env == "production"
  end

  def development?
    env == "development"
  end

  def generation_message
    <<~STR
      # GENERATED FILE, DO NOT MODIFY!
      # To update this file please edit the relevant template and run the generation
      # task `build/dockerfile_writer.rb`
    STR
  end

  def run(filename)
    File.open(filename, "w") do |f|
      f.write eval(Erubi::Engine.new(File.read("build/Dockerfile.template")).src, nil, "build/Dockerfile.template")
    end
  end

  def docker_compose_volume_paths
    paths = (docker_compose_config["services"]["web"]["volumes"] || []).map do |volume|
      name, path = volume.split(":")
      next unless name =~ /\A[a-z]/
      path.sub("/usr/src/app/", "")
    end.compact
    paths.sort_by { |path| [path[0] == "/" ? 1 : 0, path]}
  end

  def docker_compose_config
    DockerUtils.compose_config(*compose_files)
  end
end

DockerfileWriter.new(
  env: "development",
  compose_files: ["docker-compose.yml", "docker-compose.override.yml"]
).run("Dockerfile")

DockerfileWriter.new(
  env: "production",
  compose_files: ["docker-compose.yml"]
).run("Dockerfile-production")
