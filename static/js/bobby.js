var map;
var location_cache = {};
function load() {
  var latlng = new google.maps.LatLng(37.541, 127.066);
  var myOptions = {
    zoom: 16,
    center: latlng,
    mapTypeId: google.maps.MapTypeId.ROADMAP
  };
  map = new google.maps.Map(document.getElementById("map"), myOptions);
}

var cache = {};
var NotiBar = {
    types: [ 'error', 'success' ],
    hideAllMessages: function () {
      var messagesHeights = new Array();
      for (i=0; i< this.types.length; i++) {
         messagesHeights[i] = $('.' + this.types[i]).outerHeight();
         $('.' + this.types[i]).css('top', -messagesHeights[i]); 
      }
    },
    showMessage: function (type, msg) { 
      this.hideAllMessages();
      if (msg) $('.'+type).find('h3').html(msg);
      $('.'+type).animate({top:"0"}, 500).delay(1000).fadeOut();
    }
};

var Bobby = {
  get_venue: function (id) {
    return cache["venue:"+id] || $.getJSON('/dashboard/venue/' + id, function (resp) {
      result = resp;
      cache["venue:"+id] =  resp;
    });
  },
  update: function () {
    $.when($.getJSON('/dashboard/updater')).then(function (resp) {
      NotiBar.showMessage('success', "새로운 체크인정보를 업데이트하였습니다");
    })
  }
};

$(function () { 
  $("#Updater img").rotate({ bind: { 
    click: function() {
      $(this).rotate({ angle:0,animateTo:360,easing: $.easing.easeInOutExpo })
    }
  }});

  $('#Updater').click(function () {
    Bobby.update();
  });

  $('#mylocation').click(function () {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(function (pos) {

        NotiBar.showMessage("success", "I Found You!");

        var loc = new google.maps.LatLng(pos.coords.latitude, pos.coords.longitude);
        var marker = new google.maps.Marker({
          position: loc,
          map: map,
          icon: "/static/images/person.png",
          title: "You're Here!"
        });
        map.setCenter(loc);

      }, function () {
        NotiBar.showMessage("error", "Could not use Geolocation API");
      });
    } else {
      NotiBar.showMessage('error', "Could not use Geolocation API"); 
    }
  });

  NotiBar.hideAllMessages();
                 
  $('.message').click(function(){                       
     $(this).animate({top: -$(this).outerHeight()}, 500);
  }); 

  var recent_marker;
  var onNewEvent = function (e) {
    try {
      var location = new google.maps.LatLng(e.lat, e.lng);
      if (location_cache[e.id]) {
        location_cache[e.id].push(e);
        return;
      } else {
        location_cache[e.id] = new Array();
        location_cache[e.id].push(e);
      }

      var marker = new google.maps.Marker({
        position: location,
        map: map,
        animation: google.maps.Animation.DROP,
        icon: e.icon,
        title: e.name
      });

      var date = new Date(e.created_at * 1000);

      var show_status = function () {
         $('#Photos > img').remove();

         $.when(Bobby.get_venue(e.id)).then(function (res) {
            $('#location').html($('<a/>').attr({ href: res.foursquareUrl, target: "_blank" }).html(e.name + " (" + res.beenHere + ")" ));
            $(res.photos).each(function (id, data) {
               var thumbnail = data.sizes.items[2];
               if (!thumbnail) return;
          
               $('<img>').attr({ src: thumbnail.url, width: thumbnail.width, height: thumbnail.height, rel: 'facebox' })
                  .click(function() {
                    $.facebox({ image: data.sizes.items[0].url }, 'album');
                  })
                  .appendTo($('#Photos'));
           });
         });

         $('#location').html(e.name);
         $('#VisitedAt').html(date.toDateString() + " " + date.toTimeString());
         $('#People').html("w/ " + e.people);
         twttr.anywhere(function (T) {
           T('#People').hovercards();
         });

         $('#result').show();
         if (recent_marker) {
           recent_marker.setAnimation(null);
         }
         recent_marker = marker;
         if (marker.getAnimation() != null) {
           marker.setAnimation(null);
         } else {
           marker.setAnimation(google.maps.Animation.BOUNCE);
         }
         map.setCenter(location);
      };

      google.maps.event.addListener(marker, 'click', function () {
        show_status();
      });

      $('#list').append(
        $('<li/>').html(e.name)
         .click(function () {
           show_status();
         }));

    } catch (e) { if (console) console.log(e) };
  }

  if (typeof DUI != 'undefined') {
    var s = new DUI.Stream();
    s.listen('application/json', function(payload) {
      var event = eval('(' + payload + ')');
      onNewEvent(event);
    });
    s.load('/dashboard/mxhrpoll');
  } else {
    $.ev.handlers.message = onNewEvent;
    $.ev.loop('/dashboard/poll?client_id=' + Math.random());
  }
});

