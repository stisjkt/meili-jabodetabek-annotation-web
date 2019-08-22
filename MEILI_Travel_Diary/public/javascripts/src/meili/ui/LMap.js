var lastCenter;
var LMap = LMap || function(mapConfig) {
  // Leaflet map constructor
  var targetElement = 'map';
  if($('body').width() > 700) {
    $('#'+targetElement).height($('#content').height() - 0.3*$('#bs-example-navbar-collapse-1').height());
  }

  log.debug('UI LMap -> init', 'Map is drawn');

  this.map = new L.Map(targetElement, mapConfig.options);

  // Create layers from config
  var layerControl = L.control.layers();
  for (var i = 0; i < mapConfig.layers.length; i++) {
    var layerConfig = mapConfig.layers[i];

    var layer = new L.GridLayer.GoogleMutant(layerConfig.options);
    
    $('.leaflet-control-attribution').hide();

    if(layerConfig.type = 'roadmap') {
      layerControl.addBaseLayer(layer, layerConfig.label);
    } else {
      layerControl.addOverLay(layer, layerConfig.label);
    }
    if(layerConfig.visibleAtStart) {
      layer.addTo(this.map);
    }
  };
  layerControl.addTo(this.map);

  // Create a trip layer
  this.tripLayer = new L.FeatureGroup();
  this.tripLayer.addTo(this.map);
  this.map.setView(mapConfig.start.center, mapConfig.zoom);
  lastCenter = this.map;
  return this;
};
LMap.prototype = {

  addNewPlace: function() {
    var dfd = $.Deferred();
    new Confirm().show({
        heading: 'Tambahkan Lokasi Baru',
        question: '<div class="form-group has-feedback">'+
                  '<input type="text" class="form-control" placeholder="Cari Lokasi..." name="poi-name" onfocus="addr_search();" id="search-address"/>'+
                  '<span class="glyphicon glyphicon-search form-control-feedback"></span>'+
                  '</div>'+
                  '<b>Nama Lokasi:</b><br/>' +
                  '<input type="text" class="form-control" name="poi-name" placeholder="Nama lokasi.." id="poi-name"/>'+
                  '<div id="result"></div>',
        okButtonTxt: 'Tambahkan',
		cancelButtonTxt: 'Batal'
      },
      function($element) {
        var poiName = $element.find('#poi-name').val();
        // Set map cursor to marker icon
        function mapClicked(e) {
          // remove event handler
          this.map.off('click', mapClicked);
          // Reset cursor
          $(this.map.getContainer()).css({'cursor': 'auto'});
          // resolve with clicked position
          dfd.resolve(poiName, e.latlng);
          
        }

        if (poiName == false){
            swal("Error!", "Nama lokasi harus diisi!", "error");
            $(".place-selector.destination").val($('.place-selector.destination option:first-child').val()).change();
        } else {
          if(changeAddr != null){
            dfd.resolve(poiName, changeAddr);
            changeAddr = null;
          } else {
            $(this.map.getContainer()).css({'cursor': 'url(/images/marker-icon.png) 12 32, default'});
            this.map.on('click', mapClicked.bind(this));
          }
        } 
      }.bind(this));

      if($(".place-selector.destination").val() === "add_new"){
        $(".place-selector.destination").val($('.place-selector.destination option:first-child').val()).change();
      }   
    return dfd.promise();
  },

  fitBounds: function(bounds) {
    this.map.fitBounds(bounds);
  },

  clear: function() {
    this.tripLayer.clearLayers();
  },

  render: function(tripLayer) {
    this.clear();
    this.tripLayer.addLayer(tripLayer);
    this.fitBounds(this.tripLayer.getBounds());
  }

};
