
var request = Request();

var Api = function(config) {

  var mainPaths = {
    trips: 'trips',
    triplegs: 'triplegs',
    pois: 'pois'
  };

  function url(mainPath, path) { return [config.api_host, config.api_url, mainPath, path].join('/') };

  function verifyTriplegsIsReturned(dfd, result) {
    if(result.triplegs && result.triplegs.length > 0) {
      dfd.resolve(result);
    } else {
      var msg = 'No triplegs returned';
      log.error('Api -> verifyTriplegsIsReturned', msg);
      dfd.reject(msg);
      throw msg;
    }
  }

  return {

    users: {
      loggedIn: function() {
        return request.get([config.api_host, 'users/loggedin'].join('/'));
      },

      login: function(username, password) {
        return request.post([config.api_host, 'users/login'].join('/'), {
          username: username,
          password: password
        });
      }
    },

    trips: {

      getLast: function(userId){
        return request.get(url(mainPaths.trips, 'getLastTripOfUser'), { user_id: userId });
      },

      getNumberOfTrips: function(userId) {
        return request.get(url(mainPaths.trips, 'getTripsForBadge'), { user_id: userId });
      },

      getTotalOfTrips: function(userId) {
      	return request.get(url(mainPaths.trips, 'getTotalOfTrips'), {user_id: userId});
      },

      updateStartTime: function(tripId, startTime) {
        return request.get(
          url(mainPaths.trips, 'updateStartTimeOfTrip'),
          {
            trip_id: tripId,
            start_time: startTime
          },
          verifyTriplegsIsReturned
        );
      },
	  
	  getProbableActivities: function(tripId){
        return request.get(url(mainPaths.trips, 'getProbableActivities'), { trip_id: tripId });
      },

      updateEndTime: function(tripId, endTime) {
        return request.get(
          url(mainPaths.trips, 'updateEndTimeOfTrip'),
          {
            trip_id: tripId,
            end_time: endTime
          },
          verifyTriplegsIsReturned
        );
      },

      updateActivitiesOfTrip: function(tripId, activityIds, newActivity) {
        return request.get(
          url(mainPaths.trips, 'updateActivitiesOfTrip'),
          {
            trip_id: tripId,
            activity_ids: activityIds,
            new_activity: newActivity
          },
          function(dfd, result) {
            if(result.status == true) {
              dfd.resolve(result);
            } else {
              var msg = 'Some problem updating activities of trip, server responded with incorrect status';
              log.error('Api -> updateActivitiesOfTrip', msg);
              dfd.reject(msg);
              throw msg;
            }
          }
        );
      },
	  
	  updateCostOfTrip: function(tripId, transportCost) {
        return request.get(
          url(mainPaths.trips, 'updateCostOfTrip'),
          {
            trip_id: tripId,
            transport_cost: transportCost
          },
          function(dfd, result) {
            if(result.status == true) {
              dfd.resolve(result);
            } else {
              var msg = 'Some problem updating cost of trip, server responded with incorrect status';
              log.error('Api -> updateCostOfTrip', msg);
              dfd.reject(msg);
              throw msg;
            }
          }
        );
      },

      splitTrip: function(userId, start_time, end_time){
            return request.get(
                url(mainPaths.trips, 'insertPeriodBetweenTrips'),
                {
                    user_id: userId,
                    start_time: start_time,
                    end_time: end_time
                },
                function(dfd, result) {
                    if(result.trip) {
                        dfd.resolve(result.trip);
                    } else {
                        var msg = 'Some problem splitting one trip in two, server responded with incorrect status';
                        log.error('Api -> insertPeriodBetweenTrips', msg);
                        dfd.reject(msg);
                        throw msg;
                    }
                }
            );
        },

      updateDestinationPoiIdOfTrip: function(tripId, destinationPoiId) {
        return request.get(
          url(mainPaths.trips, 'updateDestinationPoiIdOfTrip'),
          {
            trip_id: tripId,
            destination_poi_id: destinationPoiId
          },
          function(dfd, result) {
            if(result.status == true) {
              dfd.resolve(result);
            } else {
              var msg = 'Some problem updating destination poi of trip, server responded with incorrect status';
              log.error('Api -> updateDestinationPoiIdOfTrip', msg);
              dfd.reject(msg);
              throw msg;
            }
          }
        );
      },

      navigateToPreviousTrip: function(userId, tripId) {
        return request.get(
          url(mainPaths.trips, 'navigateToPreviousTrip'),
          {
            trip_id: tripId,
            user_id: userId
          }
        );
      },

      navigateToNextTrip: function(userId, tripId) {
        return request.get(
          url(mainPaths.trips, 'navigateToNextTrip'),
          {
            trip_id: tripId,
            user_id: userId
          }
        );
      },

      navigatePreviewNextTrip: function(userId, tripId) {
        return request.get(
          url(mainPaths.trips, 'navigatePreviewNextTrip'),
          {
            trip_id: tripId,
            user_id: userId
          }
        );
      },

      navigatePreviewPrevTrip: function(userId, tripId) {
        return request.get(
          url(mainPaths.trips, 'navigatePreviewPrevTrip'),
          {
            trip_id: tripId,
            user_id: userId
          }
        );
      },

      navigateGoToTrip: function(userId, tripNumber) {
        return request.get(
          url(mainPaths.trips, 'navigateGoToTrip'),
          {
            trip_number: tripNumber,
            user_id: userId
          }
        );
      },

      undoLastAnnotation: function(userId) {
        return request.get(
          url(mainPaths.trips, 'undoLastAnnotation'),
          {
            user_id: userId
          }
        );
      },

      confirmAnnotationOfTrip: function(tripId) {
        return request.get(
          url(mainPaths.trips, 'confirmAnnotationOfTrip'),
          {
            trip_id: tripId
          }
        );
      },

      delete: function(tripId) {
        return request.get(
          url(mainPaths.trips, 'deleteTrip'),
          {
            trip_id: tripId
          }
        );
      },

      mergeWithNextTrip: function(tripId) {
        return request.get(
          url(mainPaths.trips, 'mergeWithNextTrip'),
          {
            trip_id: tripId
          },
          verifyTriplegsIsReturned
        );
      },

      getTripReportTypes: function() {
        return request.get(
          url(mainPaths.trips, 'getTripReportTypes'),
          {
            
          }
        );
      },

      addTripReport: function(userId, tripId, reportType, reportContent) {
        return request.get(
          url(mainPaths.trips, 'addTripReport'),
          {
            user_id: userId,
            trip_id: tripId,
            report_type: reportType,
            report_content: reportContent
          },
          function(dfd, result) {
            if(result.status == true) {
              dfd.resolve(result);
            } else {
              var msg = 'Some problem adding trip report, server responded with incorrect status';
              log.error('Api -> addTripReport', msg);
              dfd.reject(msg);
              throw msg;
            }
          }
        );
      }
    },

    triplegs: {

      get: function(tripId) {
        return request.get(
          url(mainPaths.triplegs, 'getTriplegsOfTrip'),
          { trip_id: tripId },
          verifyTriplegsIsReturned
        );
      },

      getAnnotated: function(tripId) {
        return request.get(
          url(mainPaths.triplegs, 'getAnnotatedTriplegsOfTrip'),
          { trip_id: tripId },
          verifyTriplegsIsReturned
        );
      },
	  
	  getProbableModes2: function(triplegId, transportationTypeId) {
        return request.get(
          url(mainPaths.triplegs, 'getProbableModes2'),
          { tripleg_id: triplegId, transportation_type_id: transportationTypeId }
        );
      },

      updateStartTime: function(triplegId, startTime) {
        return request.get(
          url(mainPaths.triplegs, 'updateStartTimeOfTripleg'),
          {
            tripleg_id: triplegId,
            start_time: startTime
          },
          verifyTriplegsIsReturned
        );
      },

      updateEndTime: function(triplegId, endTime) {
        return request.get(
          url(mainPaths.triplegs, 'updateEndTimeOfTripleg'),
          {
            tripleg_id: triplegId,
            end_time: endTime
          },
          verifyTriplegsIsReturned
        );
      },

      updateMode: function(triplegId, travelMode) {
        return request.get(
          url(mainPaths.triplegs, 'updateTravelModeOfTripleg'),
          {
            tripleg_id: triplegId,
            travel_mode: travelMode
          },
          function(dfd, result) {
            if(result.status == true) {
              dfd.resolve(result);
            } else {
              var msg = 'Some problem updating mode, server responded with incorrect status';
              log.error('Api -> updateMode', msg);
              dfd.reject(msg);
              throw msg;
            }
          }
        );
      },
	  
	  updateMode2: function(triplegId, travelMode2) {
        return request.get(
          url(mainPaths.triplegs, 'updateTravelMode2OfTripleg'),
          {
            tripleg_id: triplegId,
            travel_mode2: travelMode2
          },
          function(dfd, result) {
            if(result.cost) {
              dfd.resolve(result);
            } else {
              var msg = 'Some problem updating mode, server responded with incorrect status';
              log.error('Api -> updateMode', msg);
              dfd.reject(msg);
              throw msg;
            }
          }
        );
      },

      delete: function(triplegId) {
        return request.get(
          url(mainPaths.triplegs, 'deleteTripleg'),
          {
            tripleg_id: triplegId
          },
          verifyTriplegsIsReturned
        );
      },

      insertTransitionBetweenTriplegs: function(tripId, startTime, endTime, fromMode, toMode) {
        return request.get(
          url(mainPaths.triplegs, 'insertTransitionBetweenTriplegs'),
          {
            trip_id: tripId,
            start_time: startTime,
            end_time: endTime,
            from_travel_mode: fromMode,
            to_travel_mode: toMode
          },
          verifyTriplegsIsReturned
        );
      },

      merge: function(triplegId) {
        return request.get(
          url(mainPaths.triplegs, 'mergeTripleg'),
          {
            tripleg_id: triplegId
          },
          verifyTriplegsIsReturned
        );
      },

      updateTransitionPoiIdOfTripleg: function(triplegId, transitionPoiId) {
        return request.get(
          url(mainPaths.triplegs, 'updateTransitionPoiIdOfTripleg'),
          {
            tripleg_id: triplegId,
            transition_poi_id: transitionPoiId
          },
          function(dfd, result) {
            if(result.status == true) {
              dfd.resolve(result);
            } else {
              var msg = 'Some problem updating transition poi of tripleg, server responded with incorrect status';
              log.error('Api -> updateTransitionPoiIdOfTripleg', msg);
              dfd.reject(msg);
              throw msg;
            }
          }
        );
      }
    },

    pois: {
      insertDestinationPoi: function(name, point, userId) {
        return request.get(
          url(mainPaths.pois, 'insertDestinationPoi'),
          {
            name_: name,
            latitude: point.lat,
            longitude: point.lng,
            declaring_user_id: userId
          },
          function(dfd, result) {
            if(result.insert_destination_poi) {
              dfd.resolve(result);
            } else {
              var msg = 'Problem inserting destination poi';
              log.error('Api -> insertDestinationPoi', msg);
              dfd.reject(msg);
              throw msg;
            }
          }
        );
      },
      insertTransportationPoi: function(name, point, userId) {
        return request.get(
          url(mainPaths.pois, 'insertTransportationPoi'),
          {
            name_: name,
            latitude: point.lat,
            longitude: point.lng,
            declaring_user_id: userId,
            //transportation_lines: null,
            //transportation_types: null
          },
          function(dfd, result) {
            if(result.insert_transition_poi) {
              dfd.resolve(result);
            } else {
              var msg = 'Problem inserting transition poi';
              log.error('Api -> insertTransitionPoi', msg);
              dfd.reject(msg);
              throw msg;
            }
          }
        );
      }
    }
  }
};

