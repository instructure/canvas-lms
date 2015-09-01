require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')

describe 'quizzes stats' do
  include_context 'in-process server selenium tests'

  context 'as a teacher' do

    before do
      course_with_teacher_logged_in
    end

    it 'should display quiz statistics', priority: "1", test_id: 270036 do
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

    context 'teacher preview' do
      it 'should not show a quiz stats button if there was a teacher preview', priority: "2", test_id: 140645 do
        quiz_create
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

        # take the quiz
        f('#take_quiz_link').click
        wait_for_ajaximations
        f('#submit_quiz_button').click
        driver.switch_to.alert.accept

        expect(fj('ul.page-action-list')).to_not include_text('Quiz Statistics')
      end

    end

    context 'stats page' do
      before do
        quiz_with_submission
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/statistics"
      end
      it 'should have a student analysis button tooltip', priority: "2", test_id: 270038 do
        expect(fj('.report-generator:visible')).to_not include_text('Report has been generated')

        # move mouse over button
        driver.mouse.move_to f('.report-generator')
        wait_for_ajaximations
        expect(fj('.report-generator:visible')).to include_text('Generate student analysis report')
      end

      it 'should download a csv when pressing student analysis button ', priority: "1", test_id: 140638 do
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
        expect(ffj('.report-generator:visible')[1]).to_not include_text('Report has been generated')

        # move mouse over button
        driver.mouse.move_to ff('.report-generator')[1]
        wait_for_ajaximations
        expect(ffj('.report-generator:visible')[1]).to include_text('Generate item analysis report')
      end

      it 'should download a csv when pressing item analysis button ', priority: "1", test_id: 270039 do
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

      context 'question breakdown toggle' do
        it 'should expand an area for all question breakdowns', priority: "1", test_id: 140640 do
          expect(ffj('ol.sighted-user-content.answer-drilldown.detail-section').size).to eq 0

          fj('div.sighted-user-content > button.btn').click
          expect(ffj('ol.sighted-user-content.answer-drilldown.detail-section').size).to eq 1
        end

        it 'should expand an area for each question breakdown', priority: "1", test_id: 140641 do
          expect(ffj('ol.sighted-user-content.answer-drilldown.detail-section').size).to eq 0

          fj('span.sighted-user-content > button.btn').click
          expect(ffj('ol.sighted-user-content.answer-drilldown.detail-section').size).to eq 1
        end

        it 'should have individual and all work togehter', priority: "1", test_id: 140642 do
          expect(ffj('ol.sighted-user-content.answer-drilldown.detail-section').size).to eq 0

          # click to expand all
          fj('span.sighted-user-content > button.btn').click
          expect(ffj('ol.sighted-user-content.answer-drilldown.detail-section').size).to eq 1

          # close a single question
          fj('span.sighted-user-content > button.btn').click
          expect(ffj('ol.sighted-user-content.answer-drilldown.detail-section').size).to eq 0

          # click to expand all
          fj('span.sighted-user-content > button.btn').click
          expect(ffj('ol.sighted-user-content.answer-drilldown.detail-section').size).to eq 1

          # click to close all
          fj('span.sighted-user-content > button.btn').click
          expect(ffj('ol.sighted-user-content.answer-drilldown.detail-section').size).to eq 0
        end

        it 'should have a discrimination index pop up', priority: "2", test_id: 140643 do
          fj('span.sighted-user-content > button.btn').click
          wait_for_ajaximations
          fj('i.chart-help-trigger.icon-question').click
          wait_for_ajaximations

          expect(f('span.ui-dialog-title')).to include_text('The Discrimination Index Chart')
        end
      end
    end
  end
end
