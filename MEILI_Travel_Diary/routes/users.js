/*
 MEILI Travel Diary - web interface that allows to annotate GPS trajectories
 fused with accelerometer readings into travel diaries

 Copyright (C) 2014-2016 Adrian C. Prelipcean - http://adrianprelipcean.github.io/
 Copyright (C) 2016 Badger AB - https://github.com/Badger-MEILI

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

var express = require('express');
var router = express.Router();
var passport = require('passport');
var pg = require('pg');
var credentials = require('./database');
var segmenter = require('./segmenter');

var myClient = new pg.Client(credentials.connectionString);
var pool = segmenter.pool;

//Connect to the database with one client specific to each user to avoid overflow of clients
myClient.connect(function (err) {
    if (err) {
        return console.error('could not connect to postgres', err);
    } else console.log('connection successfull');
});

var admin = require('./config/firebase_config');

/**
 * Checks if the user is logged in or not
 */
router.get('/loggedin', function (req, res) {
    var checkMe = undefined;
    console.log('request is authenticated');
    console.log(req.isAuthenticated());
    if (req.user != undefined) checkMe = req.user.userId + ", " + req.user.userName;
    console.log(checkMe);
    res.send(checkMe + "");
});

/**
 * Grant access to user after handshake is complete
 */
router.post('/login', passport.authenticate('local'), function (req, res) {
    var user_id = {
        'userId': req.user.userId
    };
    console.log(user_id);

    res.send(JSON.stringify(user_id));
});

/**
 * Performs handshake via passport when the user is logging in
 */
router.get('/login', function (req, res) {
    res.send(req.user);
});

router.post('/loginWebView', passport.authenticate('local', {
    successRedirect: '/#!/map?previewMode=true',
    failureRedirect: '/#!/login'
}));

router.get('/loginChrome', passport.authenticate('token', {
    successRedirect: '/#!/map?previewMode=true',
    failureRedirect: '/#!/login'
}));

router.post('/loginDummy', function (req, res) {
    res.send(req.body);
});

/**
 * Logs out the user sesion
 */
router.post('/logout', function (req, res) {
    req.logOut();
    res.send(200);
});

/**
 * Login and perform handshake
 */
router.post('/loginDevice', function (req, res) {
    var uid = null;
    var results = [];
    // Grab data from http request
    var data = {
        username: req.body.username,
        password: req.body.password
    };

    console.log('logging in user ' + data.username);
    var prioryQuery = myClient.query("SELECT login_user as id FROM raw_data.login_user($1,$2)", [data.username, data.password]);
    console.log(prioryQuery);

    prioryQuery.on('row', function (row) {
        uid = row["id"];
        console.log('login success uid:', uid);
    });

    prioryQuery.on('end', function () {

        if (uid == null) {
            console.log('incorrect login for ' + data.username);
            return res.end("incorrect");
        } else {
            var prioryQuery2 = myClient.query("SELECT id, device_session FROM raw_data.user_table WHERE id = $1", [uid]);
            prioryQuery2.on('row', function (row2) {
                results.push(row2);
                results.push(data.username);
            });

            prioryQuery2.on('end', function () {
                if (results.length > 0) {
                    return res.json(results);
                } else {
                    return res.end("incorrect");
                }
            });
        }
    });
});

/**
 * Login and perform handshake
 */
router.post('/loginUser', function (req, res) {
    var results = [];
    var alreadyExists = false;
    // Grab data from http request
    var data = {
        username: req.body.username,
        password: req.body.password
    };

    console.log('logging in user ' + data.username);
    var prioryQuery = myClient.query("SELECT login_user as id FROM raw_data.login_user($1,$2)", [data.username, data.password]);
    console.log(prioryQuery);

    prioryQuery.on('row', function (row) {
        alreadyExists = true;
        results.push(row);
        results.push(data.username);
    });

    prioryQuery.on('end', function () {

        if (results.length == 0) {
            console.log('incorrect login for ' + data.username);
            res.end("incorrect");
        } else return res.json(results);
    });
});

/**
 * Mostly for debug purposes -> forces the generation of trips and triplegs
 */
router.get('/generateTripsAndTriplegsOfUsers', function (req, res) {
    var user_id = req.query.userId;
    console.log('generating for user ' + user_id);
    segmenter.generateTrips(user_id);
    return res.json('success');
});

