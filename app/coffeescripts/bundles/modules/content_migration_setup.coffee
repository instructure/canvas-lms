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

define [
  'i18n!content_migrations'
  'jquery'
  '../../collections/ProgressingContentMigrationCollection'
  '../../models/ContentMigration'
  '../../collections/DaySubstitutionCollection'
  '../../views/CollectionView'
  '../../views/PaginatedCollectionView'
  '../../views/content_migrations/ProgressingContentMigrationView'
  '../../views/content_migrations/MigrationConverterView'
  '../../views/content_migrations/CommonCartridgeView'
  '../../views/content_migrations/ConverterViewControl'
  '../../views/content_migrations/ZipFilesView'
  '../../views/content_migrations/CopyCourseView'
  '../../views/content_migrations/MoodleZipView'
  '../../views/content_migrations/CanvasExportView'
  '../../views/content_migrations/QTIZipView'
  '../../views/content_migrations/subviews/ChooseMigrationFileView'
  '../../views/content_migrations/subviews/FolderPickerView'
  '../../views/content_migrations/subviews/SelectContentCheckboxView'
  '../../views/content_migrations/subviews/QuestionBankView'
  '../../views/content_migrations/subviews/CourseFindSelectView'
  '../../views/content_migrations/subviews/DateShiftView'
  '../../views/content_migrations/subviews/DaySubstitutionView'
  'jst/content_migrations/ProgressingContentMigrationCollection'
  '../../views/content_migrations/ExternalToolContentView'
  '../../views/content_migrations/subviews/ExternalToolLaunchView'
  '../../views/ExternalTools/ExternalContentReturnView'
  '../../models/ExternalTool'
  'vendor/jquery.ba-tinypubsub'
  'jst/content_migrations/subviews/DaySubstitutionCollection'
  '../../views/content_migrations/subviews/OverwriteAssessmentContentView'
  '../../views/content_migrations/subviews/ImportQuizzesNextView'
], (I18n, $,
    ProgressingContentMigrationCollection,
    ContentMigrationModel,
    DaySubstitutionCollection,
    CollectionView,
    PaginatedCollectionView,
    ProgressingContentMigrationView,
    MigrationConverterView,
    CommonCartridgeView,
    ConverterViewControl,
    ZipFilesView,
    CopyCourseView,
    MoodleZipView,
    CanvasExportView,
    QTIZipView,
    ChooseMigrationFileView,
    FolderPickerView,
    SelectContentCheckboxView,
    QuestionBankView,
    CourseFindSelectView,
    DateShiftView,
    DaySubView,
    progressingMigrationCollectionTemplate,
    ExternalToolContentView,
    ExternalToolLaunchView,
    ExternalContentReturnView,
    ExternalTool,
    pubsub,
    daySubCollectionTemplate,
    OverwriteAssessmentContentView,
    ImportQuizzesNextView) ->
  ConverterViewControl.setModel new ContentMigrationModel
                                 course_id: ENV.COURSE_ID
                                 daySubCollection: daySubCollection

  daySubCollection          = new DaySubstitutionCollection
  daySubCollectionView      = new CollectionView
                                 collection: daySubCollection
                                 emptyMessage: -> I18n.t('no_day_substitutions', "No Day Substitutions Added")
                                 itemView: DaySubView
                                 template: daySubCollectionTemplate

  progressingMigCollection  = new ProgressingContentMigrationCollection null,
                                 course_id: ENV.COURSE_ID

  progressingCollectionView = new PaginatedCollectionView
                                 el: '#progress'
                                 collection: progressingMigCollection
                                 template: progressingMigrationCollectionTemplate
                                 emptyMessage: -> I18n.t('no_migrations_running', "There are no migrations currently running")
                                 itemView: ProgressingContentMigrationView
  questionBankView = new QuestionBankView
                        model: ConverterViewControl.getModel()
                        questionBanks: ENV.QUESTION_BANKS

  progressingCollectionView.getStatusView = (migProgress) ->
    if getView = ConverterViewControl.getView(migProgress.get('migration_type'))?.view?.getStatusView
      getView(migProgress)

  progressingCollectionView.render()

  migrationConverterView    = new MigrationConverterView
                                 el: '#migrationConverterContainer'
                                 selectOptions: ENV.SELECT_OPTIONS
                                 model: ConverterViewControl.getModel()
  migrationConverterView.render()

  dfd = progressingMigCollection.fetch()
  progressingCollectionView.$el.disableWhileLoading dfd

  # Migration has now started and is being processed at this point.
  $.subscribe 'migrationCreated', (migrationModelData) ->
    progressingMigCollection.add migrationModelData
    $.screenReaderFlashMessageExclusive(I18n.t('Content migration queued'))

  # Registers any subviews with any changes that happen
  # when selecting a converter. Give it the value to
  # look for then the subview to insert. Works like
  # this
  #
  # ie   ConverterChange.register key: 'some_dropdown_value', view: new BackboneView

  ConverterViewControl.register
    key: 'zip_file_importer'
    view: new ZipFilesView
            chooseMigrationFile: new ChooseMigrationFileView
                                   model: ConverterViewControl.getModel()
                                   fileSizeLimit: ENV.UPLOAD_LIMIT

            folderPicker:        new FolderPickerView
                                   model: ConverterViewControl.getModel()
                                   folderOptions: ENV.FOLDER_OPTIONS

  ConverterViewControl.register
    key: 'course_copy_importer'
    view: new CopyCourseView
            courseFindSelect: new CourseFindSelectView
                                current_user_id: ENV.current_user_id
                                model: ConverterViewControl.getModel()
                                show_select: ENV.SHOW_SELECT

            selectContent:    new SelectContentCheckboxView(model: ConverterViewControl.getModel())

            dateShift:        new DateShiftView
                                model: ConverterViewControl.getModel()
                                collection: daySubCollection
                                daySubstitution: daySubCollectionView
                                oldStartDate: ENV.OLD_START_DATE
                                oldEndDate: ENV.OLD_END_DATE


  ConverterViewControl.register
    key: 'moodle_converter'
    view: new MoodleZipView
            chooseMigrationFile: new ChooseMigrationFileView
                                   model: ConverterViewControl.getModel()
                                   fileSizeLimit: ENV.UPLOAD_LIMIT

            selectContent:       new SelectContentCheckboxView(model: ConverterViewControl.getModel())

            questionBank:        questionBankView

            dateShift:        new DateShiftView
                                model: ConverterViewControl.getModel()
                                collection: daySubCollection
                                daySubstitution: daySubCollectionView
                                oldStartDate: ENV.OLD_START_DATE
                                oldEndDate: ENV.OLD_END_DATE

  ConverterViewControl.register
    key: 'canvas_cartridge_importer'
    view: new CanvasExportView
            chooseMigrationFile: new ChooseMigrationFileView
                                   model: ConverterViewControl.getModel()
                                   fileSizeLimit: ENV.UPLOAD_LIMIT

            selectContent:       new SelectContentCheckboxView(model: ConverterViewControl.getModel())

            dateShift:        new DateShiftView
                                model: ConverterViewControl.getModel()
                                collection: daySubCollection
                                daySubstitution: daySubCollectionView
                                oldStartDate: ENV.OLD_START_DATE
                                oldEndDate: ENV.OLD_END_DATE

  ConverterViewControl.register
    key: 'common_cartridge_importer'
    view: new CommonCartridgeView
            chooseMigrationFile: new ChooseMigrationFileView
                                   model: ConverterViewControl.getModel()
                                   fileSizeLimit: ENV.UPLOAD_LIMIT

            selectContent:       new SelectContentCheckboxView(model: ConverterViewControl.getModel())

            questionBank:        questionBankView

            importQuizzesNext:     new ImportQuizzesNextView
                                  model: ConverterViewControl.getModel()
                                  quizzesNextEnabled: ENV.QUIZZES_NEXT_ENABLED
                                  questionBank: questionBankView

            overwriteAssessmentContent: new OverwriteAssessmentContentView(model: ConverterViewControl.getModel())


            dateShift:        new DateShiftView
                                model: ConverterViewControl.getModel()
                                collection: daySubCollection
                                daySubstitution: daySubCollectionView
                                oldStartDate: ENV.OLD_START_DATE
                                oldEndDate: ENV.OLD_END_DATE

            quizzes_next_enabled: ENV.QUIZZES_NEXT_ENABLED
            quizzes_next_configured_root: ENV.QUIZZES_NEXT_CONFIGURED_ROOT

  ConverterViewControl.register
    key: 'qti_converter'
    view: new QTIZipView
            chooseMigrationFile: new ChooseMigrationFileView
                                   model: ConverterViewControl.getModel()
                                   fileSizeLimit: ENV.UPLOAD_LIMIT

            questionBank:        questionBankView

            importQuizzesNext:     new ImportQuizzesNextView
                                  model: ConverterViewControl.getModel()
                                  quizzesNextEnabled: ENV.QUIZZES_NEXT_ENABLED
                                  questionBank: questionBankView

            overwriteAssessmentContent: new OverwriteAssessmentContentView(model: ConverterViewControl.getModel())
            quizzes_next_enabled: ENV.QUIZZES_NEXT_ENABLED
            quizzes_next_configured_root: ENV.QUIZZES_NEXT_CONFIGURED_ROOT




  registerExternalTool = (et) ->
    toolModel = new ExternalTool(et)
    returnView = new ExternalContentReturnView
      model: toolModel
      launchType: 'migration_selection'

    launchView = new ExternalToolLaunchView
      model: ConverterViewControl.getModel()
      contentReturnView: returnView

    selectContentView = new SelectContentCheckboxView
      model: ConverterViewControl.getModel()

    contentView = new ExternalToolContentView
      selectContent: selectContentView
      externalToolLaunch: launchView

    ConverterViewControl.register
      key: toolModel.assetString()
      view: contentView

  for et in ENV.EXTERNAL_TOOLS
    registerExternalTool(et)
