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
    class Import

      attr_accessor :root_account, :batch, :finished, :counts, :updates_every,
        :override_sis_stickiness, :add_sis_stickiness, :clear_sis_stickiness

      IGNORE_FILES = /__macosx|desktop d[bf]|\A\..*/i

      # The order of this array is important:
      #  * Account must be imported before Term and Course
      #  * Course must be imported before Section
      #  * Course and Section must be imported before Xlist
      #  * Course, Section, and User must be imported before Enrollment
      IMPORTERS = %i{change_sis_id account term abstract_course course section
                     xlist user enrollment admin group_category group group_membership
                     grade_publishing_results user_observer}.freeze

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
        @counts = {}
        IMPORTERS.each { |importer| @counts[importer.to_s.pluralize.to_sym] = 0 }

        @total_rows = 1
        @current_row = 0
        @current_row_for_pause_vars = 0

        @progress_multiplier = opts[:progress_multiplier] || 1
        @progress_offset = opts[:progress_offset] || 0

        @pending = false
        @finished = false

        settings = PluginSetting.settings_for_plugin('sis_import')

        @allow_printing = opts[:allow_printing].nil? ? true : opts[:allow_printing]
        @parallelism = opts[:parallelism]
        @parallelism ||= settings[:parallelism].to_i
        @parallelism = 1 if @parallelism < 1
        @parallelism = 1 unless @batch
        @minimum_rows_for_parallel = settings[:minimum_rows_for_parallel].to_i
        @minimum_rows_for_parallel = 1000 if @minimum_rows_for_parallel < 1
        @parallel_queue = settings[:queue_for_parallel_jobs]
        @parallel_queue = nil if @parallel_queue.blank?
        update_pause_vars
      end

      def self.process(root_account, opts = {})
        importer = Import.new(root_account, opts)
        importer.process
        importer
      end

      def use_parallel_imports?
        false
      end

      def prepare
        @tmp_dirs = []
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
              att = @batch.attachment
              att ||= create_batch_attachment file
              process_file(File.dirname(file), File.basename(file), att)
            end
          end
        end
        @files = nil

        IMPORTERS.each do |importer|
          @csvs[importer].reject! do |csv|
            begin
              rows = 0
              ::CSV.open(csv[:fullpath], "rb", CSVBaseImporter::PARSE_ARGS) do |faster_csv|
                rows += 1 while faster_csv.shift
              end
              @rows[importer] += rows
              @total_rows += rows
              false
            rescue ::CSV::MalformedCSVError
              SisBatch.add_error(csv, I18n.t("Malformed CSV"), sis_batch: @batch,failure: true)
              true
            end
          end
        end

        @csvs
      end

      def create_batch_attachment(path)
        return if File.stat(path).size == 0
        data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
        SisBatch.create_data_attachment(@batch, data, File.basename(path))
      end

      def process
        prepare

        @parallelism = 1 if @total_rows <= @minimum_rows_for_parallel

        # calculate how often we should update progress to get 1% resolution
        # but don't leave us hanging for more than 500 rows at a time
        # and don't do it more often than we have work to do
        @updates_every = [ [ @total_rows / @parallelism / 100, 500 ].min, 10 ].max

        if @batch
          @batch.data[:supplied_batches] = []
          IMPORTERS.each do |importer|
            @batch.data[:supplied_batches] << importer if @csvs[importer].present?
          end
          @batch.save!
        end

        if (@parallelism > 1)
          # re-balance the CSVs
          @batch.data[:importers] = {}
          IMPORTERS.each do |importer|
            if (importer != :account)
              rebalance_csvs(importer)
            end
            @batch.data[:importers][importer] = @csvs[importer].length
            @batch.data[:counts] = {}
            @batch.data[:current_row] = 0
          end
          @batch.save!
          @rows = nil
          @headers = nil
          run_next_importer(IMPORTERS.first)
          @batch.reload
          while @batch.workflow_state.to_sym == :importing
            sleep(0.5)
            @batch.reload
          end
          @finished = [:imported, :imported_with_messages].include?(@batch.workflow_state.to_sym)
        else
          IMPORTERS.each do |importer|
            importerObject = SIS::CSV.const_get(importer.to_s.camelcase + 'Importer').new(self)
            @csvs[importer].each { |csv| @counts[importer.to_s.pluralize.to_sym] += importerObject.process(csv) }
          end
          @finished = true
        end
      rescue => e
        if @batch
          return @batch if @batch.workflow_state == 'aborted'
          message = "Importing CSV for account"\
            ": #{@root_account.id} (#{@root_account.name}) "\
            "sis_batch_id: #{@batch.id}: #{e}"
          err_id = Canvas::Errors.capture(e,{
            type: :sis_import,
            message: message,
            during_tests: false
          })[:error_report]
          error_message = I18n.t("Error while importing CSV. Please contact support."\
                                 " (Error report %{number})", number: err_id.to_s)
          SisBatch.add_error(nil, error_message, sis_batch: @batch,failure: true)
        else
          SisBatch.add_error(nil, e.to_s, sis_batch: @batch,backtrace: e.backtrace, failure: true)
          raise e
        end
      ensure
        @tmp_dirs.each do |tmp_dir|
          FileUtils.rm_rf(tmp_dir, :secure => true) if File.directory?(tmp_dir)
        end

        if @batch && @parallelism == 1
          @batch.data[:counts] = @counts
          @batch.save
        end
      end

      def logger
        @logger ||= Rails.logger
      end

      def errors
        errors = @root_account.sis_batch_errors
        errors = errors.where(sis_batch: @batch) if @batch
        errors.order(:id).pluck(:file, :message)
      end

      def calculate_progress
        (((@current_row.to_f/@total_rows) * @progress_multiplier) + @progress_offset) * 100
      end

      def update_progress
        @current_row += 1
        @current_row_for_pause_vars += 1
        return unless @batch

        if update_progress?
          if @parallelism > 1
            begin
              SisBatch.transaction do
                @batch.reload(select: 'data, progress, workflow_state', lock: :no_key_update)
                raise SisBatch::Aborted if @batch.workflow_state == 'aborted'
                @current_row += @batch.data[:current_row]
                @batch.data[:current_row] = @current_row
                @batch.progress = [calculate_progress, 99].min
                @batch.save
                @current_row = 0
              end
            rescue ActiveRecord::RecordNotFound
              return
            end
          else
            @batch.fast_update_progress( (((@current_row.to_f/@total_rows) * @progress_multiplier) + @progress_offset) * 100)
          end
          @last_progress_update = Time.now
        end

        if @current_row_for_pause_vars % @pause_every == 0
          sleep(@pause_duration)
          update_pause_vars
        end
      end

      def update_progress?
        @last_progress_update ||= Time.now
        update_interval = Setting.get('sis_batch_progress_interval', 2.seconds).to_i
        @last_progress_update < update_interval.seconds.ago
      end

      def run_single_importer(importer, csv)
        begin
          importerObject = SIS::CSV.const_get(importer.to_s.camelcase + 'Importer').new(self)
          if csv[:attachment]
            file = csv[:attachment].open
            csv[:fullpath] = file.path
          end
          @counts[importer.to_s.pluralize.to_sym] += importerObject.process(csv)
          run_next_importer(IMPORTERS[IMPORTERS.index(importer) + 1]) if complete_importer(importer)
        rescue => e
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
          SisBatch.add_error(nil, error_message, sis_batch: @batch,failure: true, backtrace: e)
          @batch.workflow_state = :failed_with_messages
          @batch.save!
        ensure
          file.close if file
        end
      end

      private

      def run_next_importer(importer)
        return finish if importer.nil? || @batch.workflow_state == 'aborted'
        return run_next_importer(IMPORTERS[IMPORTERS.index(importer) + 1]) if @csvs[importer].empty?
        if (importer == :account)
          @csvs[importer].each { |csv| run_single_importer(importer, csv) }
          return
        end
        # logger doesn't serialize well
        @logger = nil
        enqueue_args = { :priority => Delayed::LOW_PRIORITY }
        enqueue_args[:queue] = @queue if @queue
        @csvs[importer].each { |csv| self.send_later_enqueue_args(:run_single_importer, enqueue_args, importer, csv) }
      end


      def complete_importer(importer)
        return unless @batch
        SisBatch.transaction do
          @batch.reload(:lock => true)
          @batch.data[:importers][importer] -= 1
          @batch.data[:counts] ||= {}
          @counts.each do |k, v|
            @batch.data[:counts][k] ||= 0
            @batch.data[:counts][k] += v
            @counts[k] = 0
          end
          @current_row += @batch.data[:current_row] if @batch.data[:current_row]
          @batch.data[:current_row] = @current_row
          @batch.progress = (((@current_row.to_f/@total_rows) * @progress_multiplier) + @progress_offset) * 100
          @current_row = 0
          @batch.save
          @batch.data[:importers][importer] == 0
        end
      end

      def finish
        @batch.finish(true)
        @finished = true
      end

      def update_pause_vars
        return unless @batch

        # throttling can be set on individual SisBatch instances, and also
        # site-wide in the Setting table.
        @batch.reload(:select => 'data') # update to catch changes to pause vars
        @batch.data ||= {}
        @pause_every = (@batch.data[:pause_every] || Setting.get('sis_batch_pause_every', 100)).to_i
        @pause_duration = (@batch.data[:pause_duration] || Setting.get('sis_batch_pause_duration', 0)).to_f
      end

      def rebalance_csvs(importer)
        rows_per_batch = (@rows[importer].to_f / @parallelism).ceil.to_i
        new_csvs = []
        out_csv = nil
        tmp_dir = Dir.mktmpdir
        @tmp_dirs << tmp_dir
        temp_file = 0
        headers = @headers[importer].to_a
        path = nil
        begin
          Attachment.skip_3rd_party_submits
          @csvs[importer].each do |csv|
            remaining_in_batch = 0
            ::CSV.foreach(csv[:fullpath], CSVBaseImporter::PARSE_ARGS) do |row|
              if remaining_in_batch == 0
                temp_file += 1
                if out_csv
                  out_csv.close
                  out_csv = nil
                  att = Attachment.new
                  att.context = @batch
                  att.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
                  att.display_name = new_csvs.last[:file]
                  att.save!
                  new_csvs.last.delete(:fullpath)
                  new_csvs.last[:attachment] = att
                end
                path = File.join(tmp_dir, "#{importer}#{temp_file}.csv")
                out_csv = ::CSV.open(path, "wb", {:headers => headers, :write_headers => true})
                new_csvs << {:file => csv[:file]}
                remaining_in_batch = rows_per_batch
              end
              out_row = ::CSV::Row.new(headers, []);
              headers.each { |header| out_row[header] = row[header] }
              out_csv << out_row
              remaining_in_batch -= 1
            end
          end
          if out_csv
            out_csv.close
            out_csv = nil
            att = Attachment.new
            att.context = @batch
            att.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
            att.display_name = new_csvs.last[:file]
            att.save!
            new_csvs.last.delete(:fullpath)
            new_csvs.last[:attachment] = att
          end
        ensure
          out_csv.close if out_csv
          Attachment.skip_3rd_party_submits(false)
        end
        @csvs[importer] = new_csvs
      end

      def process_file(base, file, att)
        csv = {base: base, file: file, fullpath: File.join(base, file), attachment: att}
        if File.file?(csv[:fullpath]) && File.extname(csv[:fullpath]).downcase == '.csv'
          unless valid_utf8?(csv[:fullpath])
            SisBatch.add_error(csv, I18n.t("Invalid UTF-8"), sis_batch: @batch,failure: true)
            return
          end
          begin
            ::CSV.foreach(csv[:fullpath], CSVBaseImporter::PARSE_ARGS.merge(:headers => false)) do |row|
              row.each(&:downcase!)
              importer = IMPORTERS.index do |type|
                if SIS::CSV.const_get(type.to_s.camelcase + 'Importer').send(type.to_s + '_csv?', row)
                  @csvs[type] << csv
                  @headers[type].merge(row)
                  true
                else
                  false
                end
              end
              SisBatch.add_error(csv, I18n.t("Couldn't find Canvas CSV import headers"), sis_batch: @batch,failure: true) if importer.nil?
              break
            end
          rescue ::CSV::MalformedCSVError
            SisBatch.add_error(csv, "Malformed CSV", sis_batch: @batch,failure: true)
          end
        elsif !File.directory?(csv[:fullpath]) && !(csv[:fullpath] =~ IGNORE_FILES)
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
    end
  end
end
