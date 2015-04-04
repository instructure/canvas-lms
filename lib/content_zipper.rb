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
require 'zip'
require 'action_controller_test_process'
require 'tmpdir'
require 'set'


class ContentZipper

  def initialize(options={})
    @check_user = options.has_key?(:check_user) ? options[:check_user] : true
    @logger = Rails.logger
  end

  # we evaluate some ERB templates from under app/views/ while generating assignment zips
  include I18nUtilities
  def t(*a, &b)
    I18n.t(*a, &b)
  end

  def self.process_attachment(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    ContentZipper.new(options).process_attachment(*args)
  end

  def process_attachment(attachment, user = nil)
    raise "No attachment provided to ContentZipper.process_attachment" unless attachment

    attachment.update_attribute(:workflow_state, 'zipping')
    @user = user
    @logger.debug("file found: #{attachment.id} zipping files...")

    begin
      case attachment.context
      when Assignment; zip_assignment(attachment, attachment.context)
      when Eportfolio; zip_eportfolio(attachment, attachment.context)
      when Folder; zip_base_folder(attachment, attachment.context)
      when Quizzes::Quiz; zip_quiz(attachment, attachment.context)
      end
    rescue => e
      ErrorReport.log_exception(:default, e, {
        :message => "Content zipping failed",
      })
      @logger.debug(e.to_s)
      @logger.debug(e.backtrace.join('\n'))
      attachment.update_attribute(:workflow_state, 'to_be_zipped')
    end
  end

  def assignment_zip_filename(assignment)
    "#{assignment.context.short_name_slug}-#{assignment.title_slug} submissions"
  end

  def zip_assignment(zip_attachment, assignment)
    mark_attachment_as_zipping!(zip_attachment)
    filename = assignment_zip_filename(assignment)

    user = zip_attachment.user
    context = assignment.context

    students = assignment.representatives(user).index_by(&:id)
    submissions = assignment.submissions.where(:user_id => students.keys)

    make_zip_tmpdir(filename) do |zip_name|
      @logger.debug("creating #{zip_name}")
      Zip::File.open(zip_name, Zip::File::CREATE) do |zipfile|
        count = submissions.length
        submissions.each_with_index do |submission, idx|
          @assignment = assignment
          @submission = submission
          @context = assignment.context
          @logger.debug(" checking submission for #{(submission.user.name rescue nil)}")

          # pulling out of this hash to get group names for group assignments
          # and to avoid extra queries
          users_name = students[submission.user_id].sortable_name
          # necessary because we use /_\d+_/ to infer the user/attachment
          # ids when teachers upload graded submissions
          users_name.gsub! /_(\d+)_/, '-\1-'
          users_name.gsub! /^(\d+)$/, '-\1-'

          filename = users_name + (submission.late? ? " LATE_" : "_") + submission.user_id.to_s
          filename = filename.gsub(/ /, "-").gsub(/[^-\w]/, "-").downcase

          content = nil
          if submission.submission_type == "online_upload"
            # NOTE: not using #versioned_attachments or #attachments because
            # they do not include submissions for group assignments for anyone
            # but the original submitter of the group submission
            attachment_ids = submission.attachment_ids.try(:split, ",")
            attachments = attachment_ids ?
                            Attachment.where(id: attachment_ids) :
                            []
            attachments.each do |attachment|
              @logger.debug("  found attachment: #{attachment.display_name}")
              fn = filename + "_" + attachment.id.to_s + "_" + attachment.display_name
              mark_successful! if add_attachment_to_zip(attachment, zipfile, fn)
            end
          elsif submission.submission_type == "online_url" && submission.url
            @logger.debug("  found url: #{submission.url}")
            self.extend(ApplicationHelper)
            filename += "_link.html"
            @logger.debug("  loading template")
            content = File.open(File.join("app", "views", "assignments", "redirect_page.html.erb")).read
            @logger.debug("  parsing template")
            content = ERB.new(content).result(binding)
            @logger.debug("  done parsing template")
            if content
              zipfile.get_output_stream(filename) {|f| f.puts content }
              mark_successful!
            end
          elsif submission.submission_type == "online_text_entry" && submission.body
            @logger.debug("  found text entry")
            self.extend(ApplicationHelper)
            filename += "_text.html"
            content = File.open(File.join("app", "views", "assignments", "text_entry_page.html.erb")).read
            content = ERB.new(content).result(binding)
            if content
              zipfile.get_output_stream(filename) {|f| f.puts content }
              mark_successful!
            end
          end
          update_progress(zip_attachment, idx, count)
        end
      end
      @logger.debug("added #{submissions.size} submissions")
      assignment.increment!(:submissions_downloads)
      complete_attachment!(zip_attachment, zip_name)
    end
  end

  def self.zip_eportfolio(*args)
    ContentZipper.new.zip_eportfolio(*args)
  end

  StaticAttachment = Struct.new(:display_name,
                                :filename,
                                :content_type,
                                :uuid,
                                :attachment)

  def zip_eportfolio(zip_attachment, portfolio)
    static_attachments = []
    submissions = []
    portfolio.eportfolio_entries.each do |entry|
      static_attachments += entry.attachments
      submissions += entry.submissions
    end
    idx = 1
    submissions_hash = {}
    submissions.each do |s|
      submissions_hash[s.id] = s
      if s.submission_type == 'online_upload'
        static_attachments += s.attachments
      else
      end
    end
    static_attachments = static_attachments.uniq.map do |a|
      obj = StaticAttachment.new
      obj.display_name = a.display_name
      obj.filename = "#{idx}_#{a.filename}"
      obj.content_type = a.content_type
      obj.uuid = a.uuid
      obj.attachment = a
      idx += 1
      obj
    end
    filename = portfolio.name
    make_zip_tmpdir(filename) do |zip_name|
      idx = 0
      count = static_attachments.length + 2
      Zip::File.open(zip_name, Zip::File::CREATE) do |zipfile|
        update_progress(zip_attachment, idx, count)
        portfolio.eportfolio_entries.each do |entry|
          filename = "#{entry.full_slug}.html"
          content = render_eportfolio_page_content(entry, portfolio, static_attachments, submissions_hash)
          zipfile.get_output_stream(filename) {|f| f.puts content }
        end
        update_progress(zip_attachment, idx, count)
        static_attachments.each do |a|
          add_attachment_to_zip(a.attachment, zipfile)
          update_progress(zip_attachment, idx, count)
        end
        content = File.open(Rails.root.join('public', 'images', 'logo.png'), 'rb').read rescue nil
        zipfile.get_output_stream("logo.png") {|f| f.write content } if content
      end
      mark_successful!
      complete_attachment!(zip_attachment, zip_name)
    end
  end

  def render_eportfolio_page_content(page, portfolio, static_attachments, submissions_hash)
    @page = page
    @portfolio = @portfolio
    @static_attachments = static_attachments
    @submissions_hash = submissions_hash
    av = ActionView::Base.new()
    av.view_paths = ActionController::Base.view_paths
    av.extend TextHelper
    res = av.render(:partial => "eportfolios/static_page", :locals => {:page => page, :portfolio => portfolio, :static_attachments => static_attachments, :submissions_hash => submissions_hash})
    res
  end

  def self.zip_base_folder(*args)
    ContentZipper.new.zip_base_folder(*args)
  end

  def zip_base_folder(zip_attachment, folder)
    @files_added = true
    @logger.debug("zipping into attachment: #{zip_attachment.id}")
    zip_attachment.workflow_state = 'zipping' #!(:workflow_state => 'zipping')
    zip_attachment.save!
    filename = "#{folder.context.short_name}-#{folder.name} files"
    make_zip_tmpdir(filename) do |zip_name|
      @logger.debug("creating #{zip_name}")
      Zip::File.open(zip_name, Zip::File::CREATE) do |zipfile|
        @logger.debug("zip_name: #{zip_name}")
        process_folder(folder, zipfile)
      end
      mark_successful! if @files_added
      complete_attachment!(zip_attachment, zip_name)
    end
  end

  def process_folder(folder, zipfile, start_dirs=[], opts={}, &callback)
    if callback
      zip_folder(folder, zipfile, start_dirs, opts, &callback)
    else
      zip_folder(folder, zipfile, start_dirs, opts)
    end
  end

  # make a tmp directory and yield a filename under that directory to the block
  # given. the tmp directory is deleted when the block returns.
  def make_zip_tmpdir(filename)
    filename = File.basename(filename.gsub(/ /, "_").gsub(/[^\w-]/, ""))
    Dir.mktmpdir do |dirname|
      zip_name = File.join(dirname, "#{filename}.zip")
      yield zip_name
    end
  end

  # The callback should accept two arguments, the attachment/folder and the folder names
  def zip_folder(folder, zipfile, folder_names, opts={}, &callback)
    if callback && (folder.hidden? || folder.locked)
      callback.call(folder, folder_names)
    end
    # @user = nil either means that
    # 1. this is part of a public course, and is being downloaded by somebody
    # not logged in - OR -
    # 2. we're doing this inside a course context export, and are bypassing
    # the user check (@check_user == false)
    attachments = if !@check_user || folder.context.grants_right?(@user, :manage_files)
                folder.active_file_attachments
              else
                folder.visible_file_attachments
              end

    attachments = attachments.select{|a| opts[:exporter].export_object?(a)} if opts[:exporter]
    attachments.select{|a| !@check_user || a.grants_right?(@user, :download)}.each do |attachment|
      callback.call(attachment, folder_names) if callback
      @context = folder.context
      @logger.debug("  found attachment: #{attachment.unencoded_filename}")
      path = folder_names.empty? ? attachment.display_name : File.join(folder_names, attachment.display_name)
      @files_added = false unless add_attachment_to_zip(attachment, zipfile, path)
    end
    folder.active_sub_folders.select{|f| !@check_user || f.grants_right?(@user, :read_contents)}.each do |sub_folder|
      new_names = Array.new(folder_names) << sub_folder.name
      if callback
        zip_folder(sub_folder, zipfile, new_names, opts, &callback)
      else
        zip_folder(sub_folder, zipfile, new_names, opts)
      end
    end
  end

  def mark_attachment_as_zipping!(zip_attachment)
    zip_attachment.workflow_state = 'zipping'
    zip_attachment.save!
  end

  def zip_quiz(zip_attachment, quiz)
    Quizzes::QuizSubmissionZipper.new(
      quiz: quiz,
      zip_attachment: zip_attachment).zip!
  end

  def mark_successful!
    @zip_successful = true
  end

  def zipped_successfully?
    !!@zip_successful
  end

  def add_attachment_to_zip(attachment, zipfile, filename = nil)
    filename ||= attachment.filename

    # we allow duplicate filenames in the same folder. it's a bit silly, but we
    # have to handle it here or people might not get all their files zipped up.
    @files_in_zip ||= Set.new
    filename = Attachment.make_unique_filename(filename, @files_in_zip)
    @files_in_zip << filename

    handle = nil
    begin
      handle = attachment.open(:need_local_file => true)
      zipfile.get_output_stream(filename){|zos| Zip::IOExtras.copy_stream(zos, handle)}
    rescue => e
      @logger.error("  skipping #{attachment.full_filename} with error: #{e.message}")
      return false
    ensure
      handle.close if handle
    end

    true
  end

  def update_progress(zip_attachment, idx, count)
    zip_attachment.file_state = ((idx + 1).to_f / count.to_f * 100).to_i
    zip_attachment.save!
    @logger.debug("status for #{zip_attachment.id} updated to #{zip_attachment.file_state}")
  end

  def complete_attachment!(zip_attachment, zip_name)
    if zipped_successfully?
      @logger.debug("data zipped! uploading to s3...")
      uploaded_data = Rack::Test::UploadedFile.new(zip_name, 'application/zip')
      zip_attachment.uploaded_data = uploaded_data
      zip_attachment.workflow_state = 'zipped'
      zip_attachment.file_state = 'available'
      zip_attachment.save!
    else
      zip_attachment.workflow_state = 'errored'
      zip_attachment.save!
    end
  end
end
