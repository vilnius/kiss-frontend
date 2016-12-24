function initMap() {
        var mapArray = [
          { id:'home-map', 
            input: 'home-input',
            position:{lat: 54.693, lng: 25.275}
          },
          { id:'work-map', 
            input: 'work-input',
            position:{lat: 54.693, lng: 25.275}
          }
        ]
        
        mapArray.forEach(function(item, index){
          var map = new google.maps.Map(document.getElementById(item.id), {
            zoom: 13,
            mapTypeId: google.maps.MapTypeId.ROADMAP,
            disableDefaultUI: true,
            streetViewControl: false,
            center: item.position
          });
          var marker = new google.maps.Marker({
            position: item.position,
            map: map,
            draggable: true
          });
          
          google.maps.event.addListener(marker, 'dragend', function(ev){
              Shiny.onInputChange("marker_id", item.id);
              Shiny.onInputChange("marker_lat", marker.position.lat());
              Shiny.onInputChange("marker_lng", marker.position.lng());
          });
          
          // Create the search box and link it to the UI element.
          var input = document.getElementById(item.input);
          var searchBox = new google.maps.places.SearchBox(input);
          map.controls[google.maps.ControlPosition.TOP_LEFT].push(input);
          
          // Bias the SearchBox results towards current map's viewport.
          map.addListener('bounds_changed', function() {
              searchBox.setBounds(map.getBounds());
          });
          
          var markers = [];
        // Listen for the event fired when the user selects a prediction and
        // retrieve more details for that place.
        searchBox.addListener('places_changed', function() {
          var places = searchBox.getPlaces();

          if (places.length === 0) {
            return;
          }

          // Clear out the old markers.
          markers.forEach(function(marker) {
            marker.setMap(null);
          });
          
          
          markers = [];
          // For each place, get the icon, name and location.
          var bounds = new google.maps.LatLngBounds();
          places.forEach(function(place) {
            if (!place.geometry) {
              console.log("Returned place contains no geometry");
              return;
            }
            var icon = {
              url: place.icon,
              size: new google.maps.Size(71, 71),
              origin: new google.maps.Point(0, 0),
              anchor: new google.maps.Point(17, 34),
              scaledSize: new google.maps.Size(25, 25)
            };

            // Create a marker for each place.
            markers.push(new google.maps.Marker({
              map: map,
              icon: icon,
              title: place.name,
              position: place.geometry.location
            }));
            
            //Sending location to Shiny
            Shiny.onInputChange("marker_id", item.id);
            Shiny.onInputChange("marker_lat", place.geometry.location.lat());
            Shiny.onInputChange("marker_lng", place.geometry.location.lng());
            
            if (place.geometry.viewport) {
              // Only geocodes have viewport.
              bounds.union(place.geometry.viewport);
            } else {
              bounds.extend(place.geometry.location);
            }
          });
          map.fitBounds(bounds);
        });
          
          
          
        })//mapArray.forEach
      }