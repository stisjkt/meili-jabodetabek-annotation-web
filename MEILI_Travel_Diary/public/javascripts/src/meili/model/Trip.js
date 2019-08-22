
var util = Util();

var Trip = Trip || function(trip, triplegs) {
  Emitter($.extend(this, trip));

  if(triplegs) {
    this.updateTriplegs(triplegs);
  }
  if(!this.newActivity) {
      this.newActivity = {
          id:0,
          name:'',
          selected_order:-1
      };
  }


  this.reportType=0;
  this.reportContent="";

  // Make sure activities is sorted at init
  if(this.activities) {
    this._sortActivities();
    //this._checkIfActivitiesIsAccurateAndSyncToServer();
  }
  // Make sure places is sorted at init and that it is an array
  
  if(this.destination_places && $.isArray(this.destination_places)) {
    this._sortDestinationPlaces();
    this._checkIfDestinationIsAccurateAndSyncToServer();
  } else {
    this.destination_places = [];
  }

  return this;
};

Trip.prototype = {

  // Getters
  // -------------------------------------------
  // -------------------------------------------

  getId: function() {
    return this.trip_id;
  },

  isAlreadyAnnotated: function() {
    return this.status === 'already_annotated';
  },

  isFirst: function() {
    return this.previous_trip_end_date == 0 || this.previous_trip_end_date == null;
  },

  editable: function() {
	  
    if (util.isPreviewMode()) {
	  return false;
    } else if (!this.isAlreadyAnnotated()){
		if(this.isFirst()){
			return true;
		} else {
			if(this.previous_trip_activities){
				return true;
			}
		}
		return false;
    } else {
		return false;
	}
  },

  getActivities: function() {
    return this.activities;
  },

  getPlaces: function() {
    return this.destination_places;
  },

  getDestinationPlace: function(property) {
    var place = null;
    if(this.destination_places && this.destination_places.length > 0 && this.destination_places[0].accuracy > 50) {
      place = this.destination_places[0];
      if(property) {
        place = place[property] || null;
      }
    }
    return place;
  },

  getEstimatedActivities: function(property) {
    var estimatedActivities = [];
    if(this.activities && this.activities.length > 0) {
        //take top 3
        if(this.activities[0].accuracy > 50 && this.activities[0].accuracy <= 100){
            estimatedActivities.push(this.activities[0]);
            if(property) {
                estimatedActivities[0] = estimatedActivities[0][property] || null;
            }
        }
		if(this.activities.length > 1){
			if(this.activities[1].accuracy > 50 && this.activities[1].accuracy <= 100){
				estimatedActivities.push(this.activities[1]);
				if(property) {
					estimatedActivities[1] = estimatedActivities[1][property] || null;
				}
			}
		}
		if(this.activities.length > 2){
			if(this.activities[2].accuracy > 50 && this.activities[2].accuracy <= 100){
				estimatedActivities.push(this.activities[2]);
				if(property) {
					estimatedActivities[2] = estimatedActivities[2][property] || null;
				}
			}
		}
    }
    return estimatedActivities;
  },

  getFirstTripleg: function() {
    var tripleg;
    if(this.triplegs && this.triplegs.length > 0) {
      tripleg = this.triplegs[0];
    }
    return tripleg;
  },

  getLastTripleg: function() {
    var tripleg;
    if(this.triplegs && this.triplegs.length > 0) {
      tripleg = this.triplegs[this.triplegs.length-1];
    }
    return tripleg;
  },

  getTriplegById: function(triplegId) {
    return this._getTripleg(triplegId);
  },

  getPrevTripleg: function(tripleg) {
    return this._getTripleg(tripleg.triplegid, -2);
  },

  getNextTripleg: function(tripleg) {
    return this._getTripleg(tripleg.triplegid, +2);
  },

  getPrevPassiveTripleg: function(tripleg) {
    return this._getTripleg(tripleg.triplegid, -1);
  },

  getNextPassiveTripleg: function(tripleg) {
    return this._getTripleg(tripleg.triplegid, +1);
  },

  getStartTime: function(formatted) {
    return util.formatTime(this.current_trip_start_date, formatted ? CONFIG.default_time_format : false);
  },

  getEndTime: function(formatted) {
    return util.formatTime(this.current_trip_end_date, formatted ? CONFIG.default_time_format : false);
  },

  getNextTripStartTime: function(formatted) {
    return util.formatTime(this.next_trip_start_date, formatted ? CONFIG.default_time_format : false);
  },

  getPreviousTripEndTime: function(formatted) {
    return util.formatTime(this.previous_trip_end_date, formatted ? CONFIG.default_time_format : false);
  },

  getPreviousTripPOIName: function() {
    return this.previous_trip_poi_name;
  },

  getPreviousTripActivities: function() {
    return this.previous_trip_activities;
  },

  getTimeDiffToPreviousTrip: function() {
	var diffTime = null;
    if(this.getPreviousTripEndTime()) {
	  diffTime = '';
      var msec = Math.abs(this.getStartTime().getTime() - this.getPreviousTripEndTime().getTime());
	  var hh = Math.floor(msec / 1000 / 60 / 60);
	  msec -= hh * 1000 * 60 * 60;
	  var mm = Math.floor(msec / 1000 / 60);
	  if(hh > 0){
		diffTime += hh + ' jam ';
	  }
	  if(mm > 0){
		diffTime += mm + ' menit ';
	  }
	  if(diffTime == ''){
		diffTime = 'kurang dari 1 menit ';
	  }
    }
	return diffTime;
  },

  getTimeDiffToNextTrip: function() {
	var diffTime = null;
    if(this.getNextTripStartTime()) {
	  diffTime = '';
      var msec = Math.abs(this.getNextTripStartTime().getTime() - this.getEndTime().getTime());
	  var hh = Math.floor(msec / 1000 / 60 / 60);
	  msec -= hh * 1000 * 60 * 60;
	  var mm = Math.floor(msec / 1000 / 60);
	  if(hh > 0){
		diffTime += hh + ' jam ';
	  }
	  if(mm > 0){
		diffTime += mm + ' menit ';
	  }
	  if(diffTime == ''){
		diffTime = 'kurang dari 1 menit ';
	  }
    }
	return diffTime;
  },

  generatePlacePoints: function() {
    var placesPoints = [];
    if(this.destination_places && this.destination_places.length > 0) {
      for (var i = 0; i < this.destination_places.length; i++) {
        var place = this.destination_places[i];
        if(place.accuracy === 100) {
          var marker = L.marker([place.latitude, place.longitude]);
          marker.bindTooltip(place.name);
          placesPoints.push(marker);
          break;
        }
      }
    }
    return L.featureGroup(placesPoints)
  },

  generateMapLayer: function() {
    this.mapLayer = L.featureGroup();

    // Trip points
    this.mapLayer.addLayer(this.generatePlacePoints());

    // Triplegs
    for (var i=0; i < this.triplegs.length; i++) {
      var tripleg = this.triplegs[i];
      var triplegLayer = tripleg.generateMapLayer();
      this.mapLayer.addLayer(triplegLayer);
    }
    return this.mapLayer;
  },

  confirm: function() {
    this.emit('trip-confirm', this);
  },

  // Local changes on trip
  // -------------------------------------------
  // -------------------------------------------

  updateTriplegs: function(newTriplegs) {
    if(newTriplegs && newTriplegs.length > 0) {
      this.removeTriplegs();

      newTriplegs[0].isFirst = true;
      newTriplegs[newTriplegs.length-1].isLast = true;

      for (var i = 0; i < (newTriplegs.length+1); i++) {
        if(newTriplegs[i]) {
            newTriplegs[i].trip = this;
          newTriplegs[i] = new Tripleg(newTriplegs[i]);
          newTriplegs[i].status = this.status;
          log.debug('Trip -> updateTriplegs', 'tripleg updated', newTriplegs[i].getId());
          newTriplegs[i].off('tripleg-updated').on('tripleg-updated', function() { this.emit('triplegs-update', this); }.bind(this));
        }
        // Add reference to next and previous tripleg
        if(i-1 >= 0) {
          newTriplegs[i-1].setPrevNext(newTriplegs[i-2], newTriplegs[i]);
        }
      };
      this.triplegs = newTriplegs;
      log.info('Trip -> updateTriplegs', 'triplegsupdated for trip', this.getId());
      this.emit('triplegs-update', this);
    }
    return this.triplegs;
  },

  removeTriplegs: function() {
    this._reset
    log.debug('Trip -> removeTriplegs', 'removed for trip', this.getId());
    this.emit('triplegs-remove', this);
    this.triplegs = [];
    return this;
  },
  // Add a destination place to trips local destination_places array
  addDestinationPlace: function(id, name, point) {
    if(this.destination_places === null || typeof this.destination_places === 'undefined') {
      this.destination_places = [];
    }
    this.destination_places.push({
      gid: id,
      accuracy: 100,
      added_by_user: true,
      name: name,
      latitude: point.lat,
      longitude: point.lng
    });
  },

  // API connected
  // -------------------------------------------
  // -------------------------------------------

  updateStartTime: function(newTime) {
    var dfd = $.Deferred();
    api.trips.updateStartTime(this.getId(), newTime)
      .done(function(result) {
        this.updateTriplegs(result.triplegs);
        // TODO! potentially bad to update trip state here, should the server do this?
        this.current_trip_start_date = result.triplegs[0].start_time;

        dfd.resolve(this);
      }.bind(this))
      .fail(function(err) {
        log.error('Trip -> updateStartTime', err);
        dfd.reject(err);
      });

    return dfd.promise();
  },

  updateEndTime: function(newTime) {
    var dfd = $.Deferred();
    api.trips.updateEndTime(this.getId(), newTime)
      .done(function(result) {
          this.updateTriplegs(result.triplegs);
          // TODO! potentially bad to update trip state here, should the server do this?
          this.current_trip_end_date = result.triplegs[result.triplegs.length-1].stop_time;

          dfd.resolve(this);
      }.bind(this))
      .fail(function(err) {
        log.error('Trip -> updateEndTime', err);
        dfd.reject(err);
      });

    return dfd.promise();
  },

  // This is on a trip since a time change could result in multiple triplegs being affected
  // and current tiplegs state is returned
  updateTriplegStartTime: function(triplegId, newTime) {
    var dfd = $.Deferred();
    api.triplegs.updateStartTime(triplegId, newTime)
      .done(function(result) {
        this.updateTriplegs(result.triplegs);
        dfd.resolve(this);
      }.bind(this))
      .fail(function(err) {
        log.error('Trip -> updateTriplegStartTime', err);
        dfd.reject(err);
      });

    return dfd.promise();
  },

  // This is on a trip since a time change could result in multiple triplegs being affected
  // and current tiplegs state is returned
  updateTriplegEndTime: function(triplegId, newTime) {
    var dfd = $.Deferred();
    api.triplegs.updateEndTime(triplegId, newTime)
      .done(function(result) {
        this.updateTriplegs(result.triplegs);
        dfd.resolve(this);
      }.bind(this))
      .fail(function(err) {
        log.error('Trip -> updateTriplegEndTime', err);
        dfd.reject(err);
      });

    return dfd.promise();
  },

  // This is on a trip since a time change could result in multiple triplegs being affected
  // and current tiplegs state is returned
  deleteTripleg: function(tripleg) {
    var dfd = $.Deferred();
    api.triplegs.delete(tripleg.getId()).done(function(result) {
      this.updateTriplegs(result.triplegs);
      dfd.resolve(this);
    }.bind(this)).fail(function(err) {
      log.error('Trip -> deleteTripleg', err);
      dfd.reject(err);
    });
    return dfd.promise();
  },

  mergeTripleg: function(tripleg) {
    var dfd = $.Deferred();
    api.triplegs.merge(tripleg.getId()).done(function(result) {
      this.updateTriplegs(result.triplegs);
      dfd.resolve(this);
    }.bind(this)).fail(function(err) {
      log.error('Trip -> mergeTripleg', err);
      dfd.reject(err);
    });
    return dfd.promise();
  },

  insertTransitionBetweenTriplegs: function(startTime, endTime, fromMode, toMode) {
    var dfd = $.Deferred();
    api.triplegs.insertTransitionBetweenTriplegs(this.getId(), startTime, endTime, fromMode, toMode)
      .done(function(result) {
        if(result.triplegs) {
          log.debug('Trip -> insertTransitionBetweenTriplegs', 'tripleg inserted in trip', this.getId());
          this.updateTriplegs(result.triplegs);
          dfd.resolve(this.triplegs);
        } else {
          var msg = 'Got ok from server but no triplegs returned';
          log.error('Trip -> insertTransitionBetweenTriplegs', msg, 'Got: ', result, 'FOR -- Trip: ' + this.getId(), 'StartTime: ' + startTime, 'EndTime: ' + endTime, 'FromMode: ' + fromMode, 'ToMode: ' + toMode)
          throw msg
          dfd.reject(msg);
        }
      }.bind(this))
      .fail(function(err, jqXHR) {
        log.error('Trip -> insertTransitionBetweenTriplegs', err);
        dfd.reject(err, jqXHR);
      });
    return dfd.promise();
  },

  updateActivitiesOfTrip: function(activityIds) {
    return api.trips.updateActivitiesOfTrip(this.getId(), '{'+activityIds.join(',')+'}').done(function(result) {
      this.setSelectedActivities(activityIds);
      this.emit('trip-update', this);
    }.bind(this)).fail(function(err, jqXHR) {
      log.error('Trip -> updateActivitiesOfTrip', err);
    });
  },
  
  setSelectedActivities: function(activityIds) {
    for (var i = 0; i < this.activities.length; i++) {
        this.activities[i]['selected_order'] = activityIds.indexOf(this.activities[i].id);
    }
    this.newActivity['selected_order'] = activityIds.indexOf(0);
  },
  
  getSelectedActivityIds: function() {
    var selectedActivityIds = [];
    for (var i = 0; i < this.activities.length; i++) {
      if(this.activities[i]['selected_order'] > -1) {
          selectedActivityIds[this.activities[i]['selected_order']] = this.activities[i].id;
      }
    }
    if(this.newActivity['selected_order'] > -1) {
        selectedActivityIds[this.newActivity['selected_order']] = 0;
    }
    return selectedActivityIds;
  },
  
  setNewActivityName: function(activity) {
    this.newActivity.name = activity;
  },
  
  getNewActivity: function(property) {
      return this.newActivity[property];
  },

  updateDestinationPoiIdOfTrip: function(destinationPoiId) {
	if(destinationPoiId > 0){
		return api.trips.updateDestinationPoiIdOfTrip(this.getId(), destinationPoiId).done(function(result) {
			api.trips.getProbableActivities(this.getId()).done(function(activityList) {
				for (var i = 0; i < activityList.length; i++) {
					for (var j = 0; j < this.activities.length; j++) {
						if(activityList[i].id == this.activities[j].id){
							this.activities[j].accuracy = activityList[i].accuracy;
							break;
						}
					}
				}
				this._updateDestinationPlace(destinationPoiId);
				this._sortActivities();
				this.emit('trip-update', this);
			}.bind(this)).fail(function(err, jqXHR) {
			  log.error('Trip -> getProbableActivities', err);
			});
		}.bind(this)).fail(function(err, jqXHR) {
		  log.error('Trip -> updateDestinationPoiIdOfTrip', err);
		});
	}
  },

  setReport: function(reportType, reportContent) {
    this.reportType = reportType;
    this.reportContent = reportContent;
  },

  getReportType: function() {
    return this.reportType;
  },

  getReportContent: function() {
    return this.reportContent;
  },

  addTripReport: function(userId) {
    api.trips.addTripReport(userId, this.getId(), this.getReportType(), this.getReportContent())
      .done(function(result){
        return result;
      }.bind(this)).fail(function(err, jqXHR) {
        log.error('Trip -> addTripReport', err);
        dfd.reject(err, jqXHR);
      });
  },

  getReportTypes: function() {
    return api.trips.getTripReportTypes();
  },

  // Internal methods
  // -------------------------------------------
  // -------------------------------------------

  _checkIfActivitiesIsAccurateAndSyncToServer: function() {
	if(this.isAlreadyAnnotated()){
        return; 
    }
    var estActivities = this.getEstimatedActivities();
    // If activities accuracy is set by server then make sure to sync it to the server
    // !TODO move this logic to server?
    var activityIds = [];
    for (var i in estActivities) {
        var estActivity = estActivities[i];
        if(estActivity) {
            activityIds.push(estActivity.id);
        }
    }
    if(activityIds.length > 0){
        this.updateActivitiesOfTrip(activityIds);
    }
  },

  _checkIfDestinationIsAccurateAndSyncToServer: function() {
	if(this.isAlreadyAnnotated()){
        return; 
    }
    var destination = this.getDestinationPlace();
    // If destination accuracy is set by server then make sure to sync it to the server
    // !TODO move this logic to server?
    if(destination) {
      this.updateDestinationPoiIdOfTrip(destination.gid);
    }
  },

  _updateDestinationPlace: function(destinationPlaceId) {
    for (var i = 0; i < this.destination_places.length; i++) {
      if(this.destination_places[i].gid == destinationPlaceId) {
        this.destination_places[i].accuracy = 100;
      } else {
        this.destination_places[i].accuracy = 0;
      }
    }
    this._sortDestinationPlaces();
  },

  _sortActivities: function() {
    this.activities = util.sortByAccuracy(this.activities);
  },

  _sortDestinationPlaces: function() {
    this.destination_places = util.sortByAccuracy(this.destination_places);
  },

  _getTripleg: function(id, indexDiff) {
    indexDiff = indexDiff ? indexDiff : 0;
    for (var i = 0; i < this.triplegs.length; i++) {
      if(this.triplegs[i].triplegid == id) {
        var tripleg = this.triplegs[i + indexDiff];
        // If tripleg with diff is undefined try returning current
        tripleg = tripleg ? tripleg : this.triplegs[i];
        return tripleg;
      }
    }
    return null;
  }

};
