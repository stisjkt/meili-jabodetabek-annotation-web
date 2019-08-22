/**
 * Created by adi on 2016-09-16.
 */

var express = require('express');
var reqClient = require('../users');
var apiClient = reqClient.client;
var router = express.Router();
var util = require('./util');

/**
 * @api {get} /trips/getTripsForBadge&:user_id Gets the number of trips that the user has to process
 * @apiName GetTripsForBadge
 * @apiGroup Trips
 *
 * @apiError [400] UserIdInvalid The <code>user_id</code> is undefined or null.
 *
 * @apiParam {Number} user_id Id of the user that requests the number of available unannotated trips.
 *
 * @apiSuccess {Number} user_get_badge_trips_info Number of unannotated trips available to the user.
 */
router.get("/getTripsForBadge", function(req,res){
    var results = [];
    var user_id = req.query.user_id;

    if (!user_id) {
        return util.handleError(res, 400, "Invalid user id");
    }
    else {
        var sqlQuery = "select * from apiv2.user_get_badge_trips_info($1)";
        var logQuery = apiClient.query(sqlQuery,[user_id]);

        logQuery.on('error', function(row){
          return util.handleError(res, 500, row.message);
        });

        logQuery.on('end', function(row){
            results.push(row);
            return res.json(results[0]);
        });
    }
});

router.get("/getTotalOfTrips", function(req,res){
    var results = [];
    var user_id = req.query.user_id;

    if (!user_id) {
        return util.handleError(res, 400, "Invalid user id");
    }
    else {
        var sqlQuery = "select(select count(*) from apiv2.unprocessed_trips where user_id =$1) + (select count(*) from apiv2.processed_trips where user_id =$1) as totaltrips";
        var logQuery = apiClient.query(sqlQuery,[user_id]);

        logQuery.on('error', function(row){
          return util.handleError(res, 500, row.message);
        });

        logQuery.on('end', function(row){
            results.push(row);
            return res.json(results[0]);
        });
    }
});

/**
 * @api {get} /trips/getLastTripOfUser&:user_id Gets the earliest unannotated trip of the user
 * @apiName GetLastTripOfUser
 * @apiGroup Trips
 *
 * @apiError [400] UserIdInvalid The <code>user_id</code> is undefined or null.
 * @apiError [500] UserCannotAnnotate The user with <code>user_id</code> does not have any trips to annotate.
 *
 * @apiParam {Number} user_id Id of the user that requests the earliest unannotated trip
 *
 * @apiSuccess {Trip} Trip The json representation of a trip without its triplegs
 */
router.get("/getLastTripOfUser", function(req,res){
    var results = {};
    var user_id = req.query.user_id;

    if (!user_id) {
        return util.handleError(res, 400, "Invalid user id");
    }
    else
    {
        // TODO - this is a hack, not a solution
        //var sqlQuery = "select * from apiv2.pagination_get_next_process("+user_id+")";
        var sqlQuery = "select * from apiv2.get_next_trip_response_temp_fix($1)";
        var logQuery = apiClient.query(sqlQuery,[user_id]);

        logQuery.on('row', function(row){
            results = row;
        });

        logQuery.on('error', function (row){
           return util.handleError(res, 500, row.message);
        });

        logQuery.on('end', function(){
            // check if it is empty
            if (!(Object.keys(results).length === 0 && results.constructor === Object))
            {
                return res.json(results);
            }
            else {
                return util.handleError(res, 204, "The user does not have any trips to process");
            }
        })
    }
});

router.get("/getProbableActivities", function(req,res){
    var results = {};
    var trip_id = req.query.trip_id;

    if (!trip_id) {
        return util.handleError(res, 400, "Invalid trip id");
    }
    else
    {
        var sqlQuery = "select * from apiv2.ap_get_activities($1)";
        var logQuery = apiClient.query(sqlQuery,[trip_id]);

        logQuery.on('row', function(row){
            results = row.ap_get_activities;
        });

        logQuery.on('error', function (row){
           return util.handleError(res, 500, row.message);
        });

        logQuery.on('end', function(){
            // check if it is empty
            if (!(Object.keys(results).length === 0 && results.constructor === Object))
            {
                return res.json(results);
            }
            else {
                return util.handleError(res, 204, "The user does not have any activities to process");
            }
        })
    }
});

