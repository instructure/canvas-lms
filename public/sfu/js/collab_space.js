// remove everything except Contributor and Moderator roles from enrollment options
utils.onPage(/^\/courses\/\d+\/users$/, function() {
    function removeUnusedRoles(index) {
        var $this = $(this);
        var val = $this.val();
        if (val && !(val === '' || val === 'Contributor' || val === 'Moderator')) {
          $this.remove()
        }
    }
    $('select[name="enrollment_role"] option, #enrollment_type option').each(removeUnusedRoles);
    $('#addUsers').on('click', function(ev) {
        $('#enrollment_type option').each(removeUnusedRoles);
        $('#privileges').remove();
    });
});