class Resizer

  constructor   : (@$window) ->

    { @width, @height } = @getSize @$window
    console.log "LOG: @width: %o, @height %o", @width, @height

  getSize       : ( $element ) ->
    if $element.hasOwnProperty 'outerWidth'
      width = $element.outerWidth true
      height = $element.outerHeight true
    else
      width = $element.width()
      height = $element.height()
    { width, height }

  resize        : ( $target ) ->

    { width, height } = @getSize $target

    if width < @width
      console.log "LOG: width, @width %o", width, @width
      ratio = @width / width
      width = @width
      height = Math.floor height * ratio

    if height < @height
      console.log "LOG: height, @height %o", height, @height
      ratio = @height / height
      height = @height
      width = Math.floor width * ratio

    { width, height }

$ ->

  $bg = $ '.bg'
  $navbar = $ '.navbar'
  $slide_one = $('.slide.one')
  $slide_two = $('.slide.two')
  $window = $ window

  navbar = {}
  slide_one = {}
  slide_two = {}
  windov = {}

  resizer = new Resizer $window

  $img = $bg.find('img').eq(0)

  $img.css 'opacity', 0

  $bg
    .imagesLoaded ->

      self = @

      { width, height } = resizer.resize $img

      $img
        .width( width )
        .height( height )
        .css
          position  : 'fixed'
          bottom    : '0'
          zIndex    : '-1'
        .animate
          opacity   : 1

  windov = resizer.getSize $window
  navbar = resizer.getSize $navbar
  slide_one = resizer.getSize $slide_one
  slide_two = resizer.getSize $slide_two

  console.log "LOG: ( windov.height - navbar.height - slide_one.height ) / 2 %o", ( windov.height - navbar.height - slide_one.height ) / 2
  setTimeout ->
    $slide_one.css
      paddingTop  : ( windov.height - navbar.height - slide_one.height ) / 2
  , 100

  $('#preview-invite').fancybox()

  $('#notify-invite').html()
  $('#send-invite').click ->
    $.ajax
      url     : '/invite'
      type    : 'POST'
      dataType: 'json'
      data    :
        addresses   : "#{$('#addresses-invite').val()}".split ','
      success : ( res ) ->
        console.log "LOG: res %o", res
        $('#addresses-invite').val ""
        $('#notify-invite')
          .html "<span class=\"icon tick\"></span> Successful!"

  $('#register-now').click ->
    $.ajax
      url     : "/register"
      type    : 'POST'
      dataType: 'json'
      data    :
        email   : $('#email').val()
        url_hash: Playous.url_hash || ''
      success : ( res ) ->
        console.log "LOG: res %o", res
        $slide_one
        .css
          position      : 'absolute'
          top           : 0
          left          : 0
        .animate
          opacity       : 0
        , 400 , ->
          $slide_one
            .remove()

        $('#url_share').val "#{Playous.domain}/#{res.url_hash}"
        $('#facebook-share').attr "href", "http://www.facebook.com/sharer.php?u=#{Playous.domain}/#{res.url_hash}&t=My Title"
        $('#twitter-share').attr "href", "http://twitter.com/home/?status=My Message. Please register here -> #{Playous.domain}/#{res.url_hash}"

        setTimeout ->
          $slide_two
            .removeClass('hide')
            .css
              paddingTop  : ( windov.height - navbar.height - slide_two.height ) / 2
              opacity     : 0
            .animate
              opacity : 1
            , 500, ->
              progress = {}
              progress.labels =
                0     : "first-step"
                1     : "second-step"
                2     : "third-step"
                3     : "fourth-step"
              $progress= $slide_two.find('.progress')
              $('.progress-bar').addClass progress.labels[res.followers || 0]
              progress = resizer.getSize $progress
              stick = progress.width / 4
              $progress.animate
                backgroundPosition  : ( stick / 2 ) + ( stick * ( res.followers || 0 ) ) - 300
        , 200

