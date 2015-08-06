require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')

describe 'quizzes stats' do
  include_examples 'in-process server selenium tests'

  context 'as a teacher' do

    before do
      course_with_teacher_logged_in
    end

    it "should display quiz statistics", priority: "1", test_id: 270036 do
      quiz_with_submission
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

      click_quiz_statistics_button

      expect(f('#content .question-statistics .question-text')).to include_text("Which book(s) are required for this course?")
    end

    it 'should have a link to the new quiz stats page', priority: "2", test_id: 270037 do
      quiz_with_submission
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      expect(f('.icon-stats')).to be
      expect(fj('ul.page-action-list')).to include_text('Quiz Statistics')
    end

    context 'stats page' do
      it 'should have a student analysis button tooltip', priority: "2", test_id: 270038 do
        quiz_with_submission
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"
        wait_for_ajaximations
        expect(fj('.report-generator:visible')).to_not include_text('Report has been generated')

        # move mouse over button
        driver.mouse.move_to f('.report-generator')
        wait_for_ajaximations
        expect(fj('.report-generator:visible')).to include_text('Generate student analysis report')
      end

      it 'should download a csv when pressing student analysis button ', priority: "1", test_id: 140638 do
        quiz_with_submission
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"
        wait_for_ajaximations

        fj('.generate-report').click
        wait_for_ajaximations

        # our env never creates a csv so the best we can do is check for it attempting to download it
        keep_trying_until(5) do
          # move away so the tooltip can be recreated
          driver.mouse.move_to ffj('.report-generator')[1]
          wait_for_ajaximations


          # move mouse back over button
          driver.mouse.move_to f('.report-generator')
          wait_for_ajaximations
          expect(fj('.quiz-report-status')).to include_text('Report is being generated')
        end
      end

      it 'should have a item analysis button tooltip', priority: "2", test_id: 270040 do
        quiz_with_submission
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"
        wait_for_ajaximations
        expect(ffj('.report-generator:visible')[1]).to_not include_text('Report has been generated')

        # move mouse over button
        driver.mouse.move_to ff('.report-generator')[1]
        wait_for_ajaximations
        expect(ffj('.report-generator:visible')[1]).to include_text('Generate item analysis report')
      end

      it 'should download a csv when pressing item analysis button ', priority: "1", test_id: 270039 do
        quiz_with_submission
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"
        wait_for_ajaximations

        ffj('.generate-report')[1].click
        wait_for_ajaximations

        # our env never creates a csv so the best we can do is check for it attempting to download it
        keep_trying_until(5) do
          # move away so the tooltip can be recreated
          driver.mouse.move_to ffj('.report-generator')[0]
          wait_for_ajaximations


          # move mouse back over button
          driver.mouse.move_to ff('.report-generator')[1]
          wait_for_ajaximations
          expect(ffj('.quiz-report-status')[1]).to include_text('Report is being generated')
        end
      end
    end

  end
end
