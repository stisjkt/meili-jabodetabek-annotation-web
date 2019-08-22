/**
 * Created by adi on 2016-09-16.
 */

var express = require('express');
var reqClient = require('../users');
var apiClient = reqClient.client;
var router = express.Router();
var util = require('./util');

/**
 * @api {get} /triplegs/getTriplegsOfTrip&:trip_id Gets the triplegs of a given trip
 * @apiName GetTriplegsOfTrip
 * @apiGroup Triplegs
 *
 * @apiError [400] TripIdInvalid The <code>trip_id</code> is undefined or null.
 * @apiError [404] TripIdNotFound The <code>trip_id</code> does not exist.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip for which the triplegs will be retrieved
 *
 * @apiSuccess {Tripleg[]} Triplegs An array of json objects that represent the triplegs
 */
router.get("/getTriplegsOfTrip", function(req,res){
    var results = {};
    results.triplegs = [];
    var trip_id = req.query.trip_id;

    if (!trip_id) {
        return util.handleError(res, 400, "Invalid trip id");
    }

    else
    {
        var sqlQuery = "select * from apiv2.pagination_get_triplegs_of_trip($1)";
        var prioryQuery = apiClient.query(sqlQuery,[trip_id]);

        prioryQuery.on('row', function (row) {
            results.triplegs = row.pagination_get_triplegs_of_trip || [];
        });

        prioryQuery.on('error', function (row) {
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            if (results.triplegs.length > 0)
                return res.json(results);
            else {
                return util.handleError(res, 404, "Trip id does not exist");
            }
        });
    }
});

router.get("/getProbableModes2", function(req,res){
    var results = {};
    results.modes2 = [];
	var tripleg_id = req.query.tripleg_id;
    var transportation_type_id = req.query.transportation_type_id;

    if (!tripleg_id || !transportation_type_id) {
        return util.handleError(res, 400, "Invalid tripleg id or transportation_type id");
    }
    else
    {
        var sqlQuery = "select ap_get_probable_modes2_of_tripleg_json from apiv2.ap_get_probable_modes2_of_tripleg_json($1,$2)";
        var prioryQuery = apiClient.query(sqlQuery,[tripleg_id, transportation_type_id]);

        prioryQuery.on('row', function (row) {
            results.modes2 = row.ap_get_probable_modes2_of_tripleg_json || [];
        });

        prioryQuery.on('error', function (row) {
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            if (results.modes2.length > 0)
                return res.json(results);
            else {
                return util.handleError(res, 404, "No data returned");
            }
        });
    }
});

/**
 * @api {get} /triplegs/getAnnotatedTriplegsOfTrip&:trip_id Gets the triplegs of an annotated given trip
 * @apiName GetAnnotatedTriplegsOfTrip
 * @apiGroup Triplegs
 *
 * @apiError [400] TripIdInvalid The <code>trip_id</code> is undefined or null.
 * @apiError [404] TripIdNotFound The <code>trip_id</code> does not exist.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip for which the triplegs will be retrieved
 *
 * @apiSuccess {Tripleg[]} Triplegs An array of json objects that represent the triplegs
 */
router.get("/getAnnotatedTriplegsOfTrip", function(req,res){
    var results = {};
    results.triplegs = [];
    var trip_id = req.query.trip_id;

    if (!trip_id) {
        return util.handleError(res, 400, "Invalid trip id");
    }

    else
    {
        var sqlQuery = "select * from apiv2.pagination_get_triplegs_of_trip_gt($1)";
        var prioryQuery = apiClient.query(sqlQuery,[trip_id]);

        prioryQuery.on('row', function (row) {
            results.triplegs = row.pagination_get_triplegs_of_trip_gt || [];
        });

        prioryQuery.on('error', function (row) {
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            if (results.triplegs.length > 0)
                return res.json(results);
            else {
                return util.handleError(res, 404, "Trip id does not exist");
            }
        });
    }
});


/**
 * @api {get} /triplegs/updateStartTimeOfTripleg&:tripleg_id&:start_time Updates the start time of a tripleg
 * @apiName UpdateStartTimeOfTripleg
 * @apiGroup Triplegs
 *
 * @apiError [400] InvalidInput The parameters <code>tripleg_id</code> or <code>start_time</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} tripleg_id Id of the tripleg that will have its start date modified.
 * @apiParam {Number} start_time The new value for the start time of the specified tripleg
 *
 * @apiSuccess {Tripleg[]} Triplegs An array of json objects that represent the triplegs of the trip after update
 */