/**
 * Mostly for debug purposes -> forces the generation of trips and triplegs
 */
router.get('/generateTriplegsOfUsers', function (req, res) {
    var user_id = req.query.userId;
    console.log('generating for user ' + user_id);
    segmenter.generateTriplegsExposed(user_id);
    return res.json('success');
});

/**
 * Insert text from contact form into the database
 */
router.post('/contactForm', function (req, res) {
    var results = [];
    var data = req.body;

    var prioryQuery = myClient.query("Insert into contact_form(contact_name, email_address, phone_number, message) " +
        "values($1,$2,$3,$4)",
        [data.contactName, data.emailAddress, data.phoneNumber, data.message]);

    prioryQuery.on('row', function (row) {
        results.push(row);
    });

    prioryQuery.on('end', function () {
        return res.json(results);
    });
});


/**
 * Register new user
 * In - user details: username, password, phone_model, phone_os
 */
router.post('/registerUser', function (req, res) {

    var results = [];
    var uid = null;

    // Grab data from http request
    var data = {
        username: req.body.username,
        password: req.body.password,
        phone_model: req.body.phone_model,
        phone_os: req.body.phone_os,
        phone_number: req.body.phone_number,
        reg_no: req.body.reg_no
    };

    console.log('registering a new user' + req.body.username);

    // Check if the username is already taken
    pool.query("SELECT id FROM raw_data.user_table where username = $1 AND username LIKE '%@%'", [data.username], function (err, result) {

        if (err) {
            console.log('failed to register user');
            res.end("failed to register user");
            return "email exists";
        }

        if (result.rows.length > 0) {
            console.log('email exists');
            // Inform the user that the username has been already taken
            res.end("email exists");
            return "email exists";
        } else if (data.phone_number.trim() != "") {
            pool.query("SELECT id FROM raw_data.user_table where phone_number = $1", [data.phone_number], function (err2, result2) {
                if (result2.rows.length > 0) {
                    res.end("phonenumber exists");
                    return "phonenumber exists";
                } else {
                    pool.query("SELECT reg_num FROM raw_data.reg_num_list where reg_num = $1", [data.reg_no], function (err3, result3) {
                        if (result3.rows.length > 0) {
                            // SQL Query > Insert Data
                            // New user name
                            // console.log('inserting user in the database');
                            if (data.username.trim() == "") {
                                data.username = data.phone_number;
                            }

                            admin.auth().createUser({
                                email: (data.username.includes("@") ? data.username : `${data.username}@mei.li`),
                                password: data.password
                            }).then((user) => {
                                var query = myClient.query("select register_user as id from raw_data.register_user($1, $2, $3, $4, $5, $6)",
                                    [data.username, data.password, data.phone_model, data.phone_os, data.phone_number, data.reg_no]);

                                // Stream results back one row at a time
                                query.on('row', function (row) {
                                    console.log('insert successfull');
                                    uid = row["id"];
                                });

                                query.on('end', function () {
                                    if (uid) {
                                        var query2 = myClient.query("select id, device_session from raw_data.user_table where id=$1", [uid]);
                                        query2.on('row', function (row2) {
                                            results.push(row2);
                                        });

                                        query2.on('end', function () {
                                            console.log(results);
                                            return res.json(results);
                                        });
                                    } else {
                                        return res.json(results);
                                    }
                                });
                            });
                        } else {
                            res.end("invalid regno");
                            return "invalid regno";
                        }
                    });
                }
            });
        } else {
            if (data.username.trim() == "") {
                res.end("invalid data");
                return "invalid data";
            } else {
                pool.query("SELECT reg_num FROM raw_data.reg_num_list where reg_num = $1", [data.reg_no], function (err3, result3) {
                    if (result3.rows.length > 0) {
                        // SQL Query > Insert Data
                        // New user name
                        // console.log('inserting user in the database');
                        if (data.username.trim() == "") {
                            data.username = data.phone_number;
                        }

                        admin.auth().createUser({
                            email: (data.username.includes("@") ? data.username : `${data.username}@mei.li`),
                            password: data.password
                        }).then((user) => {
                            var query = myClient.query("select register_user as id from raw_data.register_user($1, $2, $3, $4, $5, $6)",
                                [data.username, data.password, data.phone_model, data.phone_os, data.phone_number, data.reg_no]);

                            // Stream results back one row at a time
                            query.on('row', function (row) {
                                console.log('insert successfull');
                                uid = row["id"];
                            });

                            query.on('end', function () {
                                if (uid) {
                                    var query2 = myClient.query("select id, device_session from raw_data.user_table where id=$1", [uid]);
                                    query2.on('row', function (row2) {
                                        results.push(row2);
                                    });

                                    query2.on('end', function () {
                                        console.log(results);
                                        return res.json(results);
                                    });
                                } else {
                                    return res.json(results);
                                }
                            });
                        });
                    } else {
                        res.end("invalid regno");
                        return "invalid regno";
                    }
                });
            }
        }
    });
});