/**
 * @api {get} /trips/updateStartTimeOfTrip&:trip_id&:start_time Updates the start time of a trip
 * @apiName UpdateStartTimeOfTrip
 * @apiGroup Trips
 *
 * @apiError [400] InvalidInput The parameters <code>trip_id</code> or <code>start_time</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip that will have its start date modified.
 * @apiParam {Number} start_time The new value for the start time of the specified trip
 *
 * @apiSuccess {Tripleg[]} Triplegs An array of json objects that represent the triplegs of the trip after update
 */
router.get("/updateStartTimeOfTrip", function(req,res){
    var results = {};
    results.triplegs = [];
    var trip_id = req.query.trip_id;
    var new_start_time = req.query.start_time;

    if ((!trip_id)|| (!new_start_time)) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.update_trip_start_time($1,$2)";
        var prioryQuery = apiClient.query(sqlQuery,[new_start_time,trip_id]);

        prioryQuery.on('row', function (row) {
            results.triplegs = row.update_trip_start_time;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

/**
 * @api {get} /trips/updateEndTimeOfTrip&:trip_id&:end_time Updates the end time of a trip
 * @apiName UpdateEndTimeOfTrip
 * @apiGroup Trips
 *
 * @apiError [400] InvalidInput The parameters <code>trip_id</code> or <code>end_time</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip that will have its end time modified.
 * @apiParam {Number} end_time The new value for the end time of the specified trip
 *
 * @apiSuccess {Tripleg[]} Triplegs An array of json objects that represent the triplegs of the trip after update
 */
router.get("/updateEndTimeOfTrip", function(req,res){
    var results = {};
    results.triplegs = [];
    var trip_id = req.query.trip_id;
    var new_end_time = req.query.end_time;

    if ((!trip_id)|| (!new_end_time)) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.update_trip_end_time($1,$2)";
        var prioryQuery = apiClient.query(sqlQuery,[new_end_time,trip_id]);

        prioryQuery.on('row', function (row) {
            results.triplegs = row.update_trip_end_time;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

/**
 * @api {get} /trips/mergeWithNextTrip&:trip_id Merges a trip with its neighbor
 * @apiName MergeWithNextTrip
 * @apiGroup Trips
 *
 * @apiError [400] InvalidInput The parameters <code>trip_id</code> is undefined, null or of a wrong type.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip that will be merged with its neighbor
 *
 * @apiSuccess {Tripleg[]} Triplegs An array of json objects that represent the triplegs of the trip after the merge is performed
 */
router.get("/mergeWithNextTrip", function(req,res){
    var results = {};
    results.triplegs = [];
    var trip_id = req.query.trip_id;

    if (!trip_id) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.merge_with_next_trip($1)";
        var prioryQuery = apiClient.query(sqlQuery,[trip_id]);

        prioryQuery.on('row', function (row) {
            results.triplegs = row.merge_with_next_trip;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

/**
 * @api {get} /trips/insertPeriodBetweenTrips&:start_time&:end_time&:user_id Inserts a missed non movement period between two trips by splitting the existing affected trip
 * @apiName InsertPeriodBetweenTris
 * @apiGroup Trips
 *
 * @apiError [400] InvalidInput The parameters <code>user_id</code>, <code>start_time</code> or <code>end_time</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} user_id Id of the user who inserts the period between trips
 * @apiParam {Number} start_time Time at which the non movement period started
 * @apiParam {Number} end_time Time at which the non movement period ended
 *
 * @apiSuccess {Trip} Trip Gets the json representation of the next trip to process for the user that performed the action.
 */
router.get("/insertPeriodBetweenTrips", function(req,res){
    var results = {};
    results.trip = [];
    var user_id = req.query.user_id;
    var start_time = req.query.start_time;
    var end_time = req.query.end_time;

    if ((!user_id) || (!start_time) || (!end_time)) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.insert_stationary_trip_for_user($1,$2,$3)";
        var prioryQuery = apiClient.query(sqlQuery,[start_time,end_time,user_id]);

        prioryQuery.on('row', function (row) {
            console.log(row);
                results.trip = row;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

/**
 * @api {get} /trips/updateActivitiesOfTrip&:trip_id&:activity_ids Updates the activities of a trip
 * @apiName updateActivitiesOfTrip
 * @apiGroup Trips
 *
 * @apiError [400] InvalidInput The parameters <code>trip_id</code> or <code>activity_ids</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip that will have its activities updated
 * @apiParam {Number} activity_ids The new value for the activity_ids in form of {1,2,3}
 *
 * @apiSuccess {Boolean} Boolean The success state of the operation.
 */
router.get("/updateActivitiesOfTrip", function(req,res){
    var results = {};
    results.status = {};
    var trip_id = req.query.trip_id;
    var activity_ids = req.query.activity_ids;
    var new_activity = req.query.new_activity;

    if ((!trip_id) || (!activity_ids )) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.update_trip_activities($1,$2,$3)";
        var prioryQuery = apiClient.query(sqlQuery,[activity_ids,trip_id,new_activity]);

        prioryQuery.on('row', function (row) {
            results.status = row.update_trip_activities;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

router.get("/updateCostOfTrip", function(req,res){
    var results = {};
    results.status = {};
    var trip_id = req.query.trip_id;
    var transport_cost = req.query.transport_cost;

    if (!trip_id) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.update_trip_cost($1)";
        var prioryQuery = apiClient.query(sqlQuery,[JSON.stringify(transport_cost)]);

        prioryQuery.on('row', function (row) {
            results.status = row.update_trip_cost;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

/**
 * @api {get} /trips/updateDestinationPoiIdOfTrip&:trip_id&:destination_poi_id Updates the destination poi id of a trip
 * @apiName UpdateDestinationPoiIdOfTrip
 * @apiGroup Trips
 *
 * @apiError [400] InvalidInput The parameters <code>trip_id</code> or <code>destination_poi_id</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip that will have its destination poi id updated
 * @apiParam {Number} destination_poi_id The new value for the destination_poi_id
 *
 * @apiSuccess {Boolean} Boolean The success state of the operation.
 */
router.get("/updateDestinationPoiIdOfTrip", function(req,res){
    var results = {};
    results.status = {};
    var trip_id = req.query.trip_id;
    var destination_poi_id = req.query.destination_poi_id;

    if ((!trip_id)|| (!destination_poi_id)) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.update_trip_destination_poi_id($1,$2)";
        var prioryQuery = apiClient.query(sqlQuery,[destination_poi_id,trip_id]);

        prioryQuery.on('row', function (row) {
            results.status = row.update_trip_destination_poi_id;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

/**
 * @api {get} /trips/deleteTrip&:trip_id Deletes a trip
 * @apiName DeleteTrip
 * @apiGroup Trips
 *
 * @apiError [400] InvalidInput The parameter <code>trip_id</code> is undefined, null or of a wrong type.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip that will be deleted
 *
 * @apiSuccess {Trip} Trip Gets the json representation of the next trip to process for the user that performed the action.
 */
router.get("/deleteTrip", function(req,res){
    var results = {};
    var trip_id = req.query.trip_id;

    if (!trip_id ) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.delete_trip($1)";
        var prioryQuery = apiClient.query(sqlQuery,[trip_id]);

        prioryQuery.on('row', function (row) {
            results = row;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

/**
 * @api {get} /trips/confirmAnnotationOfTrip&:trip_id& Confirms the annotations of a trip, which moves the user to the next unannotated trip
 * @apiName ConfirmAnnotationOfTrip
 * @apiGroup Trips
 *
 * @apiError [400] InvalidInput The parameter <code>trip_id</code> is undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip whose annotations are confirmed
 *
 * @apiSuccess {Trip} Trip The json representation of a trip without its triplegs
 */
router.get("/confirmAnnotationOfTrip", function(req,res){
    var results = {};
    var trip_id = req.query.trip_id;

    if (!trip_id) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.confirm_annotation_of_trip_get_next($1)";
        var prioryQuery = apiClient.query(sqlQuery,[trip_id]);

        prioryQuery.on('row', function (row) {
            results = row;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

/**
 * @api {get} /trips/navigateToNextTrip&:trip_id&:user_id Navigates to the next annotated trip, if it exists
 * @apiName NavigateToNextTrip
 * @apiGroup Trips
 *
 * @apiError [400] InvalidInput The parameter <code>trip_id</code> or <code>user_id</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip whose proceeding neighbor is retrieved
 * @apiParam {Number} user_id Id of the user that annotates the trip
 *
 * @apiSuccess {Trip} Trip The json representation of a trip without its triplegs, and a status field with values "already_annotated", if the trip's time intervals should not be modifiable, or "needs_annotation" if the trip is the same with the response for getLastTripOfUser
 */
router.get("/navigateToNextTrip", function(req,res){
    var results = {};
    var trip_id = req.query.trip_id;
    var user_id = req.query.user_id;

    if ((!trip_id )|| (!user_id )) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.pagination_navigate_to_next_trip($1,$2)";
        var prioryQuery = apiClient.query(sqlQuery,[user_id,trip_id]);

        prioryQuery.on('row', function (row) {
            results = row;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

/**
 * @api {get} /trips/navigateToPreviousTrip&:trip_id&:user_id Navigates to the previous annotated trip, if it exists
 * @apiName NavigateToPreviousTrip
 * @apiGroup Trips
 *
 * @apiError [400] InvalidInput The parameter <code>trip_id</code> or <code>user_id</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip whose preceeding neighbor is retrieved
 * @apiParam {Number} user_id Id of the user that annotates the trip
 *
 * @apiSuccess {Trip} Trip The json representation of a trip without its triplegs (empty when the preceeding trip does not exist), and a status field with values "already_annotated", if the trip's time intervals should not be modifiable, or "INVALID" if the navigation works unexpected
 */
router.get("/navigateToPreviousTrip", function(req,res){
    var results = {};
    var trip_id = req.query.trip_id;
    var user_id = req.query.user_id;

    if ((!trip_id)|| (!user_id )) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.pagination_navigate_to_previous_trip($1,$2)";
        var prioryQuery = apiClient.query(sqlQuery,[user_id,trip_id]);

        prioryQuery.on('row', function (row) {
            results = row;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message+' '+sqlQuery);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

/**
 * @api {get} /trips/navigatePreviewPrevTrip&:trip_id&:user_id Navigates to the next trip, if it exists
 * @apiName NavigatePreviewPrevTrip
 * @apiGroup Trips
 *
 * @apiError [400] InvalidInput The parameter <code>trip_id</code> or <code>user_id</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip whose preceeding neighbor is retrieved
 * @apiParam {Number} user_id Id of the user that annotates the trip
 *
 * @apiSuccess {Trip} Trip The json representation of a trip without its triplegs (empty when the preceeding trip does not exist), and a status field with values "already_annotated", if the trip's time intervals should not be modifiable, or "INVALID" if the navigation works unexpected
 */
router.get("/navigatePreviewPrevTrip", function(req,res){
    var results = {};
    var trip_id = req.query.trip_id;
    var user_id = req.query.user_id;

    if ((!trip_id)|| (!user_id )) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.pagination_navigate_preview_prev_trip($1,$2)";
        var prioryQuery = apiClient.query(sqlQuery,[user_id,trip_id]);

        prioryQuery.on('row', function (row) {
            results = row;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message+' '+sqlQuery);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

/**
 * @api {get} /trips/navigatePreviewNextTrip&:trip_id&:user_id Navigates to the next trip, if it exists
 * @apiName NavigatePreviewNextTrip
 * @apiGroup Trips
 *
 * @apiError [400] InvalidInput The parameter <code>trip_id</code> or <code>user_id</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip whose preceeding neighbor is retrieved
 * @apiParam {Number} user_id Id of the user that annotates the trip
 *
 * @apiSuccess {Trip} Trip The json representation of a trip without its triplegs (empty when the preceeding trip does not exist), and a status field with values "already_annotated", if the trip's time intervals should not be modifiable, or "INVALID" if the navigation works unexpected
 */
router.get("/navigatePreviewNextTrip", function(req,res){
    var results = {};
    var trip_id = req.query.trip_id;
    var user_id = req.query.user_id;

    if ((!trip_id)|| (!user_id )) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.pagination_navigate_preview_next_trip($1,$2)";
        var prioryQuery = apiClient.query(sqlQuery,[user_id,trip_id]);

        prioryQuery.on('row', function (row) {
            results = row;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message+' '+sqlQuery);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

/**
 * @api {get} /trips/navigateGoToTrip&:trip_number&:user_id Navigates to the next trip, if it exists
 * @apiName NavigatePreviewNextTrip
 * @apiGroup Trips
 *
 * @apiError [400] InvalidInput The parameter <code>trip_id</code> or <code>user_id</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip whose preceeding neighbor is retrieved
 * @apiParam {Number} user_id Id of the user that annotates the trip
 *
 * @apiSuccess {Trip} Trip The json representation of a trip without its triplegs (empty when the preceeding trip does not exist), and a status field with values "already_annotated", if the trip's time intervals should not be modifiable, or "INVALID" if the navigation works unexpected
 */
router.get("/navigateGoToTrip", function(req,res){
    var results = {};
    var trip_number = req.query.trip_number;
    var user_id = req.query.user_id;

    if ((!trip_number)|| (!user_id )) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.pagination_go_to_trip($1,$2)";
        var prioryQuery = apiClient.query(sqlQuery,[user_id,trip_number]);

        prioryQuery.on('row', function (row) {
            results = row;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message+' '+sqlQuery);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

/**
 * @api {get} /trips/undoLastAnnotation&:user_id Undo the last annotation done by user
 * @apiName undoLastAnnotation
 * @apiGroup Trips
 *
 * @apiError [400] InvalidInput The parameter <code>trip_id</code> or <code>user_id</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} user_id Id of the user that annotates the trip
 *
 * @apiSuccess {Trip} Trip The json representation of a trip without its triplegs (empty when the preceeding trip does not exist), and a status field with values "already_annotated", if the trip's time intervals should not be modifiable, or "INVALID" if the navigation works unexpected
 */
router.get("/undoLastAnnotation", function(req,res){
    var results = {};
    var user_id = req.query.user_id;

    if ((!user_id)) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.undo_last_annotation($1)";
        var prioryQuery = apiClient.query(sqlQuery,[user_id]);

        prioryQuery.on('row', function (row) {
            results = row;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message+' '+sqlQuery);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

router.get('/addTripReport', function (req, res) {
    var results = {
        status: true
    };
    // Grab data from http request
    var data = {
        userId: req.query.user_id,
        tripId: req.query.trip_id,
        reportType: req.query.report_type,
        reportContent: req.query.report_content
    };

    console.log(data);

    var sqlQuery = "insert into apiv2.report_table(id, content, report_type, trip_id, user_id) values(DEFAULT, $1, $2, $3, $4)";
    var query = apiClient.query(sqlQuery, [data.reportContent, data.reportType, data.tripId, data.userId]);

    query.on('error', function(row) {
        return util.handleError(res, 500, row.message+' '+sqlQuery);
    });

    query.on('end', function() {
        return res.json(results);
    });
    
});

router.get('/getTripReportTypes', function (req, res){
    var results = [];
    var sqlQuery = "select * from apiv2.report_type_table";
    var query = apiClient.query(sqlQuery);
    
    query.on(('row'), function(row) {
        results.push(row);
    });

    query.on('error', function(row) {
        return util.handleError(res, 500, row.message+' '+sqlQuery);
    });

    query.on('end', function() {
        return res.json(results);
    });
});

router.get('/getReportOfTrip', function (req, res){
    var data = {
        userId: req.query.user_id,
        tripId: req.query.trip_id,
    };

    var results;
    var sqlQuery = "select * from apiv2.report_table where user_id=$1 and trip_id=$2 order by id desc limit 1";
    var query = apiClient.query(sqlQuery, [data.userId, data.tripId]);
    
    query.on(('row'), function(row) {
        results = row;
    });

    query.on('error', function(row) {
        return util.handleError(res, 500, row.message+' '+sqlQuery);
    });

    query.on('end', function() {
        return res.json(results);
    });
});

module.exports = router;