router.get("/updateStartTimeOfTripleg", function(req,res){
    var results = {};
    results.triplegs = [];
    var tripleg_id = req.query.tripleg_id;
    var new_start_time = req.query.start_time;

    if ((!tripleg_id) || (!new_start_time)) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.update_tripleg_start_time($1,$2)";
        var prioryQuery = apiClient.query(sqlQuery,[new_start_time,tripleg_id]);

        prioryQuery.on('row', function (row) {
                results.triplegs = row.update_tripleg_start_time;
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
 * @api {get} /triplegs/updateEndTimeOfTripleg&:tripleg_id&:end_time Updates the end time of a tripleg
 * @apiName UpdateEndTimeOfTripleg
 * @apiGroup Triplegs
 *
 * @apiError [400] InvalidInput The parameters <code>tripleg_id</code> or <code>end_time</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} tripleg_id Id of the tripleg that will have its end date modified.
 * @apiParam {Number} end_time The new value for the end time of the specified tripleg
 *
 * @apiSuccess {Tripleg[]} Triplegs An array of json objects that represent the triplegs of the trip after update
 */
router.get("/updateEndTimeOfTripleg", function(req,res){
    var results = {};
    results.triplegs = []
    var tripleg_id = req.query.tripleg_id;
    var new_end_time = req.query.end_time;

    if ((!tripleg_id) || (!new_end_time)) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.update_tripleg_end_time($1,$2)";
        var prioryQuery = apiClient.query(sqlQuery,[new_end_time,trip_id]);

        prioryQuery.on('row', function (row) {
                results.triplegs = row.update_tripleg_end_time;
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
 * @api {get} /triplegs/deleteTripleg&:tripleg_id Deletes the tripleg specified by id
 * @apiName DeleteTripleg
 * @apiGroup Triplegs
 *
 * @apiError [400] InvalidInput The parameters <code>tripleg_id</code> is undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} tripleg_id Id of the tripleg that will be deleted
 *
 * @apiSuccess {Tripleg[]} Triplegs An array of json objects that represent the triplegs of the trip after deletion
 */
router.get("/deleteTripleg", function(req,res){
    var results = {};
    results.triplegs = [];
    var tripleg_id = req.query.tripleg_id;

    if (!tripleg_id) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.delete_tripleg($1)";
        console.log(sqlQuery);

        var prioryQuery = apiClient.query(sqlQuery,[tripleg_id]);

        prioryQuery.on('row', function (row) {
            results.triplegs = row.delete_tripleg;
        });

        prioryQuery.on('error', function(row){
            console.log(row);
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

/**
 * @api {get} /triplegs/insertTransitionBetweenTriplegs&:start_time&:end_time&:from_travel_mode&:to_travel_mode&:trip_id Inserts a missed transition between two triplegs by splitting the existing affected tripleg
 * @apiName InsertTransitionBetweenTriplegs
 * @apiGroup Triplegs
 *
 * @apiError [400] InvalidInput The parameters <code>tripleg_id</code> is undefined, null or of wrong types.
 * @apiError [400] InvalidInput Start time cannot be later than end time.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} trip_id Id of the trip where the transition will be inserted
 * @apiParam {Number} start_time Time at which the transition started
 * @apiParam {Number} end_time Time at which the transition ended
 * @apiParam {Number} from_travel_mode The travel mode from which the user changed
 * @apiParam {Number} to_travel_mode The travel mode to which the user changed
 *
 * @apiSuccess {Tripleg[]} Triplegs An array of json objects that represent the triplegs of the trip after the insertion of the transition tripleg
 */
router.get("/insertTransitionBetweenTriplegs", function(req,res){
    var results = {};
    results.triplegs = [];
    var trip_id = req.query.trip_id;
    var start_time = req.query.start_time;
    var end_time = req.query.end_time;
    var from_travel_mode = req.query.from_travel_mode;
    var to_travel_mode =req.query.to_travel_mode;

    if ((!trip_id) ||(!start_time) ||(!end_time) ||(!from_travel_mode) || (!to_travel_mode)) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    if (start_time>end_time)
        return util.handleError(res, 400, "Start time cannot be later than end time");

    else
    {
        var sqlQuery = "select * from apiv2.insert_stationary_tripleg_period_in_trip($1,$2,$3,$4,$5)";
        var prioryQuery = apiClient.query(sqlQuery,[start_time,end_time,from_travel_mode,to_travel_mode,trip_id]);

        prioryQuery.on('row', function (row) {
                results.triplegs = row.insert_stationary_tripleg_period_in_trip;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            if (!results.triplegs) return util.handleError(res, 500, "you specified an invalid time period");
            else
            return res.json(results);
        });
    }
});


/**
 * @api {get} /triplegs/updateTravelModeOfTripleg&:tripleg_id&:travel_mode Updates the travel mode of a tripleg
 * @apiName UpdateTravelModeOfTripleg
 * @apiGroup Triplegs
 *
 * @apiError [400] InvalidInput The parameters <code>tripleg_id</code> or <code>travel_mode</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} tripleg_id Id of the tripleg that will have its travel mode updated
 * @apiParam {Number} travel_mode The new value for the travel mode of the specified tripleg
 *
 * @apiSuccess {Boolean} Boolean Returns whether the operation was successfull or not.
 */
router.get("/updateTravelModeOfTripleg", function(req,res){
    var results = {};
    results.status = {};
    var tripleg_id = req.query.tripleg_id;
    var travel_mode = req.query.travel_mode;

    if ((!tripleg_id) || (!travel_mode)) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.update_tripleg_travel_mode($1,$2)";
        var prioryQuery = apiClient.query(sqlQuery,[travel_mode,tripleg_id]);

        prioryQuery.on('row', function (row) {
            results.status = row.update_tripleg_travel_mode;
        });

        prioryQuery.on('error', function(row){
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

router.get("/updateTravelMode2OfTripleg", function(req,res){
    var results = {};
    results.cost = {};
    var tripleg_id = req.query.tripleg_id;
    var travel_mode2 = req.query.travel_mode2;

    if ((!tripleg_id) || (!travel_mode2)) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.update_tripleg_travel_mode2($1,$2)";
        var prioryQuery = apiClient.query(sqlQuery,[travel_mode2,tripleg_id]);

        prioryQuery.on('row', function (row) {
            results.cost = row.update_tripleg_travel_mode2;
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
 * @api {get} /triplegs/updateTransitionPoiIdOfTripleg&:tripleg_id&:transition_poi_id Updates the travel mode of a tripleg
 * @apiName UpdateTransitionPoiIdOfTripleg
 * @apiGroup Triplegs
 *
 * @apiError [400] InvalidInput The parameters <code>tripleg_id</code> or <code>transition_poi_id</code> are undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} tripleg_id Id of the tripleg that will have its travel mode updated
 * @apiParam {Number} transition_poi_id The new value for the transition poi id of the specified tripleg
 *
 * @apiSuccess {Boolean} Boolean Returns whether the operation was successfull or not.
 */
router.get("/updateTransitionPoiIdOfTripleg", function(req,res){
    var results = {};
    results.status = {};
    var tripleg_id = req.query.tripleg_id;
    var transition_poi_id = req.query.transition_poi_id;

    console.log(tripleg_id);
    console.log(transition_poi_id);
    if ((!tripleg_id )|| (!transition_poi_id)) {
         return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.update_tripleg_transition_poi_id($1,$2)";
        var prioryQuery = apiClient.query(sqlQuery,[transition_poi_id,tripleg_id]);

        prioryQuery.on('row', function (row) {
            results.status = row.update_tripleg_transition_poi_id;
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
 * @api {get} /triplegs/mergeTripleg&:tripleg_id Merges the tripleg specified by id
 * @apiName MergeTripleg
 * @apiGroup Triplegs
 *
 * @apiError [400] InvalidInput The parameters <code>tripleg_id</code> is undefined, null or of wrong types.
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiParam {Number} tripleg_id Id of the tripleg that will be merged
 *
 * @apiSuccess {Tripleg[]} Triplegs An array of json objects that represent the triplegs of the trip after deletion
 */
router.get("/mergeTripleg", function(req,res){
    var results = {};
    results.triplegs = [];
    var tripleg_id = req.query.tripleg_id;

    if (!tripleg_id) {
        return util.handleError(res, 400, "Invalid input parameters");
    }

    else
    {
        var sqlQuery = "select * from apiv2.merge_tripleg($1)";
        console.log(sqlQuery);

        var prioryQuery = apiClient.query(sqlQuery,[tripleg_id]);

        prioryQuery.on('row', function (row) {
            results.triplegs = row.merge_tripleg;
        });

        prioryQuery.on('error', function(row){
            console.log(row);
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            return res.json(results);
        });
    }
});

//TODO - these are bits of code that are not implemented / tested yet -> move the todo list below when a function is cleared out
// Any functions that are missing?

module.exports = router;