/**
 * Description of how the user interactis via the client
 */
router.post('/insertLog', function (req, res) {
    res.end("success");
    return "success";
});


/**
 * Insert a location from the iOS devices
 */
router.post('/insertLocationsIOSTest', function (req, res) {

    console.log('started logging test ');
    var data = JSON.parse(req.body.dataToUpload);

    console.log(req.body.dataToUpload);

    var user_ip = false;
    if (req.headers['x-forwarded-for']) {
        user_ip = req.headers['x-forwarded-for'].split(', ')[0];
    };

    user_ip = user_ip || req.connection.remoteAddress || req.socket.remoteAddress || req.connection.socket.remoteAddress;


    var sql = "INSERT INTO raw_data.location_table (upload,  accuracy_, altitude_, bearing_, lat_, lon_, time_, speed_, satellites_, user_id, size, totalismoving, totalmax, totalmean, totalmin," +
        "totalnumberofpeaks, totalnumberofsteps, totalstddev, " +
        "xismoving, xmaximum, xmean, xminimum, xnumberofpeaks, xstddev," +
        "yismoving, ymax, ymean, ymin, ynumberofpeaks, ystddev, zismoving, zmax, zmean, zmin, znumberofpeaks, zstddev, " +
        "provider, userip" +
        ")"; //+" VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37)";

    var values = [];
    var userId = 0;

    for (var i = 0; i < data.length; i++) {
        var object = [];
        userId = data[i].userid;
        object.push("'" + data[i].upload + "'", "'" + data[i].accuracy + "'", "'" + data[i].altitude + "'", "'" + data[i].bearing + "'", "'" + data[i].latitude + "'", "'" + data[i].longitude + "'",
            "'" + data[i].time_ + "000'", "'" + data[i].speed_ + "'", "'" + data[i].satellites_ + "'", "'" + data[i].userid + "'",
            "'" + data[i].size + "'", "'" + data[i].totalIsMoving + "'", "'" + data[i].totalMax + "'", "'" + data[i].totalMean + "'", "'" + data[i].totalMin + "'",
            "'" + data[i].totalNumberOfPeaks + "'", "'" + data[i].totalNumberOfSteps + "'", "'" + data[i].totalStdDev + "'",
            "'" + data[i].xIsMoving + "'", "'" + data[i].xMax + "'", "'" + data[i].xMean + "'", "'" + data[i].xMin + "'", "'" + data[i].xNumberOfPeaks + "'", "'" + data[i].xStdDev + "'",
            "'" + data[i].yIsMoving + "'", "'" + data[i].yMax + "'", "'" + data[i].yMean + "'", "'" + data[i].yMin + "'", "'" + data[i].yNumberOfPeask + "'", "'" + data[i].yStdDev + "'",
            "'" + data[i].zIsMoving + "'", "'" + data[i].zMax + "'", "'" + data[i].zMean + "'", "'" + data[i].zMin + "'", "'" + data[i].zNumberOfPeaks + "'", "'" + data[i].zStdDev + "'",
            "'maybeGPS'", "'user_ip_test'");
        values.push("(" + object.toString() + ")");
    }

    if (data.length > 0) {
        pool.query(sql + "values " + values.toString() + " ON CONFLICT ON CONSTRAINT location_table_user_id_time__key DO NOTHING;", function (err, result) {

            if (err) {
                res.end("failure");
                console.log('error with sql function ' + sql + " values " + values.toString());
                console.log(err);
            } else {
                res.end("success");
                // After a batch of insertions from the client, try and segment all residue data that are not already part of any trip
                // NOTE - this will probably make nodeJS hang since it is an intensive operation, offload to client based segmentation as soon as a final segmentation strategy has been decided on.
                segmenter.generateTrips(userId);
            }
        });

        console.log('ended logging test 1');

    } else {
        console.log('ended logging test 2');

        res.end("failure");
    }

    /*var sql = "INSERT INTO raw_data.location_table ("+
        "upload,  accuracy_, altitude_, bearing_, lat_, lon_, time_, speed_, satellites_, user_id, "+
        "size, totalismoving, totalmax, totalmean, totalmin, totalnumberofpeaks, totalnumberofsteps, totalstddev, xismoving, xmaximum, "+
        "xmean, xminimum, xnumberofpeaks, xstddev, yismoving, ymax, ymean, ymin, ynumberofpeaks, ystddev, "+
        "zismoving, zmax, zmean, zmin, znumberofpeaks, zstddev, provider, userip) " +
        "VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38)";

    var values = [];
    var userId = 0;

    for (var i = 0; i < data.length; i++) {
        userId = data[i].userid;
        values = [data[i].upload,data[i].accuracy,data[i].altitude,data[i].bearing,data[i].latitude,data[i].longitude,
            data[i].time_ + "000",data[i].speed_,data[i].satellites_,data[i].userid,
            data[i].size,data[i].totalIsMoving,data[i].totalMax,data[i].totalMean,data[i].totalMin,
            data[i].totalNumberOfPeaks,data[i].totalNumberOfSteps,data[i].totalStdDev,
            data[i].xIsMoving,data[i].xMax,data[i].xMean,data[i].xMin,data[i].xNumberOfPeaks,data[i].xStdDev,
            data[i].yIsMoving,data[i].yMax,data[i].yMean,data[i].yMin,data[i].yNumberOfPeask,data[i].yStdDev,
            data[i].zIsMoving,data[i].zMax,data[i].zMean,data[i].zMin,data[i].zNumberOfPeaks,data[i].zStdDev,
            "maybeGPS", "user_ip_test"];

        pool.query(sql,values, function (err, result) {

            if (err) {
                res.end("failure");
                console.log('error with sql function ' + sql + " values (" + values.toString()+")");
                console.log(err);
            } else {
                res.end("success");
                // After a batch of insertions from the client, try and segment all residue data that are not already part of any trip
                // NOTE - this will probably make nodeJS hang since it is an intensive operation, offload to client based segmentation as soon as a final segmentation strategy has been decided on.
                segmenter.generateTrips(userId);
            }
        });

        console.log('ended logging test 1');

    }
    
    if (data.length = 0) {
        console.log('ended logging test 2');

        res.end("failure");
    }*/
});

