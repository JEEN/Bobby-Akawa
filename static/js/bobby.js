(function() {
  var Bobby, NotiBar, cache, location_cache;
  location_cache = {};
  cache = {};
  NotiBar = {
    types: ["error", "success"],
    hideAllMessages: function() {
      var i, messagesHeights, _results;
      messagesHeights = new Array();
      i = 0;
      _results = [];
      while (i < this.types.length) {
        messagesHeights[i] = $("." + this.types[i]).outerHeight();
        $("." + this.types[i]).css("top", -messagesHeights[i]);
        _results.push(i++);
      }
      return _results;
    },
    showMessage: function(type, msg) {
      this.hideAllMessages();
      if (msg) {
        $("." + type).find("h3").html(msg);
      }
      return $("." + type).animate({
        top: "0"
      }, 500).delay(1000).fadeOut();
    }
  };
  Bobby = {
    get_venue: function(id) {
      return cache["venue:" + id] || $.getJSON("/dashboard/venue/" + id, function(resp) {
        var result;
        result = resp;
        return cache["venue:" + id] = resp;
      });
    },
    update: function() {
      return $.when($.getJSON("/dashboard/updater")).then(function(resp) {
        return NotiBar.showMessage("success", "새로운 체크인정보를 업데이트하였습니다");
      });
    }
  };
  $(document).ready(function() {
    var latlng, map, myOptions, onNewEvent, s;
    latlng = new google.maps.LatLng(37.541, 127.066);
    myOptions = {
      zoom: 16,
      center: latlng,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    map = new google.maps.Map(document.getElementById("map"), myOptions);
    $("#Updater img").rotate({
      bind: {
        click: function() {
          return $(this).rotate({
            angle: 0,
            animateTo: 360,
            easing: $.easing.easeInOutExpo
          });
        }
      }
    });
    $("#Updater").click(function() {
      return Bobby.update();
    });
    $("#mylocation").click(function() {
      if (navigator.geolocation) {
        return navigator.geolocation.getCurrentPosition((function(pos) {
          var loc, marker;
          NotiBar.showMessage("success", "I Found You!");
          loc = new google.maps.LatLng(pos.coords.latitude, pos.coords.longitude);
          marker = new google.maps.Marker({
            position: loc,
            map: map,
            icon: "/static/images/person.png",
            title: "You're Here!"
          });
          return map.setCenter(loc);
        }), function() {
          return NotiBar.showMessage("error", "Could not use Geolocation API");
        });
      } else {
        return NotiBar.showMessage("error", "Could not use Geolocation API");
      }
    });
    NotiBar.hideAllMessages();
    $(".message").click(function() {
      return $(this).animate({
        top: -$(this).outerHeight()
      }, 500);
    });
    onNewEvent = function(e) {
      var date, location, marker, show_status;
      try {
        location = new google.maps.LatLng(e.lat, e.lng);
        if (location_cache[e.id]) {
          location_cache[e.id].push(e);
          return;
        } else {
          location_cache[e.id] = new Array();
          location_cache[e.id].push(e);
        }
        marker = new google.maps.Marker({
          position: location,
          map: map,
          animation: google.maps.Animation.DROP,
          icon: e.icon,
          title: e.name
        });
        date = new Date(e.created_at * 1000);
        show_status = function() {
          var recent_marker;
          $("#Photos > img").remove();
          $.when(Bobby.get_venue(e.id)).then(function(res) {
            $("#location").html($("<a/>").attr({
              href: res.foursquareUrl,
              target: "_blank"
            }).html(e.name + " (" + res.beenHere + ")"));
            return $(res.photos).each(function(id, data) {
              var thumbnail;
              thumbnail = data.sizes.items[2];
              if (!thumbnail) {
                return;
              }
              return $("<img>").attr({
                src: thumbnail.url,
                width: thumbnail.width,
                height: thumbnail.height,
                rel: "facebox"
              }).click(function() {
                return $.facebox({
                  image: data.sizes.items[0].url
                }, "album");
              }).appendTo($("#Photos"));
            });
          });
          $("#location").html(e.name);
          $("#VisitedAt").html(date.toDateString() + " " + date.toTimeString());
          $("#People").html("w/ " + e.people);
          twttr.anywhere(function(T) {
            return T("#People").hovercards();
          });
          $("#result").show();
          if (recent_marker) {
            recent_marker.setAnimation(null);
          }
          recent_marker = marker;
          if (marker.getAnimation() != null) {
            marker.setAnimation(null);
          } else {
            marker.setAnimation(google.maps.Animation.BOUNCE);
          }
          return map.setCenter(location);
        };
        google.maps.event.addListener(marker, "click", function() {
          return show_status();
        });
        return $("#list").append($("<li/>").html(e.name).click(function() {
          return show_status();
        }));
      } catch (e) {
        if (console) {
          return console.log(e);
        }
      }
    };
    if (typeof DUI !== "undefined") {
      s = new DUI.Stream();
      s.listen("application/json", function(payload) {
        var event;
        event = eval("(" + payload + ")");
        return onNewEvent(event);
      });
      return s.load("/dashboard/mxhrpoll");
    } else {
      $.ev.handlers.message = onNewEvent;
      return $.ev.loop("/dashboard/poll?client_id=" + Math.random());
    }
  });
}).call(this);
