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
require "json"
require "optparse"
require_relative "./docker_utils"

class DockerfileWriter
  attr_reader :env, :compose_files, :in_file, :out_file

  def initialize(env:, compose_files:, in_file:, out_file:)
    @env = env
    @compose_files = compose_files
    @in_file = in_file
    @out_file = out_file
  end

  def production?
    env == "production"
  end

  def development?
    env == "development"
  end

  def jenkins?
    env == "jenkins"
  end

  def generation_message
    <<~STR
      # GENERATED FILE, DO NOT MODIFY!
      # To update this file please edit the relevant template and run the generation
      # task `build/dockerfile_writer.rb --env #{env} --compose-file #{compose_files.join(',')} --in #{in_file} --out #{out_file}`
    STR
  end

  def run()
    File.open(out_file, "w") do |f|
      f.write eval(Erubi::Engine.new(File.read(in_file)).src, nil, in_file)
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

  def yarn_packages
    JSON.load(File.open('package.json'))['workspaces']['packages']
  end
end

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: dockerfile_writer.rb [options]"

  opts.on("--env [ENVIRONMENT]", String, "Dockerfile Environment") do |v|
    options[:env] = v
  end

  opts.on("--compose-file x,y,z", Array, "List of compose files") do |v|
    options[:compose_files] = v
  end

  opts.on("--in [FILENAME]", String, "Input Template File") do |v|
    options[:in_file] = v
  end

  opts.on("--out [FILENAME]", String, "Output File") do |v|
    options[:out_file] = v
  end
end.parse!

DockerfileWriter.new(**options).run()