/**
 * Insert a location from the iOS devices
 */
router.post('/insertLocationsIOS', function (req, res) {

    var data = JSON.parse(req.body.dataToUpload);

    console.log(req.body.dataToUpload);

    var sql = "INSERT INTO raw_data.location_table (upload,  accuracy_, altitude_, bearing_, lat_, lon_, time_, speed_, satellites_, user_id, size, totalismoving, totalmax, totalmean, totalmin," +
        "totalnumberofpeaks, totalnumberofsteps, totalstddev, " +
        "xismoving, xmaximum, xmean, xminimum, xnumberofpeaks, xstddev," +
        "yismoving, ymax, ymean, ymin, ynumberofpeaks, ystddev, zismoving, zmax, zmean, zmin, znumberofpeaks, zstddev, " +
        "provider" + //, user_ip" +
        ")"; //+" VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37)";

    var user_ip = false;
    if (req.headers['x-forwarded-for']) {
        user_ip = req.headers['x-forwarded-for'].split(', ')[0];
    };

    if (req.connection) user_ip = user_ip || req.connection.remoteAddress;
    if (req.socket) user_ip = user_ip || req.socket.remoteAddress;
    if (req.connection.socket) user_ip = user_ip || req.connection.socket.remoteAddress;

    console.log('request with ip ' + user_ip);
    var values = [];
    var userId = 0;

    for (var i = 0; i < data.length; i++) {
        var object = [];
        userId = data[i].userid;
        object.push("'" + data[i].upload + "'", "'" + data[i].accuracy + "'", "'" + data[i].altitude + "'", "'" + data[i].bearing + "'", "'" + data[i].latitude + "'", "'" + data[i].longitude + "'",
            "'" + data[i].time_ + "000'", "'" + data[i].speed_ + "'", "'" + data[i].satellites_ + "'", "'" + data[i].userid + "'",
            "'" + data[i].size + "'", "'" + data[i].totalIsMoving + "'", "'" + data[i].totalMax + "'", "'" + data[i].totalMean + "'", "'" + data[i].totalMin + "'",
            "'" + data[i].totalNumberOfPeaks + "'", "'" + data[i].totalNumberOfSteps + "'", "'" + data[i].totalStdDev + "'",
            "'" + data[i].xIsMoving + "'", "'" + data[i].xMax + "'", "'" + data[i].xMean + "'", "'" + data[i].xMin + "'", "'" + data[i].xNumberOfPeaks + "'", "'" + data[i].xStdDev + "'",
            "'" + data[i].yIsMoving + "'", "'" + data[i].yMax + "'", "'" + data[i].yMean + "'", "'" + data[i].yMin + "'", "'" + data[i].yNumberOfPeask + "'", "'" + data[i].yStdDev + "'",
            "'" + data[i].zIsMoving + "'", "'" + data[i].zMax + "'", "'" + data[i].zMean + "'", "'" + data[i].zMin + "'", "'" + data[i].zNumberOfPeaks + "'", "'" + data[i].zStdDev + "'", "'maybeGPS'"); //, "'" + user_ip + "'");
        values.push("(" + object.toString() + ")");
    }
    if (data.length > 0) {
        pool.query(sql + "values " + values.toString() + " ON CONFLICT ON CONSTRAINT location_table_user_id_time__key DO NOTHING;", function (err, result) {

            if (err) {
                res.end("failure");
                console.log('error with sql function ' + sql + " values " + values.toString());
                console.log(err);
            } else {
                res.end("success");
                // After a batch of insertions from the client, try and segment all residue data that are not already part of any trip
                // NOTE - this will probably make nodeJS hang since it is an intensive operation, offload to client based segmentation as soon as a final segmentation strategy has been decided on.
                segmenter.generateTrips(userId);
            }
        });
    } else res.end("failure");
    /*
    var sql = "INSERT INTO raw_data.location_table (upload,  accuracy_, altitude_, bearing_, lat_, lon_, time_, speed_, satellites_, user_id, size, totalismoving, totalmax, totalmean, totalmin," +
        "totalnumberofpeaks, totalnumberofsteps, totalstddev, " +
        "xismoving, xmaximum, xmean, xminimum, xnumberofpeaks, xstddev," +
        "yismoving, ymax, ymean, ymin, ynumberofpeaks, ystddev, zismoving, zmax, zmean, zmin, znumberofpeaks, zstddev, " +
        "provider" + //, user_ip" +
        ") VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37)";

    var user_ip = false;
    if (req.headers['x-forwarded-for']) {
        user_ip = req.headers['x-forwarded-for'].split(', ')[0];
    };

    if (req.connection) user_ip = user_ip || req.connection.remoteAddress;
    if (req.socket) user_ip = user_ip || req.socket.remoteAddress;
    if (req.connection.socket) user_ip = user_ip || req.connection.socket.remoteAddress;

    console.log('request with ip ' + user_ip);
    var values = [];
    var userId = 0;

    for (var i = 0; i < data.length; i++) {
        userId = data[i].userid;

        values = [data[i].upload,data[i].accuracy,data[i].altitude,data[i].bearing,data[i].latitude,data[i].longitude,
            data[i].time_ + "000",data[i].speed_ ,data[i].satellites_,data[i].userid,
            data[i].size,data[i].totalIsMoving,data[i].totalMax,data[i].totalMean,data[i].totalMin,
            data[i].totalNumberOfPeaks,data[i].totalNumberOfSteps,data[i].totalStdDev,
            data[i].xIsMoving,data[i].xMax,data[i].xMean,data[i].xMin,data[i].xNumberOfPeaks,data[i].xStdDev,
            data[i].yIsMoving,data[i].yMax,data[i].yMean,data[i].yMin,data[i].yNumberOfPeask,data[i].yStdDev,
            data[i].zIsMoving,data[i].zMax,data[i].zMean,data[i].zMin,data[i].zNumberOfPeaks,data[i].zStdDev, "maybeGPS"];

        pool.query(sql,values, function (err, result) {

            if (err) {
                res.end("failure");
                console.log('error with sql function ' + sql + " values (" + values.toString()+")");
                console.log(err);
            } else {
                res.end("success");
                // After a batch of insertions from the client, try and segment all residue data that are not already part of any trip
                // NOTE - this will probably make nodeJS hang since it is an intensive operation, offload to client based segmentation as soon as a final segmentation strategy has been decided on.
                segmenter.generateTrips(userId);
            }
        });
    }
    
    if (data.length = 0)  res.end("failure");*/
});

