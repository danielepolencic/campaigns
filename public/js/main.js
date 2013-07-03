
$(function() {
  return $('.register').submit(function(event) {
    var email;
    event.preventDefault();
    email = $(this).find('.email').val();
    return $.ajax({
      type: 'POST',
      url: '/register',
      dataType: 'json',
      data: {
        email: email,
        url_hash: Playous.url_hash
      },
      success: function(response, status, xhr) {
        console.log("success: %o", response);
        $('.slide1').addClass('hide');
        return $('.slide2').removeClass('hide').find('.url_invite').val("" + Playous.domain + "/" + response.url_hash);
      },
      error: function(xhr, errorType, error) {
        var response;
        response = JSON.parse(xhr.responseText);
        return console.log("error: %o", response);
      }
    });
  });
});
