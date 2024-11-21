function handleFiles()
{
    var dataurl = null;
    var filesToUpload = document.getElementById('photo').files;
    var file = filesToUpload[0];
    var photoType = document.getElementById('photoType').value;

    // Create an image
    var img = document.createElement("img");
    // Create a file reader
    var reader = new FileReader();
    // Set the image once loaded into file reader
    reader.onload = function(e)
    {
        img.src = e.target.result;

        img.onload = function () {
            var canvas = document.createElement("canvas");
            var ctx = canvas.getContext("2d");
            ctx.drawImage(img, 0, 0);

            var maxWidth = 2048;
            var maxHeight = 2048;
            var width = img.width;
            var height = img.height;

            if (width > height) {
              if (width > maxWidth) {
                height *= maxWidth / width;
                width = maxWidth;
              }
            } else {
              if (height > maxHeight) {
                width *= maxHeight / height;
                height = maxHeight;
              }
            }
            canvas.width = width;
            canvas.height = height;
            var ctx = canvas.getContext("2d");
            ctx.drawImage(img, 0, 0, width, height);

            dataurl = canvas.toDataURL("image/jpeg").slice(23);

            $.ajax({
                url: '/admin/ajax_photo?photoType=' + photoType,
                data: dataurl,
                cache: false,
                contentType: false,
                processData: false,
                type: 'POST',
                success: function(data) {
                    window.location.href = "/admin?module=photos"
                }
            });
        } // img.onload
    }
    // Load files into file reader
    reader.readAsDataURL(file);
}

function updatePhotoType(photoID, select) {
    $.getScript( "admin/updatePhotoType.js?updatePhotoID=" + photoID + "&typeID=" + select.value, function( data, textStatus, jqxhr ) {
      console.log( "Load was performed." );
    });
}
