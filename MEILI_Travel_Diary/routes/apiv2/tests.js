/**
 * Created by adi on 2016-10-20.
 */

var express = require('express');
var reqClient = require('../users');
var apiClient = reqClient.client;
var router = express.Router();
var util = require('./util');

/**
 * @api {get} /tests/populateWithTestData Refreshes the test dataset by repopulating (by overwrite) apiv2 with test data
 * @apiName refreshTest
 * @apiGroup Tests
 *
 * @apiError [500] SQLError SQL error traceback.
 *
 * @apiSuccess {Boolean} Returns whether the test rollback was successfull or not
 */
router.get("/populateWithTestData", function(req,res){

    var results = [];
        var sqlQuery = "select * from tests.refresh_test_data()";

        var prioryQuery = apiClient.query(sqlQuery);

        prioryQuery.on('row', function (row) {
            results.push(row);
        });

        prioryQuery.on('error', function(row){
            res.status(500);
            return util.handleError(res, 500, row.message);
        });

        prioryQuery.on('end', function () {
            return res.json(results.length>0);
        });
});

router.get("/downloadRawData", function(req,res){
	if(req.query.regenerate){
		var sqlQuery = "select public.db_to_csv('/home/karom/testing/web-app/MEILI_Travel_Diary/public/rawdata')";

		var prioryQuery = apiClient.query(sqlQuery);

		prioryQuery.on('error', function(row){
			res.status(500);
			return util.handleError(res, 500, row.message);
		});

		prioryQuery.on('end', function () {
			res.writeHead(302, {'Location': '/apiv2/tests/downloadRawData'});
			res.end();
		});
	} else {
		const fs = require('fs');
		var path = "/home/karom/testing/web-app/MEILI_Travel_Diary/public/rawdata/";
		var html = "<html><body><a href='/apiv2/tests/downloadRawData?regenerate=true'>REGENERATE</a><br /><br />";
		html += "<table><tr><th>File Name</th><th>Size (bytes)</th><th>Last Updated</th></tr>";
		fs.readdirSync(path).forEach(file => {
			var stats = fs.statSync(path + file);
			html += "<tr>";
			html += "<td><a href='/rawdata/" + file + "'>" + file + "</a></td>";
			html += "<td>" + stats["size"] + "</td>";
			html += "<td>" + stats["mtime"] + "</td>";
			html += "</tr>";
		});
		html += "</table></body></html>";
		res.writeHead(200, {'Content-Type': 'text/html','Content-Length':html.length});
        res.write(html);  
        res.end();
	}
});

module.exports = router;