/**
 * Insert a location from the Android devices
 */
router.post('/insertLocationsAndroid', function (req, res) {
    var data = JSON.parse(req.body.embeddedLocations_);

    var userId = 0;
    var sql = "INSERT INTO raw_data.location_table (upload,  accuracy_, altitude_, bearing_, lat_, lon_, time_, speed_, satellites_, user_id, size, totalismoving, totalmax, totalmean, totalmin," +
        "totalnumberofpeaks, totalnumberofsteps, totalstddev, " +
        "xismoving, xmaximum, xmean, xminimum, xnumberofpeaks, xstddev," +
        "yismoving, ymax, ymean, ymin, ynumberofpeaks, ystddev, zismoving, zmax, zmean, zmin, znumberofpeaks, zstddev, " +
        "provider, " +
        "pref_min_acc, pref_min_dist, pref_min_time, pref_acc_threshold, pref_acc_period, pref_acc_saving" +
        ")"; //+" VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37)";


    var values = [];
    for (var i = 0; i < data.length; i++) {
        var object = [];
        var locationObject = data[i].currentLocation;
        var accelerometerObject = data[i].currentAcc;
        var parameterObject = data[i].currentParams;
        userId = locationObject.user_id;
        object.push("'true'", "'" + locationObject.accuracy_ + "'", "'" + locationObject.altitude_ + "'", "'" + locationObject.bearing_ + "'", "'" + locationObject.lat_ + "'", "'" + locationObject.lon_ + "'",
            "'" + locationObject.time_ + "'", "'" + locationObject.speed_ + "'", "'" + locationObject.satellites_ + "'", "'" + locationObject.user_id + "'",
            "'" + accelerometerObject.size + "'", "'" + accelerometerObject.totalIsMoving + "'", "'" + accelerometerObject.totalMax + "'", "'" + accelerometerObject.totalMean + "'", "'" + accelerometerObject.totalMin + "'",
            "'" + accelerometerObject.totalNumberOfPeaks + "'", "'" + accelerometerObject.totalNumberOfSteps + "'", "'" + accelerometerObject.totalStdDev + "'",
            "'" + accelerometerObject.xIsMoving + "'", "'" + accelerometerObject.xMaximum + "'", "'" + accelerometerObject.xMean + "'", "'" + accelerometerObject.xMinimum + "'", "'" + accelerometerObject.xNumberOfPeaks + "'", "'" + accelerometerObject.xStdDev + "'",
            "'" + accelerometerObject.yIsMoving + "'", "'" + accelerometerObject.yMax + "'", "'" + accelerometerObject.yMean + "'", "'" + accelerometerObject.yMin + "'", "'" + accelerometerObject.yNumberOfPeaks + "'", "'" + accelerometerObject.yStdDev + "'",
            "'" + accelerometerObject.zIsMoving + "'", "'" + accelerometerObject.zMax + "'", "'" + accelerometerObject.zMean + "'", "'" + accelerometerObject.zMin + "'", "'" + accelerometerObject.zNumberOfPeaks + "'", "'" + accelerometerObject.zStdDev + "'", "'" + locationObject.provider + "'", "'" + parameterObject.pref_min_acc + "'", "'" + parameterObject.pref_min_dist + "'", "'" + parameterObject.pref_min_time + "'", "'" + parameterObject.pref_acc_threshold + "'", "'" + parameterObject.pref_acc_period + "'", "'" + parameterObject.pref_acc_saving + "'");
        values.push("(" + object.toString() + ")");
    }
    if (data.length > 0) {

        pool.query(sql + "values " + values.toString() + " ON CONFLICT ON CONSTRAINT location_table_user_id_time__key DO NOTHING;", function (err, result) {


            if (err) {
                res.end("failure");
                console.log('error with sql function ' + sql + " values " + values.toString());
                console.log(err);
            } else {
                //res.end("OK");
                segmenter.generateTrips(userId);
            }
        });
    } //else res.end("failure");
    /*
    var userId = 0;
    var sql = "INSERT INTO raw_data.location_table (upload,  accuracy_, altitude_, bearing_, lat_, lon_, time_, speed_, satellites_, user_id, size, totalismoving, totalmax, totalmean, totalmin," +
        "totalnumberofpeaks, totalnumberofsteps, totalstddev, " +
        "xismoving, xmaximum, xmean, xminimum, xnumberofpeaks, xstddev," +
        "yismoving, ymax, ymean, ymin, ynumberofpeaks, ystddev, zismoving, zmax, zmean, zmin, znumberofpeaks, zstddev, " +
        "provider, " +
        "pref_min_acc, pref_min_dist, pref_min_time, pref_acc_threshold, pref_acc_period, pref_acc_saving" +
        ") VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43)";


    var values = [];
    for (var i = 0; i < data.length; i++) {
        var locationObject = data[i].currentLocation;
        var accelerometerObject = data[i].currentAcc;
        var parameterObject = data[i].currentParams;
        userId = locationObject.user_id;

        values = ["true",locationObject.accuracy_ ,locationObject.altitude_,locationObject.bearing_,locationObject.lat_,locationObject.lon_,
            locationObject.time_,locationObject.speed_,locationObject.satellites_ ,locationObject.user_id,
            accelerometerObject.size,accelerometerObject.totalIsMoving,accelerometerObject.totalMax,accelerometerObject.totalMean,accelerometerObject.totalMin,
            accelerometerObject.totalNumberOfPeaks,accelerometerObject.totalNumberOfSteps,accelerometerObject.totalStdDev,
            accelerometerObject.xIsMoving, accelerometerObject.xMaximum,accelerometerObject.xMean,accelerometerObject.xMinimum,accelerometerObject.xNumberOfPeaks, accelerometerObject.xStdDev,
            accelerometerObject.yIsMoving, accelerometerObject.yMax, accelerometerObject.yMean,accelerometerObject.yMin , accelerometerObject.yNumberOfPeaks , accelerometerObject.yStdDev,
            accelerometerObject.zIsMoving , accelerometerObject.zMax , accelerometerObject.zMean , accelerometerObject.zMin, accelerometerObject.zNumberOfPeaks, accelerometerObject.zStdDev, locationObject.provider , parameterObject.pref_min_acc , parameterObject.pref_min_dist, parameterObject.pref_min_time, parameterObject.pref_acc_threshold, parameterObject.pref_acc_period, parameterObject.pref_acc_saving];
        
        pool.query(sql,values, function (err, result) {

            if (err) {
                res.end("failure");
                console.log('error with sql function ' + sql + " values (" + values.toString()+")");
                console.log(err);
            } else {
                res.end("OK");
                segmenter.generateTrips(userId);
            }
        });

    }
    
    if (data.length = 0) res.end("failure");*/

    var data_acc = JSON.parse(req.body.accelerometers_);

    var userId_acc = 0;
    var sql_acc = "INSERT INTO raw_data.accelerometer_table(user_id, current_x, current_y, current_z, min_x, min_y, min_z, max_x, max_y, max_z, mean_x, mean_y, mean_z, time_)"; //+" VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37)";

    var values_acc = [];
    for (var i = 0; i < data_acc.length; i++) {
        var object = [];
        var accel = data_acc[i];

        userId_acc = accel.user_id;
        object.push("'" + userId_acc + "'", "'" + accel.current_x + "'", "'" + accel.current_y + "'", "'" + accel.current_z + "'", "'" + accel.min_x + "'", "'" + accel.min_y + "'", "'" + accel.min_z + "'", "'" + accel.max_x + "'", "'" + accel.max_y + "'", "'" + accel.max_z + "'", "'" + accel.mean_x + "'", "'" + accel.mean_y + "'", "'" + accel.mean_z + "'", "'" + accel.time_ + "'");
        values_acc.push("(" + object.toString() + ")");
    }

    if (data_acc.length > 0) {

        pool.query(sql_acc + " values " + values_acc.toString(), function (err, result) {

            if (err) {
                res.end("failure");
                console.log('error with sql function ' + sql_acc + " values " + values_acc.toString());
                console.log(err);
            }
            /*else {
                           res.end("OK");
                       }*/
        });
    }
    /*else {
           res.end("failure");
       }*/

    if (data.length > 0 || data_acc.length > 0) {
        res.end("OK");
    } else {
        res.end("failure");
    }

});

module.exports = router;
module.exports.client = myClient;