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

require "yaml"
require "fileutils"
require "open3"
require "English"
require_relative "./docker_utils"

Thread.abort_on_exception = true

ENV["RAILS_ENV"] = "test"
DEFAULT_COMPOSE_PROJECT_NAME = "canvas"
ENV["COMPOSE_PROJECT_NAME"] ||= DEFAULT_COMPOSE_PROJECT_NAME
ENV["PGVERSION"] ||= "9.5"
ENV["BASE_DOCKER_VOLUME_ARCHIVE"] ||= ""
# max of any build type
ENV["MASTER_RUNNERS"] = "6" if ENV["PUBLISH_DOCKER_ARTIFACTS"]
ENV["PREPARE_TEST_DATABASE"] ||= "1"

DOCKER_CACHE_S3_BUCKET = ENV.fetch("DOCKER_CACHE_S3_BUCKET")
DOCKER_CACHE_S3_REGION = ENV.fetch("DOCKER_CACHE_S3_REGION")

if ENV["VERBOSE"] != "1"
  $stderr = STDERR.clone
  STDOUT.reopen "/dev/null"
  STDERR.reopen "/dev/null"
end

ENV['RCE_API_PORT'] ||= '3000'

class DockerComposer
  class << self
    # :cry: not the same as canvas docker-compose ... yet
    RUNNER_IDS = Array.new(ENV['MASTER_RUNNERS'].to_i) { |i| i == 0 ? "" : i + 1 }
    COMPOSE_FILES = %w[docker-compose.yml docker-compose.override.yml docker-compose.jenkins.yml]

    def run
      nuke_old_crap
      pull_cached_images
      launch_services
      migrate if run_migrations?
      push_artifacts if push_artifacts?

      dump_structure if ENV["DUMP_STRUCTURE"]
    ensure
      nuke_old_crap if ENV["COMPOSE_PROJECT_NAME"] != DEFAULT_COMPOSE_PROJECT_NAME
    end

    def nuke_old_crap
      docker_compose "kill"
      docker_compose "rm -fv"
      docker "volume rm $(docker volume ls -q | grep #{ENV["COMPOSE_PROJECT_NAME"]}_) || :"
    end

    def pull_cached_images
      return if File.exist?("/tmp/.canvas_pulled_built_images")
      pull_simple_images
      pull_built_images
      FileUtils.touch "/tmp/.canvas_pulled_built_images"
    end

    def pull_simple_images
      puts "Pulling simple images..."
      simple_services.each do |key|
        docker "pull #{service_config(key)["image"]}"
      end
    end

    # port of dockerBase image caching
    def pull_built_images
      puts "Pulling built images..."
      built_services.each do |key|
        path = "s3://#{DOCKER_CACHE_S3_BUCKET}/canvas-lms/canvas_#{key}-ci.tar"
        system "aws s3 cp --only-show-errors --region #{DOCKER_CACHE_S3_REGION} #{path} - | docker load || :"
      end
    end

    # port of dockerBase image caching
    def push_built_images
      puts "Pushing built images..."
      built_services.each do |key|
        name = "canvas_#{key}"
        path = "s3://#{DOCKER_CACHE_S3_BUCKET}/canvas-lms/canvas_#{key}-ci.tar"
        system "docker save #{name} $(docker history -q #{name} | grep -v missing) | aws s3 cp --only-show-errors --region #{DOCKER_CACHE_S3_REGION} - #{path}"
      end
    end

    # e.g. postgres
    def built_services
      services.select { |key| service_config(key)["build"] }
    end

    # e.g. redis
    def simple_services
      services - built_services
    end

    def launch_services
      docker_compose "build #{services.join(" ")}"
      prepare_volumes
      start_services
      update_postgis
      db_prepare unless using_snapshot? # already set up, just need to migrate
    end

    def dump_structure
      dump_file = "/tmp/#{ENV["COMPOSE_PROJECT_NAME"]}_structure.sql"
      File.delete dump_file if File.exist?(dump_file)
      FileUtils.touch dump_file
      docker "exec -i #{ENV["COMPOSE_PROJECT_NAME"]}_postgres_1 pg_dump -s -x -O -U postgres -n public -T 'quiz_submission_events_*' canvas_test_ > #{dump_file}"
    end

    # data_loader will fetch postgres + cassandra volumes from s3, if
    # there are any (BASE_DOCKER_VOLUME_ARCHIVE), so that the db is all
    # migrated and ready to go
    def prepare_volumes
      docker_compose_up "data_loader"
      wait_for "data_loader"
    end

    # To prevent errors similar to: OperationalError: could not access file "$libdir/postgis-X.X
    # These happen when your docker image expects one version of PostGIS but the volume has a different one.  This
    # should noop if there's no mismatch in the version of PostGIS
    # https://hub.docker.com/r/mdillon/postgis/
    def update_postgis
      puts "Updating PostGIS"
      docker "exec --user postgres #{ENV["COMPOSE_PROJECT_NAME"]}_postgres_1 update-postgis.sh"
    end

    def db_prepare
      # pg db setup happens in create-dbs.sh (when we docker-compose up),
      # but cassandra doesn't have a similar hook
      cassandra_setup
    end

    def cassandra_setup
      puts "Creating keyspaces..."
      docker "exec -i #{ENV["COMPOSE_PROJECT_NAME"]}_cassandra_1 /create-keyspaces #{cassandra_keyspaces.join(" ")}"
    end

    def cassandra_keyspaces
      YAML.load_file("config/cassandra.yml")["test"].keys
    end

    # each service can define its own /wait-for-it
    def wait_for(service)
      docker "exec -i #{ENV["COMPOSE_PROJECT_NAME"]}_#{service}_1 sh -c \"[ ! -x /wait-for-it ] || /wait-for-it\""
    end

    def docker_compose_up(services = self.services.join(" "))
      docker_compose "up -d #{services} && docker ps"
    end

    def wait_for_services
      parallel_each(services) { |service| wait_for service }
    end

    def stop_services
      docker_compose "stop #{(services - ["data_loader"]).join(" ")} && docker ps"
    end

    def start_services
      puts "Starting all services..."
      docker_compose_up
      wait_for_services
    end

    def migrate
      puts "Running migrations..."

      tasks = []
      tasks << "ci:disable_structure_dump"
      tasks << "db:migrate:predeploy"
      tasks << "db:migrate"
      tasks << "ci:prepare_test_shards" if ENV["PREPARE_TEST_DATABASE"] == "1"
      tasks << "canvas:quizzes:create_event_partitions"
      tasks << "ci:reset_database" if ENV["PREPARE_TEST_DATABASE"] == "1"
      tasks = tasks.join(" ")

      parallel_each(RUNNER_IDS) do |runner_id|
        result = `TEST_ENV_NUMBER=#{runner_id} bundle exec rake #{tasks} 2>&1`
        if $CHILD_STATUS != 0
          $stderr.puts "ERROR: Migrations failed!\n\nLast 1000 lines:"
          $stderr.puts result.lines.last(1000).join
          exit(1)
        end
      end
    end

    # push the docker volume archives for the worker nodes, and possibly
    # also push the built images and the path to the volume archives if
    # this is a post-merge build
    def push_artifacts
      puts "Pushing artifacts..."
      stop_services # shut it down cleanly before we commit
      archive_path = ENV["PUSH_DOCKER_VOLUME_ARCHIVE"]
      publish_vars_path = "s3://#{DOCKER_CACHE_S3_BUCKET}/canvas-lms/docker_vars/#{ENV["PGVERSION"]}/" + `git rev-parse HEAD` if publish_artifacts?
      docker "exec -i #{ENV["COMPOSE_PROJECT_NAME"]}_data_loader_1 /push-volumes #{archive_path} #{publish_vars_path}"
      push_built_images if publish_artifacts?
      start_services
    end

    # opt-in by default, worker nodes explicitly opt out (since we'll have
    # just done it on the master)
    def run_migrations?
      ENV["RUN_MIGRATIONS"] != "0"
    end

    # master does this so slave will be fast
    def push_artifacts?
      ENV["PUSH_DOCKER_VOLUME_ARCHIVE"]
    end

    # post-merge only
    def publish_artifacts?
      ENV["PUBLISH_DOCKER_ARTIFACTS"]
    end

    def using_snapshot?
      !ENV["BASE_DOCKER_VOLUME_ARCHIVE"].empty?
    end

    def parallel_each(items)
      items.map { |item| Thread.new { yield item } }.map(&:join)
    end

    def docker(args)
      out, err, status = Open3.capture3("docker #{args}")
      puts out
      if !status.success?
        $stderr.puts err
        raise("`docker #{args}` failed")
      end
    end

    def docker_compose(args)
      file_args = COMPOSE_FILES.map { |f| "-f #{f}" }.join(" ")
      out, err, status = Open3.capture3("docker-compose #{file_args} #{args}")
      puts out
      if !status.success?
        $stderr.puts err
        raise("`docker-compose #{file_args} #{args}` failed")
      end
    end

    def service_config(key)
      config["services"][key]
    end

    def services
      own_config["services"].keys
    end

    def own_config
      @own_config ||= DockerUtils.compose_config(COMPOSE_FILES.last)
    end

    def config
      @config ||= DockerUtils.compose_config(*COMPOSE_FILES)
    end
  end
end

begin
  DockerComposer.run if __FILE__ == $0
rescue
  $stderr.puts "ERROR: #{$ERROR_INFO}"
  exit 1
end
