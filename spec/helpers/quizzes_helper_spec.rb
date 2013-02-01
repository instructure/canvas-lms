# encoding: utf-8
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe QuizzesHelper do
  include ApplicationHelper
  include QuizzesHelper

  context 'render_score' do
    it 'should render nil scores' do
      render_score(nil).should == '_'
    end

    it 'should render non-nil scores' do
      render_score(1).should == '1'
      render_score(100).should == '100'
      render_score(1.123).should == '1.12'
      render_score(1000.45166).should == '1000.45'
      render_score(1000.45966).should == '1000.46'
      render_score('100').should == '100'
      render_score('1.43').should == '1.43'
    end

    it 'should remove trailing zeros' do
      render_score(1.20000000).should == '1.2'
      render_score(0.10340000, 5).should == '0.1034'
    end

    it 'should remove trailing zeros and decimal point' do
      render_score(0.00000000).should == '0'
      render_score(1.00000000).should == '1'
      render_score(100.0).should == '100'
    end
  end

  context 'score_out_of_points_possible' do
    it 'should show single digit scores' do
      score_out_of_points_possible(1, 5).should == "1 out of 5"
      score_out_of_points_possible(0, 9).should == "0 out of 9"
    end

    it 'should show 2-decimal precision if necessary' do
      score_out_of_points_possible(0.66666666666, 1).should == "0.67 out of 1"
      score_out_of_points_possible(5.23333333333, 10.0).should == "5.23 out of 10"
    end

    it 'should be wrapped by a span when a CSS class, id, or style is given' do
      score_out_of_points_possible(1.5, 3, :class => "score_value").should == \
        '<span class="score_value">1.5</span> out of 3'
      score_out_of_points_possible(1.5, 3, :id => "score").should == \
        '<span id="score">1.5</span> out of 3'
      score_out_of_points_possible(1.5, 3, :style => "width:100%").should == \
        '<span style="width:100%">1.5</span> out of 3'
    end
  end

  context 'duration_in_minutes' do
    it 'should work in russian when count == 1' do
      I18n.locale = "ru"
      duration_in_minutes(60.6).should == "1 минута"
    end
  end

  context 'fill_in_multiple_blanks_question' do
    it 'should sanitize user input' do
      def user_content(stuff); stuff; end

      question_text = %q|<input name="question_1" 'value={{question_1}}' />|
      html = fill_in_multiple_blanks_question(
        :question => {:question_text => question_text},
        :answer_list => [%q|'><script>alert('ha!')</script><img|],
        :answers => []
      )

      html.should == %q|<input name="question_1" 'value=&#x27;&gt;&lt;script&gt;alert(&#x27;ha!&#x27;)&lt;/script&gt;&lt;img' readonly="readonly" />|
    end
  end
end
