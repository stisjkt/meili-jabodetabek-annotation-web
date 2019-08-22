var TriplegPanel = TriplegPanel || function(elementId, tripId, tripleg, previewMode) {

  this.elementId = elementId;
  this.tripId = tripId;
  this.tripleg = tripleg;
  this.previewMode = previewMode;

  Emitter(this);

  this.generateElement();

  return this;
};

TriplegPanel.prototype = {

  _onTimeSet: function(e) {

    var $target = $(e.target);

    var newTime = null;
	if ($target.hasClass('start')) {
		newTime = new Date(this.tripleg.getStartTime().getTime());
	} else if($target.hasClass('end')) {
		newTime = new Date(this.tripleg.getEndTime().getTime());
	}
    newTime.setFullYear(e.date.year());
	newTime.setMonth(e.date.month());
	newTime.setDate(e.date.date());
	newTime.setMinutes(e.date.minutes());
    newTime.setHours(e.date.hours());  
	
	if ($target.hasClass('start')) {
		if(this.tripleg.getStartTime().getTime() != newTime.getTime()) {
			log.info('UI Timeline -> _onTimeSet','changed timepicker start value of tripleg '+ this.tripleg.getId() +' to '+ newTime);
			newTime.setSeconds(0);
			newTime = newTime.getTime();
			this.emit('start-time-change', this.tripleg, newTime);
		}
	} else if($target.hasClass('end')) {
		if(this.tripleg.getEndTime().getTime() != newTime.getTime()) {
			log.info('UI Timeline -> _onTimeSet','changed timepicker start value of tripleg '+ this.tripleg.getId() +' to '+ newTime);
			newTime.setSeconds(0);
			newTime = newTime.getTime();
			this.emit('end-time-change', this.tripleg, newTime);
		}
	}

    e.preventDefault();
  },

  _bindEventListeners: function($element) {

    // Tripleg mode change
    $element.on('change', '.mode-select', function(e) {
	  for (var key in transportCost) {
		  if(key.endsWith('_' + this.tripleg.getId())){
			  delete transportCost[key];
		  }
	  }
      this.tripleg.updateMode(e.target.value);
      log.debug('UI TriplegPanel -> modecanged', 'on', this.tripleg.getId(), 'to', e.target.value);
      loadingOverlay();
    }.bind(this));
	
	$element.on('change', '.second-mode-select', function(e) {
	  for (var key in transportCost) {
		  if(key.endsWith('_'+this.tripleg.getId())){
			  delete transportCost[key];
		  }
	  }
      this.tripleg.updateMode2(e.target.value);
      log.debug('UI TriplegPanel -> modecanged', 'on', this.tripleg.getId(), 'to', e.target.value);
      loadingOverlay();
    }.bind(this));
	
	$element.on('keyup', '.cost-input', function(e) {
    transportCost[e.target.id] = e.target.value.replace(/,/g, '');
    e.target.value = (parseInt(event.target.value.replace(/[^\d]+/gi, '')) || 0).toLocaleString('en-US');
    }.bind(this));
	
	$element.on('blur', '.cost-input', function(e) {
	  transportCost[e.target.id] = e.target.value.replace(/,/g, '');
    e.target.value = (parseInt(event.target.value.replace(/[^\d]+/gi, '')) || 0).toLocaleString('en-US');
    }.bind(this));

    // Tripleg panel mouseover
    $element.on('mouseover', '.timeline-panel', function(e) {
      if(this.tripleg.polylineLayer) {
        this.tripleg.polylineLayer.setStyle({ opacity: 1 });
        log.debug('UI TriplegPanel -> mouseover', 'on', this.tripleg.getId());
      }
    }.bind(this));

    // Tripleg panel mouse exit
    $element.on('mouseout', '.timeline-panel', function(e) {
      if(this.tripleg.polylineLayer) {
        this.tripleg.polylineLayer.setStyle({ opacity: 0.6 });
        log.debug('UI TriplegPanel -> mouseout', 'on', this.tripleg.getId());
      }
    }.bind(this));

    // Tripleg panel mouse click
    $element.on('click', '.zoom-to-tripleg', function(e) {
      if(this.tripleg.polylineLayer) {
        this.emit('map-zoom-to', this.tripleg.polylineLayer.getBounds())
        log.debug('UI TriplegPanel -> zoom-to-tripleg click', 'Zoomed to layer ' + this.tripleg.getId());
      }
      e.preventDefault();
      return false;
    }.bind(this));

    $element.on('click', '.delete-tripleg', function(e) {
      new Confirm().show({ 
		heading: 'Hapus Tripleg', 
		question: 'Apakah Anda yakin ingin menghapus tripleg ini?',
		okButtonTxt: 'Ya',
		cancelButtonTxt: 'Tidak'
	  }, function() {
        this.emit('delete-tripleg', this.tripleg);
        log.debug('UI TriplegPanel -> delete-tripleg click', 'Delete tripleg ' + this.tripleg.getId());
      }.bind(this));
      e.preventDefault();
      return false;
    }.bind(this));

    $element.on('click', '.merge-tripleg', function(e) {
      new Confirm().show({ 
		heading: 'Gabungkan Tripleg', 
		question: 'Apakah Anda yakin ingin menggabungkan tripleg ini dengan tripleg sebelumnya?',
		okButtonTxt: 'Ya',
		cancelButtonTxt: 'Tidak'
	  }, function() {
        this.emit('merge-tripleg', this.tripleg);
        log.debug('UI TriplegPanel -> merge-tripleg click', 'Merge tripleg ' + this.tripleg.getId());
      }.bind(this));
      e.preventDefault();
      return false;
    }.bind(this));

    $element.on('change', '.place-selector.transition', function(e) {
      if(e.target.value) {
        if(e.target.value === 'add_new') {
          // Add new transition place
          this.emit('add-new-transportation-poi', this.tripleg);
        } else {
          // Update transition place
          this.tripleg.updateTransitionPoiIdOfTripleg(e.target.value);
        }
      }
    }.bind(this));

    // Activate timepickers
	var startDp =  $element.find('.time-picker.start');
    startDp.datetimepicker({
        format: 'DD MMM, HH:mm',
		ignoreReadonly: true,
		showClose: true,
		icons: {
			close: 'glyphicon glyphicon-floppy-saved'
		},
		tooltips: {
			close: 'Simpan'
		}
    }).on('dp.hide', this._onTimeSet.bind(this)).on('dp.show', function(e){
		$(e.target).find('.picker-switch a[data-action="togglePicker"]').click();
	});

	var endDp = $element.find('.time-picker.end');
    endDp.datetimepicker({
        format: 'DD MMM, HH:mm',
		ignoreReadonly: true,
		showClose: true,
		icons: {
			close: 'glyphicon glyphicon-floppy-saved'
		},
		tooltips: {
			close: 'Simpan'
		}
    }).on('dp.hide', this._onTimeSet.bind(this)).on('dp.show', function(e){
		$(e.target).find('.picker-switch a[data-action="togglePicker"]').click();
	});
	

  },

 /**
   * Appends the timeline element of a tripleg to the timeline list and adds its listeners
   * @param tripleg - the tripleg element
   */
  generateElement: function(tripId, tripleg) {

    if (this.tripleg.getType() == 1){
      var $ul = $('#'+this.elementId+' > ul');
      var $li = $('<li></li>');

      $li.html(this._generateContent(this.tripId, this.tripleg));
      // Add listeners
      this._bindEventListeners($li);
      // Add tripleg panel
      $ul.append($li);
      // Add transition panel
      $ul.append(this.getTransitionPanel(this.tripleg));
    }
  },

  /**
   * Generates the outerHTML for the timeline element corresponding to a tripleg
   * @param tripleg - the tripleg element
   * @returns {string} - outerHTML of the timeline element
   */
  _generateContent: function(tripId, tripleg) {
    var contentHtml = [
      '<ul class="tl-ctrl">',
      this._generateMergeTriplegButton(tripleg),
      '<li><a onclick="closeNav();" class="zoom-to-tripleg" title="Lihat di peta"><span class="glyphicon glyphicon-search medium"></span></a></li>',
        this._generateDeleteTriplegButton(tripleg),
      '</ul>',

      '<div class="timeline-panel" style="background-color:'+tripleg.getColor(0.6, '#FFF')+'">',
        '<div class="tl-heading">',
        '<p><strong>',
             '<span class="distance">Anda melakukan perjalanan sejauh ' + tripleg.getDistance() + '</span>',
             '<span class="travel-time"> dalam waktu ' + tripleg.getTravelTime() + '</span>',
          '</strong></p>',
        '</div>',
        '<div class="tl-body">',
          '<div class="row">',
            '<div class="col-md-6">',
				this._generateTimepicker(tripleg, 'Dimulai pada:', tripleg.getStartTime(), 'start'),
            '</div>',
            '<div class="col-md-6">',
                this._generateTimepicker(tripleg, 'Berakhir pada:', tripleg.getEndTime(), 'end'),
            '</div>',
          '</div>',
		  '<p>',
				this._getModeSelector(tripleg)
    ];
	var modeId = tripleg.getMode('id');
	if(modeId != 1 && modeId != 7){ //not walking and others
		if(!tripleg.editable()){
			contentHtml.push('<br />');
		}
		contentHtml.push(this._getSecondModeSelector(tripleg));
	}
	contentHtml.push('</p>');
	if(tripleg.getMode2() && modeId != 1){
		contentHtml.push('<p>');
		var tariff = tripleg.getMode2('tariff');
		var toll = tripleg.getMode2('toll');
		var parking = tripleg.getMode2('parking');
		if(tariff){
			contentHtml.push(this._generateCostInput(tripleg, tariff, 'tariff', 'Tarif'));
		}
		if(toll){
			contentHtml.push(this._generateCostInput(tripleg, toll, 'toll', 'Toll'));
		}
		if(parking){
			contentHtml.push(this._generateCostInput(tripleg, parking, 'parking', 'Parkir'));
		}
		contentHtml.push('</p>');
	}
	//contentHtml.push(this._generatePlaceSelector(tripleg));
	
	if(!tripleg.isAlreadyAnnotated()){
		contentHtml.splice( 6, 0, estimateFlag);
	}
    if(tripleg.getParentTrip().editable()){
        contentHtml.push('<p><i><strong>Apakah Anda menggunakan lebih dari satu moda?</strong><br> Pilih/tekan titik koordinat pada peta untuk menambahkan lokasi perpindahan.</i></p>');
    }
    contentHtml.push('</div></div>');
    return contentHtml.join('');
  },

  _generateTimepicker: function(tripleg, label, time, additionalClass) {
    var timepickerHtml = '';
    if(tripleg.editable()) {
      var triplegId = tripleg.getId();
      var classes = [];
      if(tripleg.isFirst) { classes.push('first') }
      if(tripleg.isLast) { classes.push('last') }
	  
	  timepickerHtml = ['<label for="timepickerstart_'+triplegId+'">'+ label +'</label>',
				'<div class="form-group">',
                '<div class="input-group bootstrap-timepicker timepicker date time-picker '+additionalClass+'" >',
                '<input id="timepickerend_'+triplegId+'" value="' + moment(time).format('DD MMM, HH:mm') + '" readonly="true" class="form-control ' + 'input-small ' + classes.join(' ') + '" type="text"><span class="input-group-addon"><i class="glyphicon glyphicon-time"></i></span>',
                '</div></div>'].join('');
    } else {
      timepickerHtml = this._generateViewElement(label, moment(time).format('DD MMM, HH:mm'));
    }
    return timepickerHtml;
  },

  _generateDeleteTriplegButton: function(tripleg) {
    if(tripleg.editable() && !(tripleg.isFirst && tripleg.isLast) && !this.previewMode) {
      return '<li><a class="delete-tripleg" title="Delete tripleg"><span class="glyphicon glyphicon-trash"></span></a></li>';
    }
  },

  _generateMergeTriplegButton: function(tripleg) {
    if(tripleg.editable() && !tripleg.isFirst && !this.previewMode) {
      return '<li><a class="merge-tripleg" title="Merge tripleg"><span class="glyphicon glyphicon-eject"></span></a></li>';
    }
  },

  _generatePlaceSelector: function(tripleg) {
    var places = tripleg.places;
    var label = 'Transferred at';

    if(tripleg.editable() && !this.previewMode) {
      var placeSelector = [];
      if (!tripleg.isLast && places && places.length > 0) {

        var selectorOptions = [];
        var specifyOptionLabel = '(Optional) Specify transfer place';


        for (var i=0; i < places.length; i++) {
          var place = places[i];
          var id = place.osm_id;
          var type = place.type ? ' ('+place.type+')' : '';
          if (id !== undefined) {
            selectorOptions.push('<option value="' + id + '">' + place.name + type + '</option>');
          }
        }

        var maxAccuracy = places[0].accuracy;
        if (maxAccuracy < 50) {
          // Can not preselect for the user
          selectorOptions.unshift('<option value="-1" disabled selected lang="en">' + specifyOptionLabel + '</option>');
        }

        selectorOptions.push('<option value="add_new">Add new ...</option>');

        placeSelector = ['<p lang="en">',
                          '<label for="place-selector">' + label + '</label>',
                          '<div>',
                          '<select class="form-control form-control-inline place-selector transition">',
                            selectorOptions.join(''),
                          '</select></p>',
                          '</div>'];
      }
      return placeSelector.join('');
    } else {
      return this._generateViewElement(label, tripleg.getTransition('name'));
    }
  },

  _generateViewElement: function(label, value) {
    htmlStr = '';
    if(value) {
      htmlStr = '<label style="margin-bottom: 0px" >' + label + '</label><br/>' +
             '<span class="form-control-static">'+ value + '</span>';
    }
    return htmlStr;
  },

    /**
   * Returns the outerHTML of a MODE selector
   * @param mode - an array containing mode ids and their inference confidence
   * @param triplegid - the id of the tripleg with which the modes are associated with
   * @returns {string} - outerHTML of the mode selector
   */
  _getModeSelector: function(tripleg){
    var label = 'Menggunakan Moda:';
    if(tripleg.editable() && !this.previewMode) {
      var mode = tripleg.getMode();
      var maxVal = mode ? mode.accuracy : 0;
      var classes = ' form-control';
      var options = [];

      if(maxVal<50) {
        classes += ' form-value-invalid';
        options.push('<option lang="en" value="-1" disabled selected>Pilih moda transportasi</option>');
      }

      for (var i = 0; i < tripleg.mode.length; i++) {
        var mode = tripleg.mode[i];
        options.push('<option lang="en" value="' + mode.id + '">' + mode.name + '</option>');
      }

      var selector = [
        '<label for="mode-select">' + label + '</label>',
        '<select class="mode-select' + classes + '" name="selectmode">',
          options.join(''),
        '</select>'
      ].join('');

      return selector;
    } else {
      return this._generateViewElement(label, tripleg.getMode('name'));
    }
  },
  
  _getSecondModeSelector: function(tripleg){
    var label = 'Tipe:';
    if(tripleg.editable()) {
      var mode2 = tripleg.getMode2();
      var maxVal = mode2 ? mode2.accuracy : 0;
      var classes = ' form-control';
      var options = [];

      if(maxVal<50) {
        classes += ' form-value-invalid';
        options.push('<option lang="en" value="-1" disabled selected>Pilih tipe moda</option>');
      }

      for (var i = 0; i < tripleg.mode2.length; i++) {
        var mode2 = tripleg.mode2[i];
        options.push('<option lang="en" value="' + mode2.id + '">' + mode2.name + '</option>');
      }

      var selector = [
        '<label for="second-mode-select">' + label + '</label>',
        '<select class="second-mode-select' + classes + '" name="selectsecondmode">',
          options.join(''),
        '</select>'
      ].join('');

      return selector;
    } else {
      return this._generateViewElement(label, tripleg.getMode2('name'));
    }
  },
  
  _generateCostInput: function(tripleg, cost, type, label){
    if(tripleg.editable()) {
	  var costId = type + '-input_'+tripleg.getId();
      var input = [
		'<div class="form-group">','<label for="',costId,'" class="col-sm-2 control-label">',
		(cost.required ? '*':''),label,':</label>',
		'<div class="col-sm-10">',
        '<input id="' + costId +'" pattern="^[\d,]+$" type="text" class="form-control cost-input" '
      ];

	  if(transportCost[costId]){
		  if(transportCost[costId].trim()){
			  input.push('value="'+transportCost[costId]+'" ');
		  } else {
			  if(cost['default']){
				input.push('value="'+cost['default']+'" ');
			  }
		  }
	  } else {
		  if(cost['default']){
			input.push('value="'+cost['default']+'" ');
		  }
	  }
	  if(cost.required){
		  input.push('required ');
	  }
	  if(cost.min){
		  input.push('min="'+cost.min+'" ');
	  } else {
		  input.push('min="0" ');
	  }
	  if(cost.max){
		  input.push('max="'+cost.max+'" ');
	  }
	  if(cost.input == 'auto'){
		  input.push('disabled ');
	  }
	  input.push('/></div></div>');
      return input.join('');
    } else {
		if(tripleg.isAlreadyAnnotated()){
			var htmlStr = '<label>' + label + ':&nbsp;</label>';
			htmlStr += '<span>'+ parseInt(cost).toLocaleString('en-US') + '</span><br />';
			return htmlStr;
		}
		return '';
    }
  },

   getTransitionPanel: function(tripleg) {
    var transitionPanel = [];

    // Not the last trip leg -> generate panel
    // TODO! handle language for mode and the case that there is no mode set
    if (!tripleg.isLast){
      var nextTripleg = tripleg.getNext().getNext();
      if(nextTripleg) {
        var fromMode = tripleg.getMode()  ? ' dari ' + tripleg.getMode().name : '';
        var toMode = nextTripleg.getMode() ? ' ke ' + nextTripleg.getMode().name : '';
		var fromTime = moment(tripleg.getEndTime()).format('DD MMM, HH:mm');
		var toTime = moment(nextTripleg.getStartTime()).format('DD MMM, HH:mm')
		if(fromTime == toTime){
			transitionPanel = [
			  '<li>',
				'<div class="tldate transition-panel" id="tldate' + nextTripleg.getId() + '">',
				  '<p lang="en">'+ fromTime +' - Pindah moda'+ fromMode + toMode +'</p>',
				'</div>',
			  '</li>'];
		} else {
			transitionPanel = [
			  '<li>',
				'<div class="tldate transition-panel" id="tldate' + nextTripleg.getId() + '">',
				  '<p lang="en">'+ fromTime + ' - ' + toTime +' - Pindah moda'+ fromMode + toMode +'</p>',
				'</div>',
			  '</li>'];
		}
      }
    }

    return transitionPanel.join('');
  }
};
