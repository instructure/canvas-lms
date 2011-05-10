#
# Copyright (C) 2011 Instructure, Inc.
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

require 'faster_csv'
require 'zip/zip'

module SIS
  class SisCsv
    attr_accessor :verify, :root_account, :batch, :errors, :warnings, :finished, :counts
    
    IGNORE_FILES = /__macosx|desktop d[bf]|\A\..*/i

    # The order of this array is important:
    #  * Account must be imported before Term and Course
    #  * Course must be imported before Section
    #  * Course and Section must be imported before Xlist
    #  * Course, Section, and User must be imported before Enrollment
    IMPORTERS = [:account, :term, :course, :section, :xlist, :user, :enrollment, :grade_publishing_results]
    
    def initialize(root_account, opts = {})
      opts = opts.with_indifferent_access
      @root_account = root_account

      @csvs = {}
      IMPORTERS.each { |importer| @csvs[importer] = [] }
      
      @files = opts[:files] || []
      @batch = opts[:batch]
      @logger = opts[:logger]
      @counts = {}
      IMPORTERS.each { |importer| @counts[importer.to_s.pluralize.to_sym] = 0 }

      @total_rows = 1
      @current_row = 0
      
      @progress_multiplier = opts[:progress_multiplier] || 1
      @progress_offset = opts[:progress_offset] || 0
      
      @errors = []
      @warnings = []
      
      @finished = false
      
      @allow_printing = opts[:allow_printing].nil? ? true : opts[:allow_printing]
      update_pause_vars
    end
    
    def self.process(root_account, opts = {})
      importer = SisCsv.new(root_account, opts)
      importer.process
      importer
    end
    
    def process
      @tmp_dirs = []
      @files.each do |file|
        if File.file?(file)
          if File.extname(file).downcase == '.zip'
            tmp_dir = Dir.mktmpdir
            @tmp_dirs << tmp_dir
            unzip_file(file, tmp_dir)
            Dir[File.join(tmp_dir, "**/**")].each do |fn|
              process_file(tmp_dir, fn[tmp_dir.size+1 .. -1])
            end
          elsif File.extname(file).downcase == '.csv'
            process_file(File.dirname(file), File.basename(file))
          end
        end
      end

      @csvs.values.flatten.each do |csv|
        @total_rows += (%x{wc -l '#{csv[:fullpath]}'}.split.first.to_i rescue 0)
      end
      
      @verify = {}

      importers = {}
      IMPORTERS.each do |importer|
        importers[importer] = SIS.const_get(importer.to_s.camelcase + 'Importer').new(self)
        @csvs[importer].each { |csv| importers[importer].verify(csv, @verify) }
        @verify[:user_rows] = nil if importer == :user
      end

      @verify = nil
      return unless @errors.empty?

      IMPORTERS.each do |importer|
        @csvs[importer].each {|csv| importers[importer].process(csv) }
      end

      @finished = true
    rescue => e
      if @batch
        error_report = ErrorReport.create(
          :backtrace => e.backtrace,
          :message => "Importing CSV for account: #{@root_account.id} (#{@root_account.name}) sis_batch_id: #{@batch.id if @batch}: #{e.to_s}",
          :during_tests => false
        )
        add_error(nil, "Error while importing CSV. Please contact support. (Error report #{error_report.id})")
      else
        add_error(nil, "#{e.message}\n#{e.backtrace.join "\n"}")
        raise e
      end
    ensure
      @tmp_dirs.each do |tmp_dir|
        FileUtils.rm_rf(tmp_dir, :secure => true) if File.directory?(tmp_dir)
      end
      
      if @batch
        @batch.data[:counts] = @counts
        @batch.processing_errors = @errors
        @batch.processing_warnings = @warnings
        @batch.save
      end
      
      if @allow_printing and !@errors.empty? and !@batch
        # If there's no batch, then we must be working via the console and we should just error out
        @errors.each { |w| puts w.join ": " }
      end
    end
    
    def logger
      @logger ||= Rails.logger
    end
    
    def add_error(csv, message)
      @errors << [ csv ? csv[:file] : "", message ]
    end
    
    def add_warning(csv, message)
      @warnings << [ csv ? csv[:file] : "", message ]
    end
    
    def update_progress
      @current_row += 1
      return unless @batch

      @batch.fast_update_progress( (((@current_row.to_f/@total_rows) * @progress_multiplier) + @progress_offset) * 100) if @current_row % 10 == 0

      if @current_row.to_i % @pause_every == 0
        sleep(@pause_duration)
        update_pause_vars
      end
    end
    
    private

    def update_pause_vars
      return unless @batch

      # throttling can be set on individual SisBatch instances, and also
      # site-wide in the Setting table.
      @batch.reload(:select => 'data') # update to catch changes to pause vars
      @pause_every = (@batch.data[:pause_every] || Setting.get('sis_batch_pause_every', 50)).to_i
      @pause_duration = (@batch.data[:pause_duration] || Setting.get('sis_batch_pause_duration', 1)).to_f
    end
    
    def unzip_file(file, dest)
      Zip::ZipFile.open(file) do |zip_file|
        zip_file.each do |f|
          f_path = File.join(dest, f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) unless File.exist?(f_path)
        end
      end
    end
    
    def process_file(base, file)
      csv = { :base => base, :file => file, :fullpath => File.join(base, file) }
      if File.file?(csv[:fullpath]) && File.extname(csv[:fullpath]).downcase == '.csv'
        FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
          importer = IMPORTERS.index do |importer|
            if SIS.const_get(importer.to_s.camelcase + 'Importer').send('is_' + importer.to_s + '_csv?', row)
              @csvs[importer] << csv
              true
            else
              false
            end
          end
          add_error(csv, "Couldn't find Canvas CSV import headers") if importer.nil?
          break
        end
      elsif !File.directory?(csv[:fullpath]) && !(csv[:fullpath] =~ IGNORE_FILES)
        add_warning(csv, "Skipping unknown file type")
      end
    end
  end
end
