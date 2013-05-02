class CourseDataController < ApplicationController
  before_filter :require_user
  include Common
  
  def base_dir
    "/usr/local/canvas/course-data"
  end

  def sep
    ":::"
  end

  def sep2
    ":_:"
  end

  def search
    data_arr = []
    queries = []
    term = params[:term]
    queries = params[:query].to_s.downcase.split unless params[:query].nil?
    file_name = "#{base_dir}/#{term}/all.lst"
    if File.exists? file_name
      File.open(file_name).each_line do |line|
        course_data = line.split(sep2).last.split(sep)
        name = course_data[0]
        number = course_data[1]
        section = course_data[2]
        title = course_data[3]
        course_display = "#{name.to_s.upcase}#{number} #{section.to_s.upcase} - #{title}"
        course_id = "#{term}#{sep}#{name.to_s.downcase}#{sep}#{number}#{sep}#{section.to_s.downcase}"
        # search must match all query parameters (e.g. math, 150, d100)
        data_arr << "#{course_id}#{sep2}#{course_display}" if queries.all? { |word| line.include?(word)}
      end
    end

    respond_to do |format|
      format.json { render :json => data_arr }
    end
  end

end
