
$( function() {
    $('input[name="date"]').datepicker({
      dateFormat: "yy-mm-dd"
    });
    
    var inputElem = document.querySelector('input[name="tags"]');
    var tagify = new Tagify(inputElem, {
        whitelist: [{tagHistory}],
        originalInputValueFormat: valuesArr => valuesArr.map(item => item.value).join(',')
    });
    $('form').keydown(function(event){
      if(event.keyCode == 13) {
        event.preventDefault();
        return false;
      }
    });
} );
