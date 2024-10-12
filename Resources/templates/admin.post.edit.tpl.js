
$( function() {
    $('input[name="date"]').datepicker({
      dateFormat: "yy-mm-dd"
    });
    
    var inputElem = document.querySelector('input[name="tags"]');
    var tagify = new Tagify(inputElem, {
        whitelist: [{tagHistory}],
        originalInputValueFormat: valuesArr => valuesArr.map(item => item.value).join(',')
    });
    var inputPhoto = document.querySelector('input[name="pictureIDs"]');
    var tagifyPhotos = new Tagify(inputPhoto, {
        originalInputValueFormat: valuesArr => valuesArr.map(item => item.value).join(',')
    });

    // must update Tagify's value according to the re-ordered nodes in the DOM
    function onDragEnd(elm){
        tagify.updateValueByDOMTags()
    }
    $('form').keydown(function(event){
      if(event.keyCode == 13) {
        event.preventDefault();
        return false;
      }
    });
} );
