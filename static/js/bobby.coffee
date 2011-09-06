location_cache = {}
cache = {}
NotiBar = 
  types: [ "error", "success" ]
  hideAllMessages: ->
    messagesHeights = new Array()
    i = 0
    while i < @types.length
      messagesHeights[i] = $("." + @types[i]).outerHeight()
      $("." + @types[i]).css "top", -messagesHeights[i]
      i++
  
  showMessage: (type, msg) ->
    @hideAllMessages()
    $("." + type).find("h3").html msg  if msg
    $("." + type).animate(top: "0", 500).delay(1000).fadeOut()

Bobby = 
  get_venue: (id) ->
    cache["venue:" + id] or $.getJSON("/dashboard/venue/" + id, (resp) ->
      result = resp
      cache["venue:" + id] = resp
    )
  
  update: ->
    $.when_($.getJSON("/dashboard/updater")).then (resp) ->
      NotiBar.showMessage "success", "새로운 체크인정보를 업데이트하였습니다"

$(document).ready ->
  latlng = new google.maps.LatLng(37.541, 127.066)
  myOptions = 
    zoom: 16
    center: latlng
    mapTypeId: google.maps.MapTypeId.ROADMAP

  map = new google.maps.Map(document.getElementById("map"), myOptions)

  $("#Updater img").rotate bind: click: ->
    $(this).rotate 
      angle: 0
      animateTo: 360
      easing: $.easing.easeInOutExpo
  
  $("#Updater").click ->
    Bobby.update()
  
  $("#mylocation").click ->
    if navigator.geolocation
      navigator.geolocation.getCurrentPosition ((pos) ->
        NotiBar.showMessage "success", "I Found You!"
        loc = new google.maps.LatLng(pos.coords.latitude, pos.coords.longitude)
        marker = new google.maps.Marker(
          position: loc
          map: map
          icon: "/static/images/person.png"
          title: "You're Here!"
        )
        map.setCenter loc
      ), ->
        NotiBar.showMessage "error", "Could not use Geolocation API"
    else
      NotiBar.showMessage "error", "Could not use Geolocation API"
  
  NotiBar.hideAllMessages()
  $(".message").click ->
    $(this).animate top: -$(this).outerHeight(), 500
  
  
  onNewEvent = (e) ->
    try
      location = new google.maps.LatLng(e.lat, e.lng)
      if location_cache[e.id]
        location_cache[e.id].push e
        return
      else
        location_cache[e.id] = new Array()
        location_cache[e.id].push e
      marker = new google.maps.Marker(
        position: location
        map: map
        animation: google.maps.Animation.DROP
        icon: e.icon
        title: e.name
      )
      date = new Date(e.created_at * 1000)
      show_status = ->
        $("#Photos > img").remove()
        $.when_(Bobby.get_venue(e.id)).then (res) ->
          $("#location").html $("<a/>").attr(
            href: res.foursquareUrl
            target: "_blank"
          ).html(e.name + " (" + res.beenHere + ")")
          $(res.photos).each (id, data) ->
            thumbnail = data.sizes.items[2]
            return  unless thumbnail
            $("<img>").attr(
              src: thumbnail.url
              width: thumbnail.width
              height: thumbnail.height
              rel: "facebox"
            ).click(->
              $.facebox image: data.sizes.items[0].url, "album"
            ).appendTo $("#Photos")
        
        $("#location").html e.name
        $("#VisitedAt").html date.toDateString() + " " + date.toTimeString()
        $("#People").html "w/ " + e.people
        twttr.anywhere (T) ->
          T("#People").hovercards()
        
        $("#result").show()
        recent_marker.setAnimation null  if recent_marker
        recent_marker = marker
        if marker.getAnimation()?
          marker.setAnimation null
        else
          marker.setAnimation google.maps.Animation.BOUNCE
        map.setCenter location
      
      google.maps.event.addListener marker, "click", ->
        show_status()
      
      $("#list").append $("<li/>").html(e.name).click(->
        show_status()
      )
    catch e
      console.log e  if console
  
  unless typeof DUI == "undefined"
    s = new DUI.Stream()
    s.listen "application/json", (payload) ->
      event = eval("(" + payload + ")")
      onNewEvent event
    
    s.load "/dashboard/mxhrpoll"
  else
    $.ev.handlers.message = onNewEvent
    $.ev.loop_ "/dashboard/poll?client_id=" + Math.random()
