
$( function() {
    $('input[name="date"]').datepicker({
      dateFormat: "yy-mm-dd"
    });
    $('input[name="tags"]').inputTags();
    $('form').keydown(function(event){
      if(event.keyCode == 13) {
        event.preventDefault();
        return false;
      }
    });
} );
