function initMap() {
        var mapArray = [
          { id:'map', 
            position:{lat: 54.693, lng: 25.275}
          },
          { id:'map2', 
            position:{lat: 54.693, lng: 25.275}
          }
        ]
        
        mapArray.forEach(function(item, index){
          var map = new google.maps.Map(document.getElementById(item.id), {
            zoom: 13,
            center: item.position
          });
          var marker = new google.maps.Marker({
            position: item.position,
            map: map,
            draggable: true
          });
          
          google.maps.event.addListener(marker, 'dragend', function(ev){
              console.log('********',item.id,'********');
              console.log("lat: ", marker.position.lat());
              console.log("lng: ", marker.position.lng());
          });
        })
      }