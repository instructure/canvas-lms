# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require 'spec_helper'

class MyTestError < StandardError
  def response_status
    401
  end
end

describe Canvas::Errors::Reporter do

  it "Should be able to catch a composed exception" do
    new_class = error_instance
    exception_handled = false
    begin
      raise new_class
    rescue MyTestError
      exception_handled = true
    end
    expect(exception_handled).to be true
  end

  it "Should have extra info" do
    new_class = error_instance
    expect(new_class.respond_to?(:canvas_error_info)).to be true
    expect(new_class.canvas_error_info[:princess_mode]).to be false
    expect(new_class.canvas_error_info[:unicorn_spotted]).to be true
    expect(new_class.canvas_error_info[:garbage]).to eq "%%jksdh38912398732987lkhjsadfkjhdfslk"
  end

  it "Should have correct backtrace" do
    new_class = error_instance
    expect(new_class.backtrace[0]).to match /typical_usage/
  end

  it "Shouldn't mess with existing classes" do
    new_class = error_instance
    old_class = MyTestError.new("i am a message")

    expect(new_class).to_not be_nil
    expect(old_class.respond_to?(:canvas_error_info)).to be false
  end

  it "Should inherrit from existing class" do
    new_class = error_instance

    expect(new_class.response_status).to be 401
  end

  it "Typical usecase" do
    expect{typical_usage}.to raise_error(MyTestError)
  end

  def extra_error_info
    {
      princess_mode: false,
      unicorn_spotted: true,
      garbage: "%%jksdh38912398732987lkhjsadfkjhdfslk"
    }
  end

  def error_instance
    begin
      typical_usage
    rescue MyTestError => err
      return err
    end
  end

  def typical_usage
    Canvas::Errors::Reporter.raise_canvas_error(MyTestError, "I am an error message", extra_error_info)
  end
end
