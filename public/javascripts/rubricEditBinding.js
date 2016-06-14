define(['edit_rubric', 'compiled/views/rubrics/EditRubricPage'], function(rubricEditing, EditRubricPage){
  document.addEventListener("rubricEditDataReady", function(e){
    new EditRubricPage
    rubricEditing.init()
  });
});
