'use strict';

var log = new Log(CONFIG);
var api = Api(CONFIG);
var ui  = {};
var totaltrips = 0;
var tripleft = 0;
var currenttrip = 0;
var tripNavCounter = 1; //1 if getLastTrip called
var tripNavDirection = 0; //-1:prev, 1:next, 0:not moving
$(function() {

    var user = new User();
    var login = new Login(user);
    ui.errorMsg = new ErrorMsg();

    // Catch all client errors
    window.onerror = function (errorMsg, url, lineNumber, column, errorObj) {
        var stack = '';
        try {
            stack = errorObj && errorObj.stack ? ' >> STACK >> ' + errorObj.stack.toString() : '';
        } catch(e) {}
        log.error('Window -> onerror', errorMsg, url, lineNumber, column, stack);
        ui.errorMsg.show(errorMsg);
    };

    // Render a document
    function render(path, callback) {
        // Getting document
        request.get(path)
            .done(function(content) {
                // Render it to #content
                var $contentRef = $('#content');
                $contentRef.empty().append(content);
                if(callback) {
                    // procceed
                    callback($contentRef);
                }
            });
    }

    // Call server to verify that the user is logged in
    function verifyLoggedIn(callback) {
        user.verifyLoggedIn()
            .done(function() {
                callback();
            })
            .fail(function() {
                page('/login');
            });
    }

     function renderTrip(trip) {

        // Render timeline
        ui.timeline.render(trip);

        // Render map
        ui.lmap.render(trip.generateMapLayer());
    }

    // Parameter Parser
    function getParameterByName(name, url) {
        if (!url) url = window.location.href;
        name = name.replace(/[\[\]]/g, "\\$&");
        var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
            results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    }

    // Routing
    // -------------------------------------------
    // -------------------------------------------

    // Resolve old paths
    page('/#/*', function(ctx, next) {
        var p = ctx.path.split('/');
        var path = p[p.length-1];
        if(path) {
            page('/'+path);
        } else {
            page('/');
        }
    })

    function generateTripSelector(totalTrips) {
        var content = '<form action="" class="formName">' +
            '<div class="btn-group-vertical btn-block" id="trip-selector">' ;
            for (let index = 1; index <= totalTrips; index++) {
                content += '<button type="button" class="btn btn-default btn-trip-selector" data='+ index +'>'+ index +'</button>';
            }
            content += '</ul>' +
            '</form>';
        return content;
    }

    page('/', function(ctx, next) {
        render('views/partials/main.html');
    });

    page('/login', function(ctx, next) {
        render('views/partials/login.html', function() { next(); });
    });

    function getParameterByName(name) {
        name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
        var regexS = "[\\?&]" + name + "=([^&#]*)";
        var regex = new RegExp(regexS);
        var results = regex.exec(window.location.href);
        if (results == null)
            return null;
        else
            return decodeURIComponent(results[1].replace(/\+/g, " "));
    }

    page('/map', function(ctx, next) {
        
        verifyLoggedIn(function() {
            render('views/partials/map.html', function() {
                var previewMode = getParameterByName("previewMode");
				if(previewMode == null){
					return;
				}
				previewMode = getParameterByName("previewMode") === 'true';
                ui.lmap = new LMap(CONFIG.map, user.id);
                ui.timeline = new Timeline({ elementId: 'timeline', previewMode: previewMode});
                //budi = ui.lmap.map._lastCenter;
                
                // keep track of user changing trip
                user.off('current-trip-changed').on('current-trip-changed', function(trip) {
                    // update number of trips left to annotate
                    user.getNumberOfTrips()
                      .done(function(result) {
						user.getTotalOfTrips()
							.done(function(result2){
                                totaltrips = result2.rows[0].totaltrips;
                                $('#trip-selector-placeholder').html(generateTripSelector(totaltrips));
								$('#total-trips').html(totaltrips);
								tripleft = result.rows[0].user_get_badge_trips_info;
								$('#tripsLeft').html(tripleft);
								$('#badge_holder').show();
                                if(tripleft == 0){
								    currenttrip = totaltrips;
                                } else {
                                    currenttrip = totaltrips - tripleft + tripNavCounter;
                                }
                                $('#current-trips').html(currenttrip);
                                
                                $('.btn-trip-selector').on('click', function(){
                                    var data = $.parseJSON($(this).attr('data'));
                                    user.navigateGoToTrip(data);
                                    tripNavCounter += (data - currenttrip);
                                    $('.modal').hide();
                                });
								
								$('.navbar-nav>li>a').on('click', function(){
									$('.navbar-collapse').collapse('hide');
								});
						});
                    });

                    trip.off('trip-confirm').on('trip-confirm', user.confirmTrip.bind(user));
                    trip.off('trip-update').on('trip-update', renderTrip);
                    trip.off('triplegs-update').on('triplegs-update', renderTrip);
                    trip.off('split-trip').on('split-trip', user.splitTrip.bind(user));

                    renderTrip(trip);

                    // Ugly hack to scroll timeline to top on trip change
                    ui.timeline.scrollToTop();

                });
                // Adding timeline events
                ui.timeline.off('navigate-to-trip').on('navigate-to-trip', user.navigateGoToTrip.bind(user));
                ui.timeline.off('move-to-previous-trip').on('move-to-previous-trip', user.getPreviousTrip.bind(user));
                ui.timeline.off('move-preview-prev-trip').on('move-preview-prev-trip', user.getPreviewPrevTrip.bind(user));
                ui.timeline.off('move-preview-next-trip').on('move-preview-next-trip', user.getPreviewNextTrip.bind(user));
                ui.timeline.off('undo-last-annotation').on('undo-last-annotation', user.undoLastAnnotation.bind(user));
                ui.timeline.off('move-to-next-trip').on('move-to-next-trip', user.getNextTrip.bind(user));
                ui.timeline.off('delete-trip').on('delete-trip', user.deleteTrip.bind(user));
                ui.timeline.off('merge-trip').on('merge-trip', user.mergeWithNextTrip.bind(user));
                ui.timeline.off('map-zoom-to').on('map-zoom-to', ui.lmap.fitBounds.bind(ui.lmap))
                ui.timeline.off('add-new-destination').on('add-new-destination', function() {
                    ui.lmap.addNewPlace().then(user.addNewDestinationPoiToCurrentTrip.bind(user));
                }.bind(this));
                ui.timeline.off('add-new-transportation-poi').on('add-new-transportation-poi', function(tripleg) {
                    ui.lmap.addNewPlace().then(function(name, point) {
                        user.insertTransportationPoi(name, point).then(function(result) {
                            tripleg.addTransitionPlace(result.insert_transition_poi, name, point);
                            tripleg.updateTransitionPoiIdOfTripleg(result.insert_transition_poi);
                        });
                    });
                }.bind(this));

                // Initiate by getting last trip for user and rendering it
                user.getLastTrip().done(renderTrip);
            });
            
        });
        
    });

    page('/statistics', function(ctx, next) {
        verifyLoggedIn(function() {
            render('views/partials/statistics.html', function() { next(); });
        });
    });

    page('/faq', function(ctx, next) {
        render('views/partials/faq.html', function() { next(); });
    });

    page('/about', function(ctx, next) {
        render('views/partials/about.html', function() { next(); });
    });

    page('/contact', function(ctx, next) {
        render('views/partials/contact.html', function() { next(); });
    });

    page({ hashbang: true });
});

