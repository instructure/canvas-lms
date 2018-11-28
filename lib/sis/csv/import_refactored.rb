#
# Copyright (C) 2011 - present Instructure, Inc.
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
#

require 'action_controller_test_process'
require 'csv'
require 'zip'

module SIS
  module CSV
    class ImportRefactored

      attr_accessor :root_account, :batch, :finished, :counts,
        :override_sis_stickiness, :add_sis_stickiness, :clear_sis_stickiness, :logger

      IGNORE_FILES = /__macosx|desktop d[bf]|\A\..*/i

      # The order of this array is important:
      #  * Account must be imported before Term and Course
      #  * Course must be imported before Section
      #  * Course and Section must be imported before Xlist
      #  * Course, Section, and User must be imported before Enrollment
      IMPORTERS = %i{change_sis_id account term abstract_course course section
                     xlist user enrollment admin group_category group group_membership
                     grade_publishing_results user_observer}.freeze

      HEADERS_TO_EXCLUDE_FOR_DOWNLOAD = %w{password ssha_password}.freeze

      def initialize(root_account, opts = {})
        opts = opts.with_indifferent_access
        @root_account = root_account

        @csvs = {}
        IMPORTERS.each { |importer| @csvs[importer] = [] }
        @rows = {}
        IMPORTERS.each { |importer| @rows[importer] = 0 }
        @headers = {}
        IMPORTERS.each { |importer| @headers[importer] = Set.new }

        @files = opts[:files] || []
        @batch = opts[:batch]
        @logger = opts[:logger]
        @override_sis_stickiness = opts[:override_sis_stickiness]
        @add_sis_stickiness = opts[:add_sis_stickiness]
        @clear_sis_stickiness = opts[:clear_sis_stickiness]

        @total_rows = 1
        @current_row = 0
        @current_row_for_pause_vars = 0

        @progress_multiplier = opts[:progress_multiplier] || 1
        @progress_offset = opts[:progress_offset] || 0

        @pending = false
        @finished = false

        settings = PluginSetting.settings_for_plugin('sis_import')
        parallel = Setting.get("sis_parallel_import/#{@root_account.global_id}_num_strands", nil).presence || "1"
        if settings.dig(:parallelism).to_i > 1 && settings[:parallelism] != parallel
          Setting.set("sis_parallel_import/#{@root_account.global_id}_num_strands", settings[:parallelism])
        end
        @rows_for_parallel = nil
        update_pause_vars
        sleep(@pause_duration)
      end

      def self.process(root_account, opts = {})
        importer = self.new(root_account, opts)
        importer.process
        importer
      end

      def prepare
        @tmp_dirs = []
        @batch.data[:downloadable_attachment_ids] ||= []
        @files.each do |file|
          if File.file?(file)
            if File.extname(file).downcase == '.zip'
              tmp_dir = Dir.mktmpdir
              @tmp_dirs << tmp_dir
              CanvasUnzip::extract_archive(file, tmp_dir)
              Dir[File.join(tmp_dir, "**/**")].each do |fn|
                next if File.directory?(fn) || !!(fn =~ IGNORE_FILES)
                file_name = fn[tmp_dir.size+1 .. -1]
                att = create_batch_attachment(File.join(tmp_dir, file_name))
                process_file(tmp_dir, file_name, att)
              end
            elsif File.extname(file).downcase == '.csv'
              att = @batch.attachment if @batch.attachment && File.extname(@batch.attachment.filename).downcase == '.csv'
              att ||= create_batch_attachment file
              process_file(File.dirname(file), File.basename(file), att)
            end
          end
        end
        remove_instance_variable(:@files)

        @parallel_importers = {}
        # first run is just to get the total number of lines to determine how
        # many jobs to create
        number_of_rows(create_importers: false)
        @rows_for_parallel = SisBatch.rows_for_parallel(@total_rows)
        # second run actually creates the jobs now that we have @total_rows and
        # @rows_for_parallel
        number_of_rows(create_importers: true)

        @csvs
      end

      def number_of_rows(create_importers:)
        IMPORTERS.each do |importer|
          @csvs[importer].reject! do |csv|
            begin
              rows = count_rows(csv, importer, create_importers: create_importers)
              unless create_importers
                @rows[importer] += rows
                @total_rows += rows
              end
              false
            rescue ::CSV::MalformedCSVError
              SisBatch.add_error(csv, I18n.t("Malformed CSV"), sis_batch: @batch, failure: true)
              true
            end
          end
        end
      end

      def count_rows(csv, importer, create_importers:)
        rows = 0
        ::CSV.open(csv[:fullpath], "rb", CSVBaseImporter::PARSE_ARGS) do |faster_csv|
          while faster_csv.shift
            if create_importers && rows % @rows_for_parallel == 0
              @parallel_importers[importer] ||= []
              @parallel_importers[importer] << create_parallel_importer(csv, importer, rows)
            end
            rows += 1
          end
        end
        rows
      end

      def create_parallel_importer(csv, importer, rows)
        @batch.parallel_importers.create!(workflow_state: 'pending',
                                          importer_type: importer.to_s,
                                          attachment: csv[:attachment],
                                          index: rows,
                                          batch_size: @rows_for_parallel)
      end

      def create_batch_attachment(path)
        return if File.stat(path).size == 0
        data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
        SisBatch.create_data_attachment(@batch, data, File.basename(path))
      end

      def process
        prepare

        @batch.data[:supplied_batches] = []
        @batch.data[:counts] ||= {}
        IMPORTERS.each do |importer|
          @batch.data[:supplied_batches] << importer if @csvs[importer].present?
          @batch.data[:counts][importer.to_s.pluralize.to_sym] = 0
        end
        @run_immediately = @total_rows <= Setting.get('sis_batch_parallelism_count_threshold', '50').to_i
        @batch.data[:running_immediately] = @run_immediately

        @batch.data[:completed_importers] = []
        @batch.save! unless @run_immediately # we're about to finish anyway

        if @run_immediately
          run_all_importers
        else
          @parallel_importers = Hash[@parallel_importers.map{|k, v| [k, v.map(&:id)]}] # save as ids in handler
          remove_instance_variable(:@csvs) # don't need anymore
          queue_next_importer_set
        end
      rescue => e
        fail_with_error!(e)
      ensure
        @tmp_dirs.each do |tmp_dir|
          FileUtils.rm_rf(tmp_dir, :secure => true) if File.directory?(tmp_dir)
        end
      end

      def errors
        @root_account.sis_batch_errors.where(sis_batch: @batch).order(:id).pluck(:file, :message)
      end

      def calculate_progress
        (((@current_row.to_f/@total_rows) * @progress_multiplier) + @progress_offset) * 100
      end

      def update_progress
        completed_count = @batch.parallel_importers.where(workflow_state: "completed").count
        current_progress = (completed_count.to_f * 100 / @parallel_importers.values.map(&:count).sum).round
        SisBatch.where(:id => @batch).where("progress IS NULL or progress < ?", current_progress).update_all(progress: current_progress)
      end

      def run_parallel_importer(id, csv: nil)
        parallel_importer = id.is_a?(ParallelImporter) ? id : ParallelImporter.find(id)
        if should_stop_import?
          parallel_importer.abort
          return
        end
        importer_type = parallel_importer.importer_type.to_sym
        importer_object = SIS::CSV.const_get(importer_type.to_s.camelcase + 'Importer').new(self)
        csv ||= begin
          att = parallel_importer.attachment
          file = att.open
          parallel_importer.start
          {:fullpath => file.path, :file => att.display_name}
        end
        count = importer_object.process(csv, parallel_importer.index, parallel_importer.batch_size)
        parallel_importer.complete(rows_processed: count)
        update_progress unless @run_immediately # just update progress on completion - the parallel jobs should be short enough
      rescue => e
        if parallel_importer.workflow_state != 'retry'
          parallel_importer.write_attribute(:workflow_state, 'retry')
          run_parallel_importer(parallel_importer)
        end
        parallel_importer.fail
        fail_with_error!(e, filename: parallel_importer.attachment.display_name)
      ensure
        file&.close
        unless @run_immediately
          if is_last_parallel_importer_of_type?(parallel_importer)
            queue_next_importer_set unless should_stop_import?
          end
        end
      end

      def fail_with_error!(e, filename: nil)
        return @batch if @batch.workflow_state == 'aborted'
        message = "Importing CSV for account: "\
            "#{@root_account.id} (#{@root_account.name}) sis_batch_id: #{@batch.id}: #{e}"
        err_id = Canvas::Errors.capture(e, {
          type: :sis_import,
          message: message,
          during_tests: false
        })[:error_report]
        error_message = I18n.t("Error while importing CSV. Please contact support. "\
                                 "(Error report %{number})", number: err_id.to_s)
        @batch.shard.activate do
          SisBatch.add_error(filename, error_message, sis_batch: @batch, failure: true, backtrace: e.try(:backtrace))
          @batch.workflow_state = :failed_with_messages
          @batch.finish(false)
          @batch.save!
        end
      end

      def should_stop_import?
        %w{aborted failed failed_with_messages}.include?(@batch.workflow_state)
      end

      def run_all_importers
        IMPORTERS.each do |importer_type|
          importers = @parallel_importers[importer_type]
          next unless importers
          importers.each do |pi|
            run_parallel_importer(pi, csv: @csvs[importer_type].detect{|csv| csv[:attachment] == pi.attachment})
            @batch.data[:completed_importers] << importer_type
            return false if should_stop_import?
          end
        end
        @parallel_importers.each do |type, importers|
          @batch.data[:counts][type.to_s.pluralize.to_sym] = importers.map(&:rows_processed).sum
        end
        finish
      end

      def queue_next_importer_set
        next_importer_type = IMPORTERS.detect{|i| !@batch.data[:completed_importers].include?(i) && @parallel_importers[i].present?}
        return finish unless next_importer_type

        enqueue_args = { :priority => Delayed::LOW_PRIORITY, :on_permanent_failure => :fail_with_error!, :max_attempts => 5}
        if next_importer_type == :account
          enqueue_args[:strand] = "sis_account_import:#{@root_account.global_id}" # run one at a time
        else
          enqueue_args[:n_strand] = ["sis_parallel_import", @batch.data[:strand_account_id] || @root_account.global_id]
        end

        importers_to_queue = @parallel_importers[next_importer_type]
        updated_count = @batch.parallel_importers.where(:id => importers_to_queue, :workflow_state => "pending").
          update_all(:workflow_state => "queued")
        if updated_count != importers_to_queue.count
          raise "state mismatch error queuing parallel import jobs"
        end
        importers_to_queue.each do |pi|
          self.send_later_enqueue_args(:run_parallel_importer, enqueue_args, pi)
        end
      end

      def is_last_parallel_importer_of_type?(parallel_importer)
        importer_type = parallel_importer.importer_type.to_sym
        return false if @batch.parallel_importers.where(:importer_type => importer_type, :workflow_state => %w{queued running retry}).exists?

        SisBatch.transaction do
          @batch.reload(:lock => true)
          if !@batch.data[:completed_importers].include?(importer_type) # check for race condition
            @batch.data[:completed_importers] << importer_type
            @batch.data[:counts][importer_type.to_s.pluralize.to_sym] = @batch.parallel_importers.where(:importer_type => importer_type).sum(:rows_processed).to_i
            @batch.save
            true
          else
            false
          end
        end
      end

      def finish
        @batch.finish(true)
        @finished = true
      end

      def update_pause_vars
        # throttling can be set on individual SisBatch instances, and also
        # site-wide in the Setting table.
        @batch.data ||= {}
        @pause_duration = (@batch.data[:pause_duration] || Setting.get('sis_batch_pause_duration', 0)).to_f
      end

      def process_file(base, file, att)
        csv = {base: base, file: file, fullpath: File.join(base, file), attachment: att}
        if File.file?(csv[:fullpath]) && File.extname(csv[:fullpath]).downcase == '.csv'
          unless valid_utf8?(csv[:fullpath])
            SisBatch.add_error(csv, I18n.t("Invalid UTF-8"), sis_batch: @batch, failure: true)
            return
          end
          begin
            ::CSV.foreach(csv[:fullpath], CSVBaseImporter::PARSE_ARGS.merge(:headers => false)) do |row|
              row.each(&:downcase!)
              importer = IMPORTERS.index do |type|
                if SIS::CSV.const_get(type.to_s.camelcase + 'Importer').send(type.to_s + '_csv?', row)
                  if type == :user && (row & HEADERS_TO_EXCLUDE_FOR_DOWNLOAD).any?
                    filtered_att = create_filtered_csv(csv, row)
                    @batch.data[:downloadable_attachment_ids] << filtered_att.id if filtered_att
                  else
                    @batch.data[:downloadable_attachment_ids] << att.id
                  end
                  @csvs[type] << csv
                  @headers[type].merge(row)
                  true
                else
                  false
                end
              end
              SisBatch.add_error(csv, I18n.t("Couldn't find Canvas CSV import headers"), sis_batch: @batch, failure: true) if importer.nil?
              break
            end
          rescue ::CSV::MalformedCSVError
            SisBatch.add_error(csv, "Malformed CSV", sis_batch: @batch, failure: true)
          end
        elsif !File.directory?(csv[:fullpath]) && (csv[:fullpath] !~ IGNORE_FILES)
          SisBatch.add_error(csv, I18n.t("Skipping unknown file type"), sis_batch: @batch)
        end
      end

      def valid_utf8?(path)
        # validate UTF-8
        Iconv.open('UTF-8', 'UTF-8') do |iconv|
          File.open(path) do |file|
            chunk = file.read(4096)
            error_count = 0

            while chunk
              begin
                iconv.iconv(chunk)
              rescue Iconv::Failure
                error_count += 1
                if !file.eof? && error_count <= 4
                  # we may have split a utf-8 character in the chunk - try to resolve it, but only to a point
                  chunk << file.read(1)
                  next
                else
                  raise
                end
              end

              error_count = 0
              chunk = file.read(4096)
            end
            iconv.iconv(nil)
          end
        end
        true
      rescue Iconv::Failure
        false
      end

      def create_filtered_csv(csv, headers)
        Dir.mktmpdir do |tmp_dir|
          path = File.join(tmp_dir, File.basename(csv[:fullpath]).sub(/\.csv$/i, "_filtered.csv"))
          new_csv = ::CSV.open(path, 'wb', headers: headers - HEADERS_TO_EXCLUDE_FOR_DOWNLOAD, write_headers: true)
          ::CSV.foreach(csv[:fullpath], CSVBaseImporter::PARSE_ARGS) do |row|
            HEADERS_TO_EXCLUDE_FOR_DOWNLOAD.each do |header|
              row.delete(header)
            end
            new_csv << row
          end
          new_csv.close
          create_batch_attachment(path)
        end
      end
    end
  end
end
