function initMap() {
        var mapArray = [
          { id:'map', 
            position:{lat: -25.363, lng: 131.044}
          },
          { id:'map2', 
            position:{lat: -25.363, lng: 131.044}
          }
        ]
        
        mapArray.forEach(function(item, index){
          var map = new google.maps.Map(document.getElementById(item.id), {
            zoom: 8,
            center: item.position
          });
          var marker = new google.maps.Marker({
            position: item.position,
            map: map
          });
        })
      }