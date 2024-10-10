function handleFiles()
{
    var dataurl = null;
    var filesToUpload = document.getElementById('photo').files;
    var file = filesToUpload[0];

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

            var MAX_WIDTH = 2048;
            var MAX_HEIGHT = 2048;
            var width = img.width;
            var height = img.height;

            if (width > height) {
              if (width > MAX_WIDTH) {
                height *= MAX_WIDTH / width;
                width = MAX_WIDTH;
              }
            } else {
              if (height > MAX_HEIGHT) {
                width *= MAX_HEIGHT / height;
                height = MAX_HEIGHT;
              }
            }
            canvas.width = width;
            canvas.height = height;
            var ctx = canvas.getContext("2d");
            ctx.drawImage(img, 0, 0, width, height);

            dataurl = canvas.toDataURL("image/jpeg").slice(23);

            $.ajax({
                url: '/admin/ajax_photo',
                data: dataurl,
                cache: false,
                contentType: false,
                processData: false,
                type: 'POST',
                success: function(data){
                    location.reload();
                }
            });
        } // img.onload
    }
    // Load files into file reader
    reader.readAsDataURL(file);
}
