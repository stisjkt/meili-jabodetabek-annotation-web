// fungsi dibawah untuk autocomplete search
function addr_search(){
	var latitude = tempTimeline.trip.getLastTripleg().points[tempTimeline.trip.getLastTripleg().points.length-1].lat; //mendapatkan latitude dari point terakhir dari tripleg terakhir
	var longitude = tempTimeline.trip.getLastTripleg().points[tempTimeline.trip.getLastTripleg().points.length-1].lon;  //mendapatkan longitude dari point terakhir dari tripleg terakhir
	var center = new google.maps.LatLng(latitude,longitude); // titik tengah
	var circle = new google.maps.Circle({
		// membuat lingkaran dengan titik pusatnya adalah 'center', dengan radius 1000 m (1km) 
		center: center,
		radius: 1000
	});
	
	//mendeklarasikan autocomplete
	var autocomplete = new google.maps.places.Autocomplete(
	//   (document.getElementById('search-address')), {
	  ($('.form-control')[$('.form-control').length-2]), {
	  	//hasil yang keluar hanya di negara indonesia
	  	componentRestrictions: {country: "ID"},
	  	//hasil yang keluar lokasi terdekat dengan koordinat tujuan
	  	strictBounds: true
	  });
	
	autocomplete.setBounds(circle.getBounds()); // Pencarian destination of trip adalah lokasi terdekat dengan koordinat tujuan (1km)
	console.log(autocomplete);
	autocomplete.addListener('place_changed', fillInAddress); //ketika tempat berubah jalankan fungsi fillinaddress
	
	function fillInAddress() {
	  var place = autocomplete.getPlace(); // mendapatkan place dari autocomplete
	  $('.form-control:last').val(place.name);
	  chooseAddr(place.geometry.location.lat(),place.geometry.location.lng()); // mengambil latitude dan longitude dari tempat yang dipilih
	}
}

var changeAddr;
function chooseAddr(lat, lng) {
	changeAddr = {"lat": lat, "lng":lng};
}