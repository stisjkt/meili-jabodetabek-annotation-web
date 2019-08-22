var tempTimeline;
var max_activities = 3;
var estimateFlag = '<div style="text-align:  right; color: orange; position:  absolute; top: 3px; right: 8px;"><strong><i>(Estimasi)</i></strong></div>';
var transportCost = {};

var Timeline = Timeline || function (options) {
	transportCost = {};
    this.elementId = options.elementId;
    this.previewMode = options.previewMode;
    console.log('previewMode:' + this.previewMode);
    this.days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    this.resize();
    $(window).resize(this.resize.bind(this));

    this._addListeners();

    Emitter(this);
    tempTimeline = this;
    return this;
};

Timeline.prototype = {

    render: function (trip) {
        this.trip = trip;
        this.previewMode = this.getParameterByName("previewMode") === 'true';
        // Reset
        $('#' + this.elementId + ' > ul').html('<div id="vline"></div>');
        this.generateFirstElement();
        var tripLayers = [];
        for (var i = 0; i < this.trip.triplegs.length; i++) {
            var tripleg = this.trip.triplegs[i];
            var triplegPanel = new TriplegPanel(this.elementId, this.trip.getId(), tripleg, this.previewMode);
            // console.log(this.trip);
            // Bind trip specific events on triplegpanel
            triplegPanel.on('start-time-change', this._updateStartTime.bind(this));
            triplegPanel.on('end-time-change', this._updateEndTime.bind(this));
            triplegPanel.on('delete-tripleg', this.trip.deleteTripleg.bind(this.trip));
            triplegPanel.on('merge-tripleg', this.trip.mergeTripleg.bind(this.trip));
            triplegPanel.on('map-zoom-to', function (bounds) {
                this.emit('map-zoom-to', bounds);
            }.bind(this));
            triplegPanel.on('add-new-transportation-poi', function (tripleg) {
                this.emit('add-new-transportation-poi', tripleg);
            }.bind(this));
        }
        this.generateLastElement();
    },

    getParameterByName: function(name) {
        name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
        var regexS = "[\\?&]" + name + "=([^&#]*)";
        var regex = new RegExp(regexS);
        var results = regex.exec(window.location.href);
        if (results == null)
            return "";
        else
            return decodeURIComponent(results[1].replace(/\+/g, " "));
    },

    scrollToTop: function () {
        $('#' + this.elementId).scrollTop(0);
    },

    _updateStartTime: function (tripleg, newStartTime) {
        if (tripleg.isFirst) {
            this.trip.updateStartTime(newStartTime);
        } else {
            this.trip.updateTriplegStartTime(tripleg.getId(), newStartTime);
        }
    },

    _updateEndTime: function (tripleg, newEndTime) {
        if (tripleg.isLast) {
            this.trip.updateEndTime(newEndTime);
        } else {
            this.trip.updateTriplegEndTime(tripleg.getId(), newEndTime);
        }
    },

    _addTime: function (time, hoursMinutes) {
        var hm = hoursMinutes.split(':');
        time.setHours(hm[0]);
        time.setMinutes(hm[1]);
        return time.getTime();
    },

    /**
     * Adds listeners to a timeline element associated with a tripleg and checks for consequences of time change
     * @param tripleg - tripleg
     */
    _addListeners: function (tripId, tripleg) {

        var $element = $('#' + this.elementId);
        
        $element.on('change','input[name="activities"]', function(e){
			 var checked_activities = $('input[name="activities"]:checked');
			 if(e.target.checked && checked_activities.length > max_activities) {
				 e.target.checked = false;
				 e.preventDefault();
			 } else if(e.target.checked){
					if(e.target.value == '0'){
						e.target.checked = false;
						new Confirm().show({
							heading: 'Aktivitas Lainnya',
							question: '<input type="text" class="form-control" placeholder="Nama aktivitas.." id="other_activity"/>'+
									  '<div id="result"></div>',
							okButtonTxt: 'Ok',
							cancelButtonTxt: 'Batal'
						  },
						  function($element) {
							var otherActivity = $element.find('#other_activity').val();
							if (otherActivity){
								this.trip.setNewActivityName(otherActivity);
								e.target.checked = true;
								$('#other_activity_label').text("Lainnya: " + this.trip.getNewActivity('name'));
								$('#badge_activity-0').html(checked_activities.length + 1);
								$('#badge_activity-0').show();
								this.trip.setSelectedActivities([0]);
							} else {
							  swal("Error!", "Nama lokasi harus diisi!", "error");
							} 
						  }.bind(this));
					} else {
						$('#badge_activity-'+e.target.value).html(checked_activities.length);
						$('#badge_activity-'+e.target.value).show();
					}
			 } else {
				 $('#badge_activity-'+e.target.value).hide();
				 var removedPriority = Number($('#badge_activity-'+e.target.value).html());
				 for(var i in checked_activities){
					 var priority = Number($('#badge_activity-'+checked_activities[i].value).html());
					 if(priority > removedPriority){
						$('#badge_activity-'+checked_activities[i].value).html(priority-1);
					}
				 }
				 $('#badge_activity-'+e.target.value).html('');
			 }
			var activityIds = [-1,-1,-1];
			checked_activities = $('input[name="activities"]:checked');
			for (var i in checked_activities) {
				if(checked_activities[i].checked){
					var priority = Number($('#badge_activity-'+checked_activities[i].value).html());
					var actId = Number(checked_activities[i].value);
					activityIds[priority-1] = actId;
				}
			}
			this.trip.setSelectedActivities(activityIds);
        }.bind(this));

        $element.on('change', '.place-selector.destination', function (e) {
            if (e.target.value) {
                if (e.target.value === 'add_new') {
                   this.emit('add-new-destination', this);
                } else {
					this.trip.updateDestinationPoiIdOfTrip(e.target.value);
                }
            }
        }.bind(this));

        $element.on('click', '.btn-trip-selector', function (e) {
            console.log(e);
            loadingOverlay();
            // tripNavDirection = -1;
            this.emit('navigate-to-trip', this.data());
            closeNav();
            e.preventDefault();
            return false;
        }.bind(this));

        $element.on('click', '.go-to-previous-trip', function (e) {
            console.log(e);
            loadingOverlay();
            tripNavDirection = -1;
            this.emit('move-to-previous-trip', this.trip);
            closeNav();
            e.preventDefault();
            return false;
        }.bind(this));

        $element.on('click', '.go-to-next-trip', function (e) {
            if (this.trip.isAlreadyAnnotated()) {
                loadingOverlay();
				tripNavDirection = 1;
                this.emit('move-to-next-trip', this.trip);
                closeNav();
            } else {
                var safeToMoveToNext = true;
                var errorDisplayMessage = '';
				
				//chek triplegs cost validity
				for (var i = 0; i < this.trip.triplegs.length && safeToMoveToNext; i++) {
					var tripleg = this.trip.triplegs[i];
					if (tripleg.getType() == 1){
						var tariffInput = $('#tariff-input_' + tripleg.getId());
						if(tariffInput.length > 0){
							if(tariffInput.prop('required') && tariffInput.val().trim()==''){
								safeToMoveToNext = false;
								errorDisplayMessage += ((errorDisplayMessage.length != 0) ? ', ' : ' ') + '<strong>Tarif</strong>';
							}
						}
						var tollInput = $('#toll-input_' + tripleg.getId());
						if(tollInput.length > 0){
							if(tollInput.prop('required') && tollInput.val().trim()==''){
								safeToMoveToNext = false;
								errorDisplayMessage += ((errorDisplayMessage.length != 0) ? ', ' : ' ') + '<strong>Toll</strong>';
							}
						}
						var parkingInput = $('#parking-input_' + tripleg.getId());
						if(parkingInput.length > 0){
							if(parkingInput.prop('required') && parkingInput.val().trim()==''){
								safeToMoveToNext = false;
								errorDisplayMessage += ((errorDisplayMessage.length != 0) ? ', ' : ' ') + '<strong>Parkir</strong>';
							}
						}
					}
				}
				
                var selectedActivityIds = this.trip.getSelectedActivityIds();
                if (selectedActivityIds.length == 0) {
                    safeToMoveToNext = false;
					errorDisplayMessage += ((errorDisplayMessage.length != 0) ? ', ' : ' ') + '<strong>Aktivitas</strong>';
                }

                var destinationTrip = $("#destination-selector").val();
                console.log("timeline <- id destination = ", destinationTrip);
                if (destinationTrip !== "add_new") {
                    if (destinationTrip !== -1) {
                        this.trip.updateDestinationPoiIdOfTrip(destinationTrip);
                    } else {
                        safeToMoveToNext = false;
                        errorDisplayMessage += ((errorDisplayMessage.length != 0) ? ', ' : ' ') + '<strong>Tujuan Perjalanan</strong>';
                    }
                } else {
                    safeToMoveToNext = false;
                    errorDisplayMessage += ((errorDisplayMessage.length != 0) ? ', ' : ' ') + '<strong>Tujuan Perjalanan</strong>';
                }
				
                if (this.trip.getNewActivity('selected_order') > -1 && this.trip.getNewActivity('name').trim() == "") {
                  safeToMoveToNext = false;
                  errorDisplayMessage += ((errorDisplayMessage.length != 0) ? ', ' : ' ') + '<strong>Aktivitas Lainnya</strong>';
                }

                var allTriplegsOk = true;
                for (var j = 0; j < this.trip.triplegs.length; j++) {
                    var tripleg = this.trip.triplegs[j];
                    if (tripleg.getType() == 1 && !tripleg.getMode() || (tripleg.getMode() && tripleg.getMode().accuracy < 50)) {
                        safeToMoveToNext = false;
                        allTriplegsOk = false;
                    }
					if (tripleg.getType() == 1 && !tripleg.getMode2() || (tripleg.getMode2() && tripleg.getMode2().accuracy < 50)) {
                        safeToMoveToNext = false;
                        allTriplegsOk = false;
                    }
                }

                if (!allTriplegsOk)
                    errorDisplayMessage += ((errorDisplayMessage.length != 0) ? ', ' : ' ') + '<strong>Moda Perjalanan</strong>';

                errorDisplayMessage = 'Silakan melengkapi:' + errorDisplayMessage;
                if (safeToMoveToNext){
                    var jc;
                    var trip = this.trip;
                    $.confirm({
                        columnClass: "medium",
                        title: 'Apakah ingin melanjutkan anotasi ke perjalanan berikutnya?',
                        content: function() {
                            var self = this;
                            return trip.getReportTypes().done(function(response) {
                                var content = '<form action="" class="formName">' +
                                '<div class="form-check center">'+
                                '<input type="checkbox" class="form-check-input" id="has-report">'+
                                '<label class="form-check-label" for="has-report">Tambahkan Laporan pada Perjalanan Ini </label>'+
                                '</div>'+
                                '<div class="form-group" id="report-form">' +
                                '<label>Laporan kesalahan</label>' +
                                '<select class="form-control report-type">'+
                                '<option value="0">Pilih Kategori Laporan</option>';

                                $.each(response, function(i, obj) {
                                    content += '<option value="'+obj.id+'">'+obj.name+'</option>';
                                });

                                content += '</select>' +
                                '</br>' +
                                '<textarea class="form-control report-content" rows="5" placeholder="Tuliskan laporan kesalahan" name="report-content"></textarea>' +
                                '</div>' +
                                '</form>';
                                self.setContent(content);
                            }.bind(this))

                        },
                        buttons: {
                            formSubmit: {
                                text: 'Lanjutkan',
                                btnClass: 'btn-blue',
                                action: function () {
                                    reportContent = jc.$content.find('.report-content').val();
                                    reportType = jc.$content.find('.report-type').val();
                                    console.log(reportContent+" "+reportType);
                                    this.trip.setReport(reportType, reportContent)
                                    this.trip.confirm();
                                    loadingOverlay();
                                    closeNav();
                                }.bind(this)
                            },

                            cancel: function () {
                                
                            },
                        },
                        onContentReady: function () {
                            // bind to events
                            $("#report-form").hide()    ;
                            $("#has-report").on('click', function(){
                                $("#report-form").toggle();
                            });
                            jc = this;
                            this.$content.find('form').on('submit', function (e) {
                                // if the user submits the form by pressing enter in the field.
                                e.preventDefault();
                                jc.$$formSubmit.trigger('click'); // reference the button and click it
                            });
                        }
                    });
                    // new Confirm().show({
                    //     heading: 'Anda telah selesai melakukan anotasi untuk perjalanan ini',
                    //     question: 'Apakah ingin melanjutkan anotasi ke perjalanan berikutnya?',
					// 	okButtonTxt: 'Ya',
					// 	cancelButtonTxt: 'Tidak'
                    // }, function () {
                    //     this.trip.confirm();
                    //     loadingOverlay();
                    //     closeNav();
                    // }.bind(this));
                } else new Confirm().show({
                    heading: 'Informasi perjalanan yang Anda masukkan belum lengkap',
                    question: errorDisplayMessage,
                    type: 'error',
					okButtonTxt: 'Tutup'
                }, function () {
                }.bind(this));
            }
            e.preventDefault();
            return false;
        }.bind(this));

        $element.on('click', '.preview-next-trip', function (e) {
            loadingOverlay();
            tripNavDirection = 1;
            this.emit('move-preview-next-trip', this.trip);
            closeNav();
            e.preventDefault();
            return false;
        }.bind(this));

        $element.on('click', '.preview-prev-trip', function (e) {
            loadingOverlay();
            tripNavDirection = -1;
            this.emit('move-preview-prev-trip', this.trip);
            closeNav();
            e.preventDefault();
            return false;
        }.bind(this));

        $element.on('click', '.undo-last-annotation', function (e) {
            new Confirm().show({
                heading: 'Batalkan Anotasi terkahir',
                question: 'Apakah Anda yakin ingin membatalkan anotasi terakhir?',
				okButtonTxt: 'Ya',
				cancelButtonTxt: 'Tidak'
            }, function () {
                this.emit('undo-last-annotation', this.trip);
            }.bind(this));
            e.preventDefault();
            return false;
        }.bind(this));

        $element.on('click', '.delete-trip', function (e) {
            new Confirm().show({
                heading: 'Hapus Perjalanan',
                question: 'Apakah Anda yakin ingin menghapus perjalanan ini?',
				okButtonTxt: 'Ya',
				cancelButtonTxt: 'Tidak'
            }, function () {
                this.emit('delete-trip', this.trip);
            }.bind(this));
            e.preventDefault();
            return false;
        }.bind(this));


        $element.on('click', '.merge-with-next-trip', function (e) {
            new Confirm().show({
                heading: 'Menggabungkan Perjalanan',
                question: 'Apakah Anda yakin ingin menggabungkan dengan perjalanan selanjutnya?',
				okButtonTxt: 'Ya',
				cancelButtonTxt: 'Tidak'
            }, function () {
                this.emit('merge-trip', this.trip);
            }.bind(this));
            e.preventDefault();
            return false;
        }.bind(this));

    },

    /**
     * Generates the first timeline element and adds it at the head of the timeline
     */
    generateFirstElement: function () {
        var ul = $('#' + this.elementId + ' > ul');

        var previousActivities = this.trip.getPreviousTripActivities();
        var previousPlace = this.trip.getPreviousTripPOIName();
        var currentTripStartDate = this.trip.getStartTime();

        if (!this.trip.isFirst()) {
            /* Add see previous button */
            var navigateToPreviousTrip = [
                '<li>',
                '<div class="tldatecontrol go-to-previous-trip" id="seePrevious">',
                '<a id="prev_trip_button" class="go-to-previous-trip" href="#" lang="en"><i class="glyphicon medium glyphicon-arrow-left"></i> Lihat Perjalanan Sebelumnya</a>',
                '</div>',
                '</li>'
            ];
            
            
            /* Add see previous button for unannotated trip */
            var previewPreviousTrip = [
                '<li>',
                '<div class="tldatecontrol preview-prev-trip" id="previewPrevious">',
                '<a id="prev_trip_button" class="preview-prev-trip" href="#" lang="en"><i class="glyphicon medium glyphicon-arrow-left"></i> Lihat Perjalanan Sebelumnya</a>',
                '</div>',
                '</li>'
            ];

            if(this.trip.isAlreadyAnnotated() || (this.trip.getPreviousTripActivities() != null)) {
                ul.append(navigateToPreviousTrip.join(''));
            } else {
                ul.append(previewPreviousTrip.join(''));
            }

            var previousTripEndDateLocal = moment(this.trip.getPreviousTripEndTime()).format('dddd, DD MMMM YYYY');

            /* Add previous trip ended panel*/
            var previousTripPanel = [
                '<li>',
                '<div class="tldate previous" style="width:330px"> <p lang="en">Perjalanan sebelumnya berakhir pada</br>Pukul <strong>' + this.trip.getPreviousTripEndTime(true) + '</strong> (' + previousTripEndDateLocal + ')</p>',
                '</div>',
                '</li>'
            ];
            ul.append(previousTripPanel.join(''));

            /* Add previous trip summary */
            var previousTripSummaryPanel = [
                '<li class="timeline-inverted">',
                '<div class="timeline-panel previous">',
                '<div class="tl-heading">',
                '<strong>Resume Lokasi Sebelumnya</strong>',
                '</div>',
                '<div class="tl-body">',
                '<div id="tldatefirstparagraph">',
                '<small class="text-muted">',
                '<i class="glyphicon glyphicon-time"></i> ' + moment(this.trip.getPreviousTripEndTime()).format('DD MMM, HH:mm') 
				+ ' - ' + moment(this.trip.getStartTime()).format('DD MMM, HH:mm') + ', ' + this.trip.getTimeDiffToPreviousTrip() + ' sebelum perjalanan ini',
                '</small>',
                '</div>'
            ];
			if(!previousActivities){
				previousTripSummaryPanel.splice( 2, 0, estimateFlag);
			}
            if(previousPlace){
                previousTripSummaryPanel.push('<div lang="en">Tempat: ' + previousPlace + '</div>');
            }
            if(previousActivities){
                previousTripSummaryPanel.push('<div lang="en">Aktivitas: ' + previousActivities + '</div>');
            }
            previousTripSummaryPanel.push('</div></div></li>');
            ul.append(previousTripSummaryPanel.join(''));
        } else {
            var firstTimePanel = [
                '<li>',
                '<div class="tldate init" id="firstTimelinePanel">',
                '<p lang="en">Anda memulai menggunakan Aplikasi disini</p>',
                '</div>',
                '</li>'
            ];
            if (this.trip.isFirst()) {
                ul.append(firstTimePanel.join(''));
            }
        }

        /* Add started trip info */
        var currentTripStartDateLocal = moment(currentTripStartDate).format('dddd') + ", " + moment(currentTripStartDate).format("DD MMMM YYYY");
        var currentTripStartHour = moment(currentTripStartDate).format("hh:ss");

        var tripStartPanel = [
            '<li>',
            '<div class="tldate start row" id="tldatefirst">',
            '<div class="col-md-1">',
            '<span class="glyphicon glyphicon-flag large"></span>',
            '</div>',
            '<div class="col-md-7">',
            '<span class="important-time">' + this.trip.getStartTime(true) + '</span> <small>(' + currentTripStartDateLocal + ')</small> - <strong>Perjalanan Dimulai</strong>',
            '</div>',
            '<div class="col-md-4 controls">',
            this._generateDeleteTripButton(this.trip),
            '</div>',
            '</div>',
            '</li>'
        ];

        ul.append(tripStartPanel.join(''));
    },

    _generateDeleteTripButton: function (trip) {
        if (trip.editable()) {
            return '<button class="delete-trip btn btn-default" lang="en" style="white-space: normal"><span class="glyphicon glyphicon-trash"></span> Hapus Perjalanan</button>';
        } else {
            return '';
        }
    },

    _generateMergeTripsButton: function (trip) {
        console.log("from merge button editable:" + trip.editable());
        if (trip.editable() && this.trip.getNextTripStartTime() && this.trip.getNextTripStartTime() !== null && !this.previewMode) {
            
            return '<button class="merge-with-next-trip btn btn-default" lang="en"  style="white-space: normal">Gabungkan dengan</br>Perjalanan Selanjutnya <span class="glyphicon glyphicon-share-alt"></span></button>';
        } else {
            return '';
        }
    },

    _generateViewElement: function (label, value) {
        htmlStr = '';
        if (value) {
            htmlStr = '<label>' + label + '</label>' +
                '<p class="form-control-static">' + value + '</p>';
        }
        return htmlStr;
    },

    /**
     * Generates the last timeline element and adds it at the tail of the timeline
     */
    generateLastElement: function () {
        var ul = $('#' + this.elementId + ' > ul');

        var currentTripEnd = this.trip.getEndTime();
        var currentTripEndDateLocal = moment(currentTripEnd).format('dddd') + ", " + moment(currentTripEnd).format("DD MMMM YYYY");

        var lastTimelineElement = [
            '<li>',
            '<div class="tldate end row" id="tldatelast">',
            '<div class="col-md-1">',
            '<span class="glyphicon glyphicon-flag large"></span>',
            '</div>',
            '<div class="col-md-7">',
            '<span class="important-time">' + this.trip.getEndTime(true) + '</span> <small>(' + currentTripEndDateLocal + ')</small> - <strong>Perjalanan Berakhir</strong>',
            '</div>',
            '<div class="col-md-4 controls">',
            this._generateMergeTripsButton(this.trip),
            '</div>',
            '</div>',
            '</li>',
            '<button id="dummy-goto-button" class="nav-goto hidden-lg hidden-md" style="display=none;"></button>'
        ];

        ul.append(lastTimelineElement.join(''));


        // Add ended trip info
        // TODO! move into separate method
        var displayTripEndTime = moment(this.trip.getEndTime()).format('DD MMM, HH:mm');
        if (this.trip.getNextTripStartTime() && this.trip.getNextTripStartTime() !== null) {
            // Add previous trip ended panel
            displayTripEndTime += ' - ' + moment(this.trip.getNextTripStartTime()).format('DD MMM, HH:mm');
        }

        var lastTripControl = [
            '<li class="timeline-inverted">',
            '<div class="timeline-panel" id="lastTimelinePanel">',
            '<div class="tl-heading">',
            '<h4 lang="en">Akhir dari Perjalanan</h4>',
            '<p id="tldatelastparagraph">',
            '</p>',
            '</div>',
            '<div class="tl-body">',
            this.generateDestinationPlaceSelector(this.trip),
            this.generateActivitiesSelector(this.trip),
            '</div>',
            '</div>',
            '</li>'
        ];
		
		if(this.trip.getTimeDiffToNextTrip() == null) {
			lastTripControl.splice( 5, 0, '<small class="text-muted"><i class="glyphicon glyphicon-time"></i> ' + displayTripEndTime + '</small>');
		} else {
			lastTripControl.splice( 5, 0, '<small class="text-muted"><i class="glyphicon glyphicon-time"></i> ' + displayTripEndTime + ', ' + this.trip.getTimeDiffToNextTrip() + ' sampai perjalanan selanjutnya</small>');
		}
		
		if(!this.trip.isAlreadyAnnotated()){
			lastTripControl.splice( 2, 0, estimateFlag);
		}

        ul.append(lastTripControl.join(''));


        // Navigation to next trip
        // TODO! move into separate method
        /* Add process next trip */
        var navigateToNextTrip = [
            '<li id="processNext">',
            '<div class="tldatecontrol go-to-next-trip">'
        ];
        if (this.trip.editable()) {
            navigateToNextTrip.push('<a class="go-to-next-trip" href="#" lang="en">');
            navigateToNextTrip.push('<i class="glyphicon medium glyphicon-floppy-disk"></i> Simpan</a>');
        } else {
            navigateToNextTrip.push('<a id="next_trip_button" class="go-to-next-trip" href="#" lang="en">');
            navigateToNextTrip.push('Lihat Perjalanan Selanjutnya<i class="glyphicon medium glyphicon-arrow-right"></i></a>');
        }
        navigateToNextTrip.push('</div></li>');
        
        if (this.trip.isAlreadyAnnotated() || this.trip.editable()) {
            ul.append(navigateToNextTrip.join(''));
        }

        if (!this.trip.isAlreadyAnnotated()) {
            /* Add preview next trip */
            navigatePreviewNextTrip = [
                '<li id="previewNext">',
                '<div class="tldatecontrol preview-next-trip">',
                '<a id="next_trip_button" class="preview-next-trip" href="#" lang="en">Lihat Perjalanan Selanjutnya <i class="glyphicon medium glyphicon-arrow-right"></i> </a>',
                '</div>',
                '</li>'
            ];
            ul.append(navigatePreviewNextTrip.join(''));
        }

        if ((this.trip.editable() && !this.trip.isFirst()) || (!this.previewMode && this.trip.isAlreadyAnnotated() && !this.trip.getNextTripStartTime())) {
            console.log("from undo, previewMode:" + this.previewMode)
            var undoLastAnnotation = [
                '<li>',
                '<div class="tldatecontrol undo-last-annotation" id="undoLast">',
                '<a class="undo-last-annotation" href="#" lang="en"><i class="b glyphicon medium glyphicon-trash"></i> Batalkan Anotasi Terakhir</a>',
                '</div>',
                '</li>'
            ];
            ul.append(undoLastAnnotation.join(''));
        }

    },

    /**
     * Generates a selector for the places (for destination) associated to a trip
     * @param places - array of places (lat, lon) that have accuracy of inference embedded
     * @returns {string|string} - outerHTML of the place selector
     */
    generateDestinationPlaceSelector: function (trip) {
        var elementHtml = '';
        var label = 'Lokasi Tujuan:';
        var places = trip.getPlaces();
        if (places && $.isArray(places)) {
            if (trip.editable()) {
                var placeSelector = [];
                var selectorOptions = [];
                var specifyOptionLabel = 'Inputkan lokasi tujuan';
                var classes = '';

                if (places.length > 0) {
                    for (var i = 0; i < places.length; i++) {
                        var place = places[i];
                        var id = place.gid;
                        var type = place.type ? ' (' + place.type + ')' : '';
                        if (id !== undefined) {
                            if (i == 0) {
                                selectorOptions.push('<option value="' + id + '" selected>' + place.name + type + '</option>');
                            } else {
                                selectorOptions.push('<option value="' + id + '">' + place.name + type + '</option>');
                            }
                        }
                    }
                } else {
                    if (places.length == 0) {
                        classes = ' form-value-invalid';
                        selectorOptions.unshift('<option value="-1" disabled selected lang="en">' + specifyOptionLabel + '</option>');
                    }
                }
				
                selectorOptions.push('<option  value="add_new">(Tambah lokasi baru...)</option>');

                placeSelector = ['<p lang="en">',
                    '<label for="destination-selector">' + label + '</label>',
                    '<select id="destination-selector" class="form-control form-control-inline place-selector destination' + classes + '">',
                    selectorOptions.join(''),
                    '</select></p>'
                ];
                elementHtml = placeSelector.join('');
            } else if (trip.isAlreadyAnnotated()){
				elementHtml = this._generateViewElement(label, trip.getDestinationPlace('name'));
            } else {
				var dest = trip.getDestinationPlace('name');
				if(dest){
					elementHtml = this._generateViewElement(label, trip.getDestinationPlace('name'));
				}
			}
        }
        return elementHtml;
    },

    /**
     * Generates a selector for the purposes associated with a trip
     * @param purposes - an array of purposes and their inference certainty
     * @returns {string|string} outerHTML of the purpose selector
     */
    generateActivitiesSelector: function (trip) {
        var elementHtml = '';
        var label = 'Aktivitas:';
        var activities = trip.getActivities();
        if (activities && activities.length > 0) {
            if (trip.editable()) {
                var activityOptions = [];
                var classes = '';
                for (var i = 0; i < activities.length; i++) {
                    var activity = activities[i];
                    activityOptions.push('<div>' +
                          '<label>' + 
                          '<input type="checkbox" name="activities" value="' 
                          + activity.id + '" '+ (activity.selected_order > -1 ? 'checked':'')
                          +' lang="en" style="margin-bottom: 10px;"/> ' + 
                          '<span id="badge_activity-'+activity.id+'" class="badge badge-primary" '
                          + (activity.selected_order > -1 ? '':'style="display:none;"') +' >'
                          + (activity.selected_order > -1 ? activity.selected_order+1:'') + '</span>' +
                          activity.name + '</label><br /></div>');
                }
				//aktifitas lainnya
                activityOptions.push('<div>' +
                    '<label>' + 
                    '<input type="checkbox" name="activities" value ="0" lang="en" style="margin-bottom: 10px;" '
					+ (trip.getNewActivity('selected_order') > -1 ? 'checked':'') + ' /> ' +
                    '<span id="badge_activity-0" class="badge badge-primary" '
                    + (trip.getNewActivity('selected_order') > -1 ? '':'style="display:none;"') +' >'
                    + (trip.getNewActivity('selected_order') > -1 ? trip.getNewActivity('selected_order')+1:'') +'</span><span id="other_activity_label">' 
					+ (trip.getNewActivity('selected_order') > -1 ? "Lainnya: " + trip.getNewActivity('name'):'(Lainnya, sebutkan...)')
                    + '</span></label><br /></div>');

                var activitySelector = '<div><p lang="en">' +
                    '<label for="purpose-selector">' + label + ' <i>(pilih maks. 3)</i></label>'+
                    '<div id="radioContainer" class="form-control form-control-inline form-need-check purpose-selector ' + classes + '" style="display: block; overflow-y: auto; height: 130px;">' +
                    activityOptions.join('')+
                    '</div>' +
                    '</p>';
                elementHtml = activitySelector;
            } else if (trip.isAlreadyAnnotated()){
				var estimatedActivities = trip.getEstimatedActivities('name');
                var activities = '';
                for(var i in estimatedActivities){
                    activities += estimatedActivities[i] + '<br />';
                }
                elementHtml = this._generateViewElement(label, activities);
			} else {
                var estimatedActivities = trip.getEstimatedActivities('name');
                var activities = '';
                for(var i in estimatedActivities){
                    activities += estimatedActivities[i] + '<br />';
                }
                elementHtml = this._generateViewElement(label, activities);
            }
        }
        return elementHtml;
    },

    resize: function () {
        $('#' + this.elementId).height($('#content').height() + 'px');
    },

    previewPreviousTripMobility : function() {
        $('#prev_trip_button').click();
    },

    previewNextTripMobility : function () { 
        $('#next_trip_button').click();
    }

};
