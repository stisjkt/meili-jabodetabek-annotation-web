--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.10
-- Dumped by pg_dump version 9.6.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: apiv2; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA apiv2;


ALTER SCHEMA apiv2 OWNER TO postgres;

--
-- Name: SCHEMA apiv2; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA apiv2 IS 'Stores the data that can be used in the CRUD operations for trips and triplegs';


--
-- Name: dashboard; Type: SCHEMA; Schema: -; Owner: meili
--

CREATE SCHEMA dashboard;


ALTER SCHEMA dashboard OWNER TO meili;

--
-- Name: learning_processes; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA learning_processes;


ALTER SCHEMA learning_processes OWNER TO postgres;

--
-- Name: raw_data; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA raw_data;


ALTER SCHEMA raw_data OWNER TO postgres;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: transport_cost_type; Type: TYPE; Schema: apiv2; Owner: postgres
--

CREATE TYPE apiv2.transport_cost_type AS (
	tripleg_id integer,
	tariff bigint,
	toll bigint,
	parking bigint
);


ALTER TYPE apiv2.transport_cost_type OWNER TO postgres;

--
-- Name: ap_get_activities(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.ap_get_activities(trip_id integer) RETURNS json
    LANGUAGE sql
    AS $_$ 

SELECT ap_get_activities

FROM learning_processes.ap_get_activities($1);$_$;


ALTER FUNCTION apiv2.ap_get_activities(trip_id integer) OWNER TO postgres;

--
-- Name: ap_get_destinations_close_by(double precision, double precision, bigint, bigint); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.ap_get_destinations_close_by(latitude double precision, longitude double precision, user_id bigint, destination_poi_id bigint) RETURNS json
    LANGUAGE sql
    AS $_$ 
SELECT ap_get_destinations_close_by from learning_processes.ap_get_destinations_close_by($1,$2,$3,$4)
$_$;


ALTER FUNCTION apiv2.ap_get_destinations_close_by(latitude double precision, longitude double precision, user_id bigint, destination_poi_id bigint) OWNER TO postgres;

--
-- Name: ap_get_mode_of_tripleg_gt_json(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.ap_get_mode_of_tripleg_gt_json(triplegid integer) RETURNS json
    LANGUAGE sql
    AS $_$

	select array_to_json(

	array_cat(

			array_agg(

				(SELECT x FROM (

					(SELECT 100 as accuracy, 

					id, name_ as name, name_sv, 1 as level, null as tariff, null as toll, null as parking 

					FROM apiv2.travel_mode_table where id = (select av.transportation_type from apiv2.processed_triplegs av where av.tripleg_id = $1))

					) x

				)

			),

			array_agg(

				(SELECT x FROM (

					(SELECT 100 as accuracy,

					tmt.id, tmt.name_ as name, tmt.name_en as name_sv, 2 as level, tgt.tariff, tgt.toll, tgt.parking

					FROM apiv2.triplegs_gt tgt, apiv2.travel_mode2_table tmt WHERE tgt.transportation_type2=tmt.id AND tgt.tripleg_inf_id=$1)

					) x

				)

			)

		)

	) as mode; 

	$_$;


ALTER FUNCTION apiv2.ap_get_mode_of_tripleg_gt_json(triplegid integer) OWNER TO postgres;

--
-- Name: FUNCTION ap_get_mode_of_tripleg_gt_json(triplegid integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.ap_get_mode_of_tripleg_gt_json(triplegid integer) IS 'Gets the travel mode of annotated triplegs

';


--
-- Name: ap_get_probable_modes2_of_tripleg_json(integer, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.ap_get_probable_modes2_of_tripleg_json(triplegid integer, transportation_type_id integer) RETURNS json
    LANGUAGE sql
    AS $_$

SELECT ap_get_probable_modes2_of_tripleg_json FROM learning_processes.ap_get_probable_modes2_of_tripleg_json($1, $2)

$_$;


ALTER FUNCTION apiv2.ap_get_probable_modes2_of_tripleg_json(triplegid integer, transportation_type_id integer) OWNER TO postgres;

--
-- Name: ap_get_probable_modes_of_tripleg_json(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.ap_get_probable_modes_of_tripleg_json(triplegid integer) RETURNS json
    LANGUAGE sql
    AS $_$
SELECT ap_get_probable_modes_of_tripleg_json FROM learning_processes.ap_get_probable_modes_of_tripleg_json($1)
$_$;


ALTER FUNCTION apiv2.ap_get_probable_modes_of_tripleg_json(triplegid integer) OWNER TO postgres;

--
-- Name: ap_get_purposes(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.ap_get_purposes(trip_id integer) RETURNS json
    LANGUAGE sql
    AS $_$ 
SELECT ap_get_purposes FROM learning_processes.ap_get_purposes($1);
$_$;


ALTER FUNCTION apiv2.ap_get_purposes(trip_id integer) OWNER TO postgres;

--
-- Name: ap_get_transit_pois_of_tripleg_within_buffer(bigint, bigint, bigint, double precision, bigint); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.ap_get_transit_pois_of_tripleg_within_buffer(user_id bigint, from_time bigint, to_time bigint, buffer_in_meters double precision, transition_poi_id bigint) RETURNS json
    LANGUAGE sql
    AS $_$
with 
point as (select lat_, lon_ from raw_data.location_table where user_id = $1 and time_ between $2 and $3 
order by time_ desc limit 1), 
point_geometry as (select st_setsrid(st_makepoint(lon_, lat_),4326) as orig_pt_geom from point),
        -- [HACK] Force cast to geography to specify ellipsoid distances
personal_transition_within_buffer as (SELECT gid as osm_id, type_ AS type, name_ as name, lat_ as lat, lon_ as lon, 1 as added_by_user from apiv2.poi_transportation as p1, point_geometry as p2 where (st_dwithin(p2.orig_pt_geom::geography,p1.geom::geography, $4) or gid = $5) and declared_by_user = true),
        -- [HACK] Force cast to geography to specify ellipsoid distances
public_transition_within_buffer as (SELECT gid as osm_id, type_ AS type, name_ as name, lat_ as lat, lon_ as lon, -1 as added_by_user from apiv2.poi_transportation as p1, point_geometry as p2 where (st_dwithin(p2.orig_pt_geom::geography,p1.geom::geography, $4) or gid = $5) and declared_by_user = false)
select array_to_json(array_agg(x)) from (select osm_id, type, name, lat, lon, added_by_user, case when (osm_id = $5) then 100 else 0 end as accuracy from personal_transition_within_buffer union all select osm_id, type, name, lat, lon, added_by_user, case when (osm_id = $5) then 100 else 0 end as accuracy from public_transition_within_buffer) x 
$_$;


ALTER FUNCTION apiv2.ap_get_transit_pois_of_tripleg_within_buffer(user_id bigint, from_time bigint, to_time bigint, buffer_in_meters double precision, transition_poi_id bigint) OWNER TO postgres;

--
-- Name: FUNCTION ap_get_transit_pois_of_tripleg_within_buffer(user_id bigint, from_time bigint, to_time bigint, buffer_in_meters double precision, transition_poi_id bigint); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.ap_get_transit_pois_of_tripleg_within_buffer(user_id bigint, from_time bigint, to_time bigint, buffer_in_meters double precision, transition_poi_id bigint) IS 'Extracts the transportation POIs at next to the location at the end of a time period';


--
-- Name: confirm_annotation_of_trip_get_next(bigint); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.confirm_annotation_of_trip_get_next(trip_id bigint) RETURNS TABLE(status text, trip_id integer, current_trip_start_date bigint, current_trip_end_date bigint, previous_trip_end_date bigint, previous_trip_activities text, previous_trip_poi_name text, next_trip_start_date bigint, activities json, destination_places json)
    LANGUAGE sql
    AS $_$

WITH inserted_trip AS (

		INSERT INTO apiv2.trips_gt (

			trip_inf_id

			,user_id

			,from_time

			,to_time

			,type_of_trip

			,destination_poi_id

			) (

			SELECT trip_id

			,user_id

			,from_time

			,to_time

			,type_of_trip

			,destination_poi_id FROM apiv2.trips_inf WHERE trip_id = $1

			) returning user_id

			,trip_id

		)

	,inserted_triplegs AS (

		INSERT INTO apiv2.triplegs_gt (

			tripleg_inf_id

			,trip_id

			,user_id

			,from_time

			,to_time

			,type_of_tripleg

			,transportation_type

			,transportation_type2

			,tariff

			,toll

			,parking

			,transition_poi_id

			) (

			SELECT tripleg_id

			,(

				SELECT trip_id

				FROM inserted_trip

				)

			,user_id

			,from_time

			,to_time

			,type_of_tripleg

			,transportation_type

			,transportation_type2

			,tariff

			,toll

			,parking

			,transition_poi_id FROM apiv2.triplegs_inf WHERE trip_id = $1

			) returning user_id

		)

	,inserted_activities AS (

		INSERT INTO apiv2.activities_gt (

			trip_id

			,activity_id

			,activity_order

			) (

			SELECT (

				SELECT trip_id

				FROM inserted_trip

				)

			,activity_id

			,activity_order FROM apiv2.activities_inf WHERE trip_id = $1

			) returning trip_id

		)

	,distinct_user_id AS (

		SELECT DISTINCT user_id

		FROM inserted_triplegs

		)

SELECT p2.*

FROM distinct_user_id

LEFT JOIN lateral apiv2.get_next_trip_response_temp_fix(user_id::INT) p2 ON TRUE;$_$;


ALTER FUNCTION apiv2.confirm_annotation_of_trip_get_next(trip_id bigint) OWNER TO postgres;

--
-- Name: FUNCTION confirm_annotation_of_trip_get_next(trip_id bigint); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.confirm_annotation_of_trip_get_next(trip_id bigint) IS '

CONFIRMS THAT THE TRIP WAS ANNOTATED, IF THIS IS NOT PREVENTED BY TRIGGERS.

';


--
-- Name: delete_trip(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.delete_trip(trip_id integer) RETURNS TABLE(trip_id integer, current_trip_start_date bigint, current_trip_end_date bigint, previous_trip_end_date bigint, previous_trip_activities text, previous_trip_poi_name text, next_trip_start_date bigint, activities json, destination_places json)
    LANGUAGE sql
    AS $_$ 

WITH deleted_trip AS (

		UPDATE

		apiv2.trips_inf SET type_of_trip=0

		WHERE trip_id = $1 returning user_id

		),
         backup_trip AS (
            INSERT INTO apiv2.trips_inf_deleted (trip_inf_id) VALUES ($1) returning trip_inf_id
         ),
	 deleted_activities AS (

		DELETE

		FROM apiv2.activities_inf

		WHERE trip_id = $1 returning activity_id

		)

SELECT r.*

FROM deleted_trip

LEFT JOIN lateral apiv2.pagination_get_next_process(user_id::INT) r ON TRUE;$_$;


ALTER FUNCTION apiv2.delete_trip(trip_id integer) OWNER TO postgres;

--
-- Name: FUNCTION delete_trip(trip_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.delete_trip(trip_id integer) IS '

DELETES A TRIP AND RETURNS THE NEXT TRIP THAT THE USER HAS TO ANNOTATE

';


--
-- Name: delete_tripleg(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.delete_tripleg(tripleg_id_ integer) RETURNS json
    LANGUAGE plpgsql
    AS $_$
DECLARE 
response json; 
trip_id_ integer;  
BEGIN 
	trip_id_ := trip_id from apiv2.triplegs_inf where tripleg_id = $1; 
	
	DELETE FROM apiv2.triplegs_inf where tripleg_id = $1;
	
	RAISE NOTICE 'trip_id %', trip_id_;
	response:= apiv2.pagination_get_triplegs_of_trip(trip_id_); 
	RETURN response;
END;
$_$;


ALTER FUNCTION apiv2.delete_tripleg(tripleg_id_ integer) OWNER TO postgres;

--
-- Name: FUNCTION delete_tripleg(tripleg_id_ integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.delete_tripleg(tripleg_id_ integer) IS '
DELETES A TRIPLEG AND RETURNS THE MODIFIED TRIPLEGS OF THE DELETED TRIPLEGs PARRENT TRIP 
';


--
-- Name: get_commuterline_cost(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.get_commuterline_cost(tripleg_id integer) RETURNS TABLE(tariff bigint, from_ text, to_ text)
    LANGUAGE sql
    AS $_$

	WITH the_tripleg AS (
		select * from apiv2.unprocessed_triplegs WHERE tripleg_id = $1
	), start_station_id AS (
		SELECT pt.gid, pt.name_ FROM apiv2.poi_transportation pt,
			(SELECT
				lat_
				, lon_
			FROM
				raw_data.location_table l
				, the_tripleg  t
			WHERE
				t.user_id = l.user_id
				AND l.time_ >= t.from_time
				AND l.accuracy_<=50
			ORDER BY
				l.time_ ASC
			limit 1) st_pt
		ORDER BY pt.geom <#> ST_MakePoint(st_pt.lat_,st_pt.lon_) LIMIT 1
	), end_station_id AS (
		SELECT pt.gid, pt.name_ FROM apiv2.poi_transportation pt,
			(SELECT
				lat_
				, lon_
			FROM
				raw_data.location_table l
				, the_tripleg  t
			WHERE
				t.user_id = l.user_id
				AND l.time_ <= t.to_time
				AND l.accuracy_<=50
			ORDER BY
				l.time_ DESC
			limit 1) en_pt
		ORDER BY pt.geom <#> ST_MakePoint(en_pt.lat_,en_pt.lon_) LIMIT 1
	)		
	SELECT case when ss.gid=es.gid then 2000 else (select tt.tariff) end as tariff, ss.name_ as from_, es.name_ as to_ FROM apiv2.tariff_train tt, start_station_id ss, 
			end_station_id es WHERE tt.poi_from_id=ss.gid AND tt.poi_to_id=es.gid
	

$_$;


ALTER FUNCTION apiv2.get_commuterline_cost(tripleg_id integer) OWNER TO postgres;

--
-- Name: FUNCTION get_commuterline_cost(tripleg_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.get_commuterline_cost(tripleg_id integer) IS '

GET COST OF COMMUTER LINE

';


--
-- Name: get_next_trip_response_temp_fix(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.get_next_trip_response_temp_fix(user_id_ integer) RETURNS TABLE(status text, trip_id integer, current_trip_start_date bigint, current_trip_end_date bigint, previous_trip_end_date bigint, previous_trip_activities text, previous_trip_poi_name text, next_trip_start_date bigint, activities json, destination_places json)
    LANGUAGE sql
    AS $_$

WITH last_annotated_trip AS (

		SELECT trip_id

			,user_id

		FROM apiv2.processed_trips

		WHERE user_id = $1

		ORDER BY from_time DESC

			,to_time DESC limit 1

		)

SELECT l1.*

FROM last_annotated_trip l

LEFT JOIN lateral apiv2.pagination_get_gt_trip(l.user_id::INTEGER, l.trip_id) l1 ON true

UNION ALL

SELECT 'needs_annotation'

	,*

FROM apiv2.pagination_get_next_process($1)

ORDER BY STATUS DESC limit 1 $_$;


ALTER FUNCTION apiv2.get_next_trip_response_temp_fix(user_id_ integer) OWNER TO postgres;

--
-- Name: get_stream_for_stop_detection(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.get_stream_for_stop_detection(userid integer) RETURNS json
    LANGUAGE sql
    AS $_$select array_to_json(array_agg(result)) from 
(select l.*, t.* from raw_data.location_table as l, 
(SELECT COALESCE(COALESCE(max(t_inf.from_time), max(t_gt.from_time)),0) as from_time, COALESCE(COALESCE(max(t_inf.to_time), max(t_gt.to_time)),0) as to_time from apiv2.all_unprocessed_trips t_inf full outer join apiv2.processed_trips t_gt 
	on t_inf.user_id = t_gt.user_id where  t_inf.user_id = $1 or t_gt.user_id = $1) 
as t
where l.time_>= t.from_time
and l.user_id = $1
and l.accuracy_<=50
order by l.time_) result
$_$;


ALTER FUNCTION apiv2.get_stream_for_stop_detection(userid integer) OWNER TO postgres;

--
-- Name: FUNCTION get_stream_for_stop_detection(userid integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.get_stream_for_stop_detection(userid integer) IS 'Returns a stream containing all the locations that do not fall within a trip for a given user.
';


--
-- Name: get_stream_for_tripleg_detection(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.get_stream_for_tripleg_detection(userid integer) RETURNS json
    LANGUAGE sql
    AS $_$select array_to_json(array_agg(result)) from 
(select l.*, t.trip_id from raw_data.location_table as l, (select * from apiv2.trips_inf
	where from_time>= (SELECT COALESCE(COALESCE(max(t_inf.to_time), max(t_gt.to_time)),0) as to_time from 
	apiv2.all_unprocessed_triplegs t_inf full outer join apiv2.processed_triplegs t_gt 
	on t_inf.user_id = t_gt.user_id where  t_inf.user_id = $1 or t_gt.user_id = $1)
	and user_id = $1
	order by from_time, to_time) t 
where l.time_ between t.from_time and t.to_time
and l.user_id = $1
and l.accuracy_<=50 
order by l.time_, t.from_time, t.to_time) result
$_$;


ALTER FUNCTION apiv2.get_stream_for_tripleg_detection(userid integer) OWNER TO postgres;

--
-- Name: FUNCTION get_stream_for_tripleg_detection(userid integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.get_stream_for_tripleg_detection(userid integer) IS 'Returns a stream containing all the locations that do not fall within a tripleg for a given user.';


--
-- Name: insert_destination_poi(text, double precision, double precision, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.insert_destination_poi(name text, latitude double precision, longitude double precision, declaring_user_id integer) RETURNS integer
    LANGUAGE sql
    AS $_$
	INSERT INTO apiv2.pois(name_, lat_, lon_, user_id, is_personal, geom)
	VALUES ($1, $2, $3, $4, true, st_setsrid(st_makepoint($3, $2), 4326))
	RETURNING gid
$_$;


ALTER FUNCTION apiv2.insert_destination_poi(name text, latitude double precision, longitude double precision, declaring_user_id integer) OWNER TO postgres;

--
-- Name: FUNCTION insert_destination_poi(name text, latitude double precision, longitude double precision, declaring_user_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.insert_destination_poi(name text, latitude double precision, longitude double precision, declaring_user_id integer) IS '
INSERTS A NEW DESTINATION POI AS DEFINED BY A USER AND RETURNS THE ID OF THE INSERTED POINT 
';


--
-- Name: insert_stationary_trip_for_user(bigint, bigint, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.insert_stationary_trip_for_user(from_time_ bigint, to_time_ bigint, user_id_ integer) RETURNS TABLE(trip_id integer, current_trip_start_date bigint, current_trip_end_date bigint, previous_trip_end_date bigint, previous_trip_activities text, previous_trip_poi_name text, next_trip_start_date bigint, activities json, destination_places json)
    LANGUAGE plpgsql
    AS $_$

DECLARE returning_user_id INT;

	affected_trip record;

	affected_non_movement_trip_period record;

	result record;

	inserted_movement_period record;

	inserted_stationary_period record;

BEGIN

	SELECT *

	FROM apiv2.trips_inf

	WHERE type_of_trip = 1

		AND user_id = $3

		AND $1 > from_time

		AND $1 < to_time

		AND $2 > from_time

		AND $2 < to_time

	INTO affected_trip;

	-- raise notice 'Affected trip -> %', affected_trip;

	SELECT *

	FROM apiv2.trips_inf

	WHERE type_of_trip = 0

		AND user_id = $3

		AND from_time >= affected_trip.to_time

	ORDER BY from_time

		,to_time limit 1

	INTO affected_non_movement_trip_period;

	-- raise notice 'Non movement period -> %', affected_non_movement_trip_period;

	-- raise notice 'FCT UPDATING to_time -> %', affected_trip;

	UPDATE apiv2.trips_inf ti

	SET to_time = $1

	WHERE ti.trip_id = affected_trip.trip_id;

	-- raise notice 'PREPARING TO INSERT NON MOVEMENT -> %, %, %, %, %', affected_trip.user_id, $1, $2, 0, affected_trip.trip_id;

	INSERT INTO apiv2.trips_inf (

		user_id

		,from_time

		,to_time

		,type_of_trip

		,parent_trip_id

		)

	SELECT affected_trip.user_id

		,$1

		,$2

		,0

		,affected_trip.trip_id RETURNING *

	INTO inserted_stationary_period;

	-- raise notice 'FCT INSERTED NON MOVEMENT -> %', inserted_stationary_period;

	-- raise notice 'PREPARING TO INSERT MOVEMENT -> %, %, %, %, %', affected_trip.user_id, $2, affected_trip.to_time , 1, affected_trip.trip_id;

	INSERT INTO apiv2.trips_inf (

		user_id

		,from_time

		,to_time

		,type_of_trip

		,parent_trip_id

		)

	SELECT affected_trip.user_id

		,$2

		,affected_trip.to_time

		,1

		,affected_trip.trip_id RETURNING *

	INTO inserted_movement_period;

	-- raise notice 'FCT INSERTED MOVEMENT -> %', inserted_movement_period;

	INSERT INTO apiv2.triplegs_inf (

		user_id

		,from_time

		,to_time

		,type_of_tripleg

		,trip_id

		,parent_tripleg_id

		)

	SELECT inserted_stationary_period.user_id

		,inserted_stationary_period.from_time

		,inserted_stationary_period.to_time

		,1

		,inserted_stationary_period.trip_id

		,inserted_stationary_period.trip_id * (- 1);

	-- raise notice 'FCT INSERTED FIRST TRIPLEG';   	

	INSERT INTO apiv2.triplegs_inf (

		user_id

		,from_time

		,to_time

		,type_of_tripleg

		,trip_id

		,parent_tripleg_id

		)

	SELECT inserted_movement_period.user_id

		,inserted_movement_period.from_time

		,inserted_movement_period.to_time

		,1

		,inserted_movement_period.trip_id

		,inserted_movement_period.trip_id * (- 1);

	-- raise notice 'FCT INSERTED SECOND TRIPLEG';   	

	result := apiv2.pagination_get_next_process($3);

	RETURN QUERY

	SELECT *

	FROM apiv2.pagination_get_next_process($3);

END;$_$;


ALTER FUNCTION apiv2.insert_stationary_trip_for_user(from_time_ bigint, to_time_ bigint, user_id_ integer) OWNER TO postgres;

--
-- Name: FUNCTION insert_stationary_trip_for_user(from_time_ bigint, to_time_ bigint, user_id_ integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.insert_stationary_trip_for_user(from_time_ bigint, to_time_ bigint, user_id_ integer) IS '

INSERTS A NON MOVEMENT PERIOD THAT WAS MISSED BY THE SEGMENTATION ALGORITHM BETWEEN TWO TRIPS - TAKES A TRIP, SPLITS IT IN TWO AND INSERTS A NON-MOVEMENT PERIOD IN BETWEEN

';


--
-- Name: insert_stationary_tripleg_period_in_trip(bigint, bigint, integer, integer, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.insert_stationary_tripleg_period_in_trip(from_time_ bigint, to_time_ bigint, from_travel_mode_ integer, to_travel_mode_ integer, trip_id_ integer) RETURNS json
    LANGUAGE plpgsql
    AS $_$
DECLARE 
affected_tripleg record; 
inserted_stationary_period record;
inserted_movement_period record; 
result json; 
BEGIN 
	select * from apiv2.triplegs_inf where type_of_tripleg = 1 and 
				trip_id = $5
				and $1 > from_time and $1 < to_time
				and $2 > from_time and $2 < to_time
				into affected_tripleg;

	-- RAISE NOTICE 'INSERTING FIRST -> %,%,%,%,%,%', affected_tripleg.user_id, $1, $2, 0, affected_tripleg.trip_id, affected_tripleg.tripleg_id;
	INSERT INTO apiv2.triplegs_inf(user_id, from_time, to_time, type_of_tripleg, trip_id, parent_tripleg_id)
					select affected_tripleg.user_id, $1, $2, 0, affected_tripleg.trip_id, affected_tripleg.tripleg_id;

	-- RAISE NOTICE 'INSERTING SECOND -> %,%,%,%,%,%, %', affected_tripleg.user_id, $2, affected_tripleg.to_time , 1, $4, affected_tripleg.trip_id, affected_tripleg.tripleg_id;				 
	INSERT INTO apiv2.triplegs_inf(user_id, from_time, to_time, type_of_tripleg, transportation_type, trip_id, parent_tripleg_id)
					select affected_tripleg.user_id, $2, affected_tripleg.to_time , 1, $4, affected_tripleg.trip_id, affected_tripleg.tripleg_id;

	-- RAISE NOTICE 'UPDATING TRIPLEG -> %, %, %', affected_tripleg.tripleg_id, $1, $3;
	UPDATE apiv2.triplegs_inf set to_time = $1, transportation_type = $3 where tripleg_id = affected_tripleg.tripleg_id;  

	result := apiv2.pagination_get_triplegs_of_trip($5);
	
	RETURN result;
END; 
$_$;


ALTER FUNCTION apiv2.insert_stationary_tripleg_period_in_trip(from_time_ bigint, to_time_ bigint, from_travel_mode_ integer, to_travel_mode_ integer, trip_id_ integer) OWNER TO postgres;

--
-- Name: FUNCTION insert_stationary_tripleg_period_in_trip(from_time_ bigint, to_time_ bigint, from_travel_mode_ integer, to_travel_mode_ integer, trip_id_ integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.insert_stationary_tripleg_period_in_trip(from_time_ bigint, to_time_ bigint, from_travel_mode_ integer, to_travel_mode_ integer, trip_id_ integer) IS '
INSERTS A NEW TRANSITION THAT WAS MISSED BY THE SEGMENTATION ALGORITHM IN BETWEEN TWO TRIPLEGS - TAKES A TRIPLEG, SPLITS IT IN TWO AND INSERTS A NON-MOVEMENT TRIPLEG IN BETWEEN
';


--
-- Name: insert_transition_poi(text, double precision, double precision, integer, text, text); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.insert_transition_poi(name text, latitude double precision, longitude double precision, declaring_user_id integer, transportation_lines text, transportation_types text) RETURNS integer
    LANGUAGE sql
    AS $_$
	INSERT INTO apiv2.poi_transportation
	(name_, lat_, lon_, declaring_user_id, declared_by_user, geom, transportation_lines, transportation_types)
	VALUES ($1, $2, $3, $4, true, st_setsrid(st_makepoint($3, $2), 4326), $5, $6)
	RETURNING gid
$_$;


ALTER FUNCTION apiv2.insert_transition_poi(name text, latitude double precision, longitude double precision, declaring_user_id integer, transportation_lines text, transportation_types text) OWNER TO postgres;

--
-- Name: FUNCTION insert_transition_poi(name text, latitude double precision, longitude double precision, declaring_user_id integer, transportation_lines text, transportation_types text); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.insert_transition_poi(name text, latitude double precision, longitude double precision, declaring_user_id integer, transportation_lines text, transportation_types text) IS '
INSERTS A NEW TRANSITION POI AS DEFINED BY THE USER AND RETURNS THE ID OF THE INSERTED POI
';


--
-- Name: merge_tripleg(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.merge_tripleg(tripleg_id_ integer) RETURNS json
    LANGUAGE plpgsql
    AS $_$DECLARE 
response json;
trip_id_ integer;
trip_to_time bigint;
tripleg_to_time bigint;
prev_tripleg_id int;
BEGIN
	trip_id_ := trip_id from apiv2.triplegs_inf where tripleg_id = $1;
	trip_to_time := to_time from apiv2.trips_inf where trip_id=trip_id_;
	tripleg_to_time := stop_time from apiv2.pagination_get_tripleg_with_id($1); 
	prev_tripleg_id := tripleg_id from apiv2.triplegs_inf where to_time < tripleg_to_time and trip_id = trip_id_ and type_of_tripleg=1 order by to_time desc limit 1; 

	perform apiv2.delete_tripleg($1);
	perform apiv2.update_trip_end_time(trip_to_time, trip_id_);
	perform apiv2.update_tripleg_end_time(tripleg_to_time, prev_tripleg_id);

	response:= apiv2.pagination_get_triplegs_of_trip(trip_id_); 
	RETURN response;
	
END;
$_$;


ALTER FUNCTION apiv2.merge_tripleg(tripleg_id_ integer) OWNER TO postgres;

--
-- Name: FUNCTION merge_tripleg(tripleg_id_ integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.merge_tripleg(tripleg_id_ integer) IS 'MERGE TRIPLEG WITH PREVIOUS TRIPLEG, RETURN THE MODIFIED TRIPLEGS OF THE TRIP';


--
-- Name: merge_with_next_trip(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.merge_with_next_trip(trip_id_ integer) RETURNS json
    LANGUAGE plpgsql
    AS $_$
DECLARE 
response json; 
update_to_time bigint;
BEGIN 
	update_to_time := to_time + 1 FROM apiv2.trips_inf
		WHERE from_time >= (SELECT to_time FROM apiv2.trips_inf WHERE trip_id = $1)
		AND user_id = (SELECT user_id FROM apiv2.trips_inf WHERE trip_id = $1)
		AND type_of_trip = 1
		ORDER BY to_time
		LIMIT 1;
	
	response := apiv2.update_trip_end_time(update_to_time, $1);

	RETURN response; 
END; 
$_$;


ALTER FUNCTION apiv2.merge_with_next_trip(trip_id_ integer) OWNER TO postgres;

--
-- Name: FUNCTION merge_with_next_trip(trip_id_ integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.merge_with_next_trip(trip_id_ integer) IS 'MERGES A TRIP WITH ITS NEIGHBOUR';


--
-- Name: pagination_get_gt_trip(integer, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.pagination_get_gt_trip(user_id_ integer, trip_id_ integer) RETURNS TABLE(status text, trip_id integer, current_trip_start_date bigint, current_trip_end_date bigint, previous_trip_end_date bigint, previous_trip_activities text, previous_trip_poi_name text, next_trip_start_date bigint, activities json, destination_places json)
    LANGUAGE sql
    AS $_$


WITH return_trip AS (

		SELECT *

		FROM apiv2.processed_trips

		WHERE user_id = $1

			AND trip_id = $2

		)

	,exists_current AS (

		SELECT EXISTS (

				SELECT *

				FROM return_trip

				)

		)

	,previous_trip AS (

		SELECT t1.*

		FROM apiv2.processed_trips t1

			,apiv2.processed_trips t2

		WHERE t1.user_id = $1

			AND t1.user_id = t2.user_id

			AND t2.trip_id = $2

			AND t1.trip_id <> t2.trip_id

			AND t1.to_time <= t2.from_time

		ORDER BY from_time DESC

			,to_time DESC limit 1

		)

	,exists_previous AS (

		SELECT EXISTS (

				SELECT *

				FROM previous_trip

				)

		)

	,next_trip AS (

		SELECT *

		FROM apiv2.all_trips

		WHERE user_id = $1

			AND from_time >= (

				SELECT to_time

				FROM return_trip

				)

		ORDER BY from_time limit 1

		)

	,exists_next AS (

		SELECT EXISTS (

				SELECT *

				FROM next_trip

				)

		)

	,last_point_of_trip AS (

		SELECT lat_

			,lon_

		FROM raw_data.location_table l

			,return_trip nt

		WHERE nt.user_id = l.user_id

			AND l.time_ <= nt.to_time limit 1

		)

SELECT CASE 

		WHEN (

				SELECT *

				FROM exists_current

				)

			THEN 'already_annotated'

				-- THIS SHOULD NEVER HAPPEN

		ELSE 'INVALID'

		END AS STATUS

	,first.trip_id

	,first.from_time AS current_trip_start_date

	,first.to_time AS current_trip_end_date

	,CASE 

		WHEN (

				SELECT *

				FROM exists_previous

				)

			THEN (

					SELECT to_time

					FROM previous_trip

					)

		ELSE 0

		END AS previous_trip_end_date

	,CASE 

		WHEN (

				SELECT *

				FROM exists_previous

				)

			THEN (

					SELECT string_agg(act.name_, ', ' ORDER BY agt.activity_order)

					FROM apiv2.activities_gt agt, apiv2.activity_table act

					WHERE agt.activity_id = act.id

						AND agt.trip_id = (SELECT trip_id FROM previous_trip)

					)

		ELSE NULL

		END AS last_trip_activities

	,CASE 

		WHEN (

				SELECT *

				FROM exists_previous

				)

			THEN (

					SELECT name_

					FROM apiv2.pois

					WHERE gid = (

							SELECT destination_poi_id

							FROM previous_trip

							)

					)

		ELSE ''

		END AS previous_trip_poi

	,CASE 

		WHEN (

				SELECT *

				FROM exists_next

				)

			THEN (

					SELECT from_time

					FROM next_trip

					)

		ELSE NULL

		END AS next_trip_start_date

	,CASE 

		WHEN (

				SELECT *

				FROM exists_current

				)

			THEN (
					SELECT array_to_json(array_agg(x ORDER BY x.accuracy))
					FROM (SELECT act.id as id, act.name_ as name, act.name_en as name_en, 
					100 - 0.01*agt.activity_order as accuracy

					FROM apiv2.activities_gt agt, apiv2.activity_table act

					WHERE agt.activity_id = act.id

						AND agt.trip_id = $2) x
				)

			ELSE (
					SELECT *

					FROM apiv2.ap_get_activities(trip_inf_id)
				 ) 
	 
		END AS activities
	,CASE 

		WHEN (

				SELECT *

				FROM exists_current

				)

			THEN (
					SELECT array_to_json(array_agg(x)) 
					FROM (SELECT gid, 100 as accuracy, is_personal as added_by_user, 
					lat_ as latitude, lon_ as longitude, case when name_='' then type_ else name_ end as name, type_

					FROM apiv2.pois

					WHERE gid = (

							SELECT destination_poi_id

							FROM return_trip

							)) x
				)
			ELSE (
					coalesce((

						SELECT *

						FROM apiv2.ap_get_destinations_close_by(pt.lat_, pt.lon_, user_id, destination_poi_id)

						), '{}')
				 )
		END AS destination_places

FROM return_trip first

	,last_point_of_trip AS pt $_$;


ALTER FUNCTION apiv2.pagination_get_gt_trip(user_id_ integer, trip_id_ integer) OWNER TO postgres;

--
-- Name: FUNCTION pagination_get_gt_trip(user_id_ integer, trip_id_ integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.pagination_get_gt_trip(user_id_ integer, trip_id_ integer) IS '

GETS THE GROUND TRUTH DEFINITION OF A SPECIFIED TRIP OR RETURNS A NULL SET IF THE TRIP DOES NOT EXIST

';


--
-- Name: pagination_get_gt_tripleg_with_id(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.pagination_get_gt_tripleg_with_id(tripleg_id integer) RETURNS TABLE(triplegid integer, start_time bigint, stop_time bigint, type_of_tripleg smallint, points json, mode json, places json)
    LANGUAGE sql
    AS $_$
select tripleg_id as triplegid, from_time as start_time, to_time as stop_time, type_of_tripleg, 
json_agg(row_to_json((select r from (select l.id, l.lat_ as lat, l.lon_ as lon, l.time_ as time) r))) as points,
(select * from apiv2.ap_get_mode_of_tripleg_gt_json(tripleg_id)) as modes,
coalesce((select * from apiv2.ap_get_transit_pois_of_tripleg_within_buffer(tl.user_id, tl.from_time, tl.to_time, 200, tl.transition_poi_id)), '{}') as places
from (select * from apiv2.processed_triplegs WHERE tripleg_id = $1) tl
left outer join
raw_data.location_table l
on l.time_ between tl.from_time and tl.to_time and l.accuracy_<=50
and l.user_id = tl.user_id
group by tripleg_id, type_of_tripleg, tl.user_id, from_time, to_time, transition_poi_id
$_$;


ALTER FUNCTION apiv2.pagination_get_gt_tripleg_with_id(tripleg_id integer) OWNER TO postgres;

--
-- Name: pagination_get_next_process(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.pagination_get_next_process(user_id integer) RETURNS TABLE(trip_id integer, current_trip_start_date bigint, current_trip_end_date bigint, previous_trip_end_date bigint, previous_trip_activities text, previous_trip_poi_name text, next_trip_start_date bigint, activities json, destination_places json)
    LANGUAGE sql
    AS $_$
WITH first_unprocessed_trip AS
     (
              SELECT *
              FROM
                       apiv2.unprocessed_trips
              WHERE
                       user_id = $1
              ORDER BY
                       from_time
                     , to_time
              limit    1
     )
   , last_processed_trip AS
     (
              SELECT *
              FROM
                       apiv2.processed_trips
              WHERE
                       user_id = $1
              ORDER BY
                       from_time DESC
                     , to_time DESC
              limit    1
     )
   , exists_previous AS
     (
            SELECT
                   EXISTS
                   (
                          SELECT *
                          FROM
                                 last_processed_trip
                   )
     )
   , next_trip_to_process AS
     (
              SELECT *
              FROM
                       apiv2.unprocessed_trips
              WHERE
                       user_id        = $1
                       AND from_time >=
                       (
                              SELECT
                                     to_time
                              FROM
                                     first_unprocessed_trip
                       )
              ORDER BY
                       from_time
              limit    1
     )
   , exists_next AS
     (
            SELECT
                   EXISTS
                   (
                          SELECT *
                          FROM
                                 next_trip_to_process
                   )
     )
   , last_point_of_trip AS
     (
              SELECT
                       lat_
                     , lon_
              FROM
                       raw_data.location_table l
                     , first_unprocessed_trip  nt
              WHERE
                       nt.user_id   = l.user_id
                       AND l.time_ <= nt.to_time
              ORDER BY
                       l.time_ DESC
              limit    1
     )
SELECT
       first.trip_id
     , first.from_time AS current_trip_start_date
     , first.to_time   AS current_trip_end_date
     , CASE
              WHEN
                     (
                            SELECT *
                            FROM
                                   exists_previous
                     )
                     THEN
                     (
                            SELECT
                                   to_time
                            FROM
                                   last_processed_trip
                     )
                     ELSE 0
       END AS previous_trip_end_date
     , CASE
              WHEN
                     (
                            SELECT *
                            FROM
                                   exists_previous
                     )
                     THEN
                     (
                              SELECT
                                       string_agg(act.name_, ', ' ORDER BY agt.activity_order)
                              FROM
                                       apiv2.activities_gt  agt
                                     , apiv2.activity_table act
                              WHERE
                                       agt.activity_id = act.id
                                       AND agt.trip_id =
                                       (
                                              SELECT
                                                     trip_id
                                              FROM
                                                     last_processed_trip
                                       )
                     )
                     ELSE NULL
       END AS last_trip_activities
     , CASE
              WHEN
                     (
                            SELECT *
                            FROM
                                   exists_previous
                     )
                     THEN
                     (
                            SELECT
                                   name_
                            FROM
                                   apiv2.pois
                            WHERE
                                   gid =
                                   (
                                          SELECT
                                                 destination_poi_id
                                          FROM
                                                 last_processed_trip
                                   )
                     )
                     ELSE ''
       END AS previous_trip_poi
     , CASE
              WHEN
                     (
                            SELECT *
                            FROM
                                   exists_next
                     )
                     THEN
                     (
                            SELECT
                                   from_time
                            FROM
                                   next_trip_to_process
                     )
                     ELSE NULL
       END AS next_trip_start_date
     , (
              SELECT *
              FROM
                     apiv2.ap_get_activities(trip_id)
       )
       AS activities
     , coalesce(
                 (
                        SELECT *
                        FROM
                               apiv2.ap_get_destinations_close_by(pt.lat_, pt.lon_, user_id, destination_poi_id)
                )
                , '{}') AS destination_places
FROM
       first_unprocessed_trip    first
     , last_point_of_trip     AS pt 
 $_$;


ALTER FUNCTION apiv2.pagination_get_next_process(user_id integer) OWNER TO postgres;

--
-- Name: FUNCTION pagination_get_next_process(user_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.pagination_get_next_process(user_id integer) IS 'Gets the earliest unannotated trip of a user by user id';


--
-- Name: pagination_get_tripleg_with_id(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.pagination_get_tripleg_with_id(tripleg_id integer) RETURNS TABLE(triplegid integer, start_time bigint, stop_time bigint, type_of_tripleg smallint, points json, mode json, places json)
    LANGUAGE sql
    AS $_$
select tripleg_id as triplegid, from_time as start_time, to_time as stop_time, type_of_tripleg, 
json_agg(row_to_json((select r from (select l.id, l.lat_ as lat, l.lon_ as lon, l.time_ as time) r))) as points,
(select * from apiv2.ap_get_probable_modes_of_tripleg_json(tripleg_id)) as modes,
coalesce((select * from apiv2.ap_get_transit_pois_of_tripleg_within_buffer(tl.user_id, tl.from_time, tl.to_time, 200, tl.transition_poi_id)), '{}') as places
from (select * from apiv2.unprocessed_triplegs WHERE tripleg_id = $1) tl
left outer join 
(select * from raw_data.location_table order by time_) l
on l.time_ between tl.from_time and tl.to_time and l.accuracy_<=50
and l.user_id = tl.user_id
group by tripleg_id, type_of_tripleg, tl.user_id, from_time, to_time, transition_poi_id
$_$;


ALTER FUNCTION apiv2.pagination_get_tripleg_with_id(tripleg_id integer) OWNER TO postgres;

--
-- Name: FUNCTION pagination_get_tripleg_with_id(tripleg_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.pagination_get_tripleg_with_id(tripleg_id integer) IS 'Gets an unannotated tripleg by its id';


--
-- Name: pagination_get_triplegs_of_trip(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.pagination_get_triplegs_of_trip(trip_id integer) RETURNS json
    LANGUAGE sql
    AS $_$
select json_agg(l1.*) from
(select tripleg_id from apiv2.unprocessed_triplegs where trip_id = $1 order by from_time, to_time) l2
join lateral (select * from apiv2.pagination_get_tripleg_with_id(l2.tripleg_id)) l1
on true
$_$;


ALTER FUNCTION apiv2.pagination_get_triplegs_of_trip(trip_id integer) OWNER TO postgres;

--
-- Name: FUNCTION pagination_get_triplegs_of_trip(trip_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.pagination_get_triplegs_of_trip(trip_id integer) IS 'Retrieves the unannotated triplegs of a trip by the trip_id';


--
-- Name: pagination_get_triplegs_of_trip_gt(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.pagination_get_triplegs_of_trip_gt(trip_id integer) RETURNS json
    LANGUAGE sql
    AS $_$
select json_agg(l1.*) from
(select tripleg_id from apiv2.processed_triplegs where trip_id = (select trip_inf_id from apiv2.trips_gt where trip_id = $1 limit 1) order by from_time, to_time) l2
join lateral (select * from apiv2.pagination_get_gt_tripleg_with_id(l2.tripleg_id)) l1
on true
$_$;


ALTER FUNCTION apiv2.pagination_get_triplegs_of_trip_gt(trip_id integer) OWNER TO postgres;

--
-- Name: pagination_go_to_trip(integer, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.pagination_go_to_trip(user_id_ integer, trip_id_ integer) RETURNS TABLE(status text, is_editable integer, trip_id integer, current_trip_start_date bigint, current_trip_end_date bigint, previous_trip_end_date bigint, previous_trip_activities text, previous_trip_poi_name text, next_trip_start_date bigint, activities json, destination_places json)
    LANGUAGE sql
    AS $_$

WITH

	return_trip_id AS (SELECT trip_id from apiv2.all_trips WHERE user_id = $1 ORDER BY from_time ASC OFFSET ($2 - 1) LIMIT 1),

	return_trip_gt_id AS (SELECT trip_id from apiv2.trips_gt WHERE user_id = $1 AND trip_inf_id = (SELECT trip_id FROM return_trip_id)),

	return_trip AS (

		SELECT *

		FROM apiv2.all_trips

		WHERE user_id = $1

			AND trip_id = (SELECT trip_id FROM return_trip_id)

		)

	,exists_current AS (

		SELECT EXISTS (

				SELECT *

				FROM return_trip

				)

		)
	
	,exists_current_gt AS (SELECT EXISTS (SELECT * FROM return_trip_gt_id))

	,previous_trip AS (

		SELECT t1.*

		FROM apiv2.all_trips t1

			,apiv2.all_trips t2

		WHERE t1.user_id = $1

			AND t1.user_id = t2.user_id

			AND t2.trip_id = (SELECT trip_id FROM return_trip_id)

			AND t1.trip_id <> t2.trip_id

			AND t1.to_time <= t2.from_time

		ORDER BY from_time DESC

			,to_time DESC limit 1

		)

	,previous_trip_gt_id AS (SELECT trip_id from apiv2.trips_gt WHERE user_id = $1 AND trip_inf_id = (SELECT trip_id FROM previous_trip))

	,exists_previous AS (

		SELECT EXISTS (

				SELECT *

				FROM previous_trip

				)

		)

	,next_trip AS (

		SELECT *

		FROM apiv2.all_trips

		WHERE user_id = $1

			AND from_time >= (

				SELECT to_time

				FROM return_trip

				)

		ORDER BY from_time limit 1

		)

	,exists_next AS (

		SELECT EXISTS (

				SELECT *

				FROM next_trip

				)

		)

	,last_point_of_trip AS (

		SELECT lat_

			,lon_

		FROM raw_data.location_table l

			,return_trip nt

		WHERE nt.user_id = l.user_id

			AND l.time_ <= nt.to_time limit 1

		)

SELECT CASE 

		WHEN (SELECT * FROM exists_current_gt)

			THEN 'already_annotated'

				-- THIS SHOULD NEVER HAPPEN

		ELSE 'needs_annotation'

		END AS STATUS
		,
		(

		CASE 

			WHEN (

					SELECT trip_id

					FROM apiv2.get_next_trip_response_temp_fix($1)

					) = first.trip_id

				THEN 1

			ELSE 0

			END

		) AS is_editable

	,CASE
		WHEN (SELECT * FROM exists_current_gt) THEN (SELECT trip_id FROM return_trip_gt_id)
		ELSE first.trip_id
	END

	,first.from_time AS current_trip_start_date

	,first.to_time AS current_trip_end_date

	,CASE 

		WHEN (

				SELECT *

				FROM exists_previous

				)

			THEN (

					SELECT to_time

					FROM previous_trip

					)

		ELSE 0

		END AS previous_trip_end_date

	,CASE 

		WHEN (

				SELECT *

				FROM exists_previous

				)

			THEN (

					SELECT string_agg(act.name_, ', ' ORDER BY agt.activity_order)

					FROM apiv2.activities_gt agt, apiv2.activity_table act

					WHERE agt.activity_id = act.id

						AND agt.trip_id = (SELECT trip_id FROM previous_trip_gt_id)

					)

		ELSE NULL

		END AS last_trip_activities

	,CASE 

		WHEN (

				SELECT *

				FROM exists_previous

				)

			THEN (

					SELECT name_

					FROM apiv2.pois

					WHERE gid = (

							SELECT destination_poi_id

							FROM previous_trip

							)

					)

		ELSE ''

		END AS previous_trip_poi

	,CASE 

		WHEN (

				SELECT *

				FROM exists_next

				)

			THEN (

					SELECT from_time

					FROM next_trip

					)

		ELSE NULL

		END AS next_trip_start_date

	,CASE 

		WHEN (

				SELECT *

				FROM exists_current

				)

			THEN (
					SELECT array_to_json(array_agg(x ORDER BY x.accuracy))
					FROM (SELECT act.id as id, act.name_ as name, act.name_en as name_en, 
					100 - 0.01*agt.activity_order as accuracy

					FROM apiv2.activities_gt agt, apiv2.activity_table act

					WHERE agt.activity_id = act.id

						AND agt.trip_id = (SELECT trip_id FROM return_trip_gt_id)) x
				)

			ELSE (
					SELECT *

					FROM apiv2.ap_get_activities((SELECT trip_id FROM return_trip_id))
				 ) 
	 
		END AS activities
	,CASE 

		WHEN (

				SELECT *

				FROM exists_current

				)

			THEN (
					SELECT array_to_json(array_agg(x)) 
					FROM (SELECT gid, 100 as accuracy, is_personal as added_by_user, 
					lat_ as latitude, lon_ as longitude, case when name_='' then type_ else name_ end as name, type_

					FROM apiv2.pois

					WHERE gid = (

							SELECT destination_poi_id

							FROM return_trip

							)) x
				)
			ELSE (
					coalesce((

						SELECT *

						FROM apiv2.ap_get_destinations_close_by(pt.lat_, pt.lon_, user_id, destination_poi_id)

						), '{}')
				 )
		END AS destination_places

FROM return_trip first

	,last_point_of_trip AS pt 
$_$;


ALTER FUNCTION apiv2.pagination_go_to_trip(user_id_ integer, trip_id_ integer) OWNER TO postgres;

--
-- Name: pagination_navigate_preview_next_trip(integer, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.pagination_navigate_preview_next_trip(user_id_ integer, trip_id_ integer) RETURNS TABLE(status text, is_editable integer, trip_id integer, current_trip_start_date bigint, current_trip_end_date bigint, previous_trip_end_date bigint, previous_trip_activities text, previous_trip_poi_name text, next_trip_start_date bigint, activities json, destination_places json)
    LANGUAGE sql
    AS $_$


WITH current_trip AS (

		SELECT *

		FROM apiv2.all_trips

		WHERE user_id = $1

			AND trip_id = $2

		ORDER BY from_time limit 1

		)

	,next_trip AS (

		SELECT *

		FROM apiv2.all_trips

		WHERE user_id = $1

			AND from_time >= (

				SELECT to_time

				FROM current_trip

				)

		ORDER BY from_time limit 1

		)

	,exists_next AS (

		SELECT EXISTS (

				SELECT *

				FROM next_trip

				)

		)

	,after_next_trip AS (

		SELECT *

		FROM apiv2.unprocessed_trips

		WHERE user_id = $1

			AND from_time >= (

				SELECT to_time

				FROM next_trip

				)

		ORDER BY from_time limit 1

		)

	,exists_after_next AS (

		SELECT EXISTS (

				SELECT *

				FROM after_next_trip

				)

		)

	,last_point_of_trip AS (

		SELECT lat_

			,lon_

		FROM raw_data.location_table l

			,next_trip nt

		WHERE nt.user_id = l.user_id

			AND l.time_ <= nt.to_time

		ORDER BY l.time_ DESC limit 1

		)

SELECT 'needs_annotation'::TEXT

	,(

		CASE 

			WHEN (

					SELECT trip_id

					FROM apiv2.get_next_trip_response_temp_fix($1)

					) = first.trip_id

				THEN 1

			ELSE 0

			END

		) AS is_editable

	,first.trip_id

	,first.from_time AS current_trip_start_date

	,first.to_time AS current_trip_end_date

	,CASE 

		WHEN (

				SELECT *

				FROM exists_next

				)

			THEN (

					SELECT to_time

					FROM current_trip

					)

		ELSE 0

		END AS previous_trip_end_date

	,CASE 

		WHEN (

				SELECT *

				FROM exists_next

				)

			THEN (

					SELECT string_agg(act.name_, ', ' ORDER BY agt.activity_order)

					FROM apiv2.activities_inf agt

						,apiv2.activity_table act

					WHERE agt.activity_id = act.id

						AND agt.trip_id = (

							SELECT trip_id

							FROM apiv2.trips_gt WHERE trip_inf_id = $2

							)

				)

		ELSE NULL

		END AS last_trip_activities

	,CASE 

		WHEN (

				SELECT *

				FROM exists_next

				)

			THEN (

					SELECT name_

					FROM apiv2.pois

					WHERE gid = (

							SELECT destination_poi_id

							FROM current_trip

							)

					)

		ELSE ''

		END AS previous_trip_poi

	,CASE 

		WHEN (

				SELECT *

				FROM exists_after_next

				)

			THEN (

					SELECT from_time

					FROM after_next_trip

					)

		ELSE NULL

		END AS next_trip_start_date

	,(

		SELECT *

		FROM apiv2.ap_get_activities(trip_id)

		) AS activities

	,coalesce((

			SELECT *

			FROM apiv2.ap_get_destinations_close_by(pt.lat_, pt.lon_, user_id, destination_poi_id)

			), '{}') AS destination_places

FROM next_trip first

	,last_point_of_trip AS pt $_$;


ALTER FUNCTION apiv2.pagination_navigate_preview_next_trip(user_id_ integer, trip_id_ integer) OWNER TO postgres;

--
-- Name: FUNCTION pagination_navigate_preview_next_trip(user_id_ integer, trip_id_ integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.pagination_navigate_preview_next_trip(user_id_ integer, trip_id_ integer) IS '

GETS THE GROUND TRUTH DEFINITION OF THE TRIP THAT PRECEDES THE ONE WITH THE SPECIFED ID OR RETURNS A NULL SET IF THE TRIP DOES NOT EXIST';


--
-- Name: pagination_navigate_preview_prev_trip(integer, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.pagination_navigate_preview_prev_trip(user_id_ integer, trip_id_ integer) RETURNS TABLE(status text, is_editable integer, trip_id integer, current_trip_start_date bigint, current_trip_end_date bigint, previous_trip_end_date bigint, previous_trip_activities text, previous_trip_poi_name text, next_trip_start_date bigint, activities json, destination_places json)
    LANGUAGE sql
    AS $_$


WITH current_trip AS (

		SELECT *

		FROM apiv2.all_trips

		WHERE user_id = $1

			AND trip_id = $2

		ORDER BY from_time limit 1

		)

	,prev_trip AS (

		SELECT *

		FROM apiv2.all_trips

		WHERE user_id = $1

			AND to_time <= (

				SELECT from_time

				FROM current_trip

				)

		ORDER BY to_time DESC limit 1

		)

	,exists_prev AS (

		SELECT EXISTS (

				SELECT *

				FROM prev_trip

				)

		)

	,before_prev_trip AS (

		SELECT *

		FROM apiv2.all_trips

		WHERE user_id = $1

			AND to_time <= (

				SELECT from_time

				FROM prev_trip

				)

		ORDER BY to_time DESC limit 1

		)

	,exists_before_next AS (

		SELECT EXISTS (

				SELECT *

				FROM before_prev_trip

				)

		)

	,last_point_of_trip AS (

		SELECT lat_

			,lon_

		FROM raw_data.location_table l

			,prev_trip nt

		WHERE nt.user_id = l.user_id

			AND l.time_ <= nt.to_time

		ORDER BY l.time_ DESC limit 1

		)

SELECT 'needs_annotation'::TEXT

	,(

		CASE 

			WHEN (

					SELECT trip_id

					FROM apiv2.get_next_trip_response_temp_fix($1)

					) = first.trip_id

				THEN 1

			ELSE 0

			END

		) AS is_editable

	,first.trip_id

	,first.from_time AS current_trip_start_date

	,first.to_time AS current_trip_end_date

	,CASE 

		WHEN (

				SELECT *

				FROM exists_prev

				)

			THEN (

					SELECT to_time

					FROM before_prev_trip

					)

		ELSE 0

		END AS previous_trip_end_date

	,CASE 

		WHEN (

				SELECT *

				FROM exists_prev

				)

			THEN (

					SELECT string_agg(act.name_, ', ' ORDER BY ainf.activity_order)

					FROM apiv2.activities_inf ainf

						,apiv2.activity_table act

					WHERE ainf.activity_id = act.id

						AND ainf.trip_id = (

							SELECT trip_id

							FROM before_prev_trip

							)

					)

		ELSE NULL

		END AS last_trip_activities

	,CASE 

		WHEN (

				SELECT *

				FROM exists_prev

				)

			THEN (

					SELECT name_

					FROM apiv2.pois

					WHERE gid = (

							SELECT destination_poi_id

							FROM before_prev_trip

							)

					)

		ELSE ''

		END AS previous_trip_poi

	,CASE 

		WHEN (

				SELECT *

				FROM exists_before_next

				)

			THEN (

					SELECT from_time

					FROM current_trip

					)

		ELSE NULL

		END AS next_trip_start_date

	,(

		SELECT *

		FROM apiv2.ap_get_activities(trip_id)

		) AS activities

	,coalesce((

			SELECT *

			FROM apiv2.ap_get_destinations_close_by(pt.lat_, pt.lon_, user_id, destination_poi_id)

			), '{}') AS destination_places

FROM prev_trip first

	,last_point_of_trip AS pt $_$;


ALTER FUNCTION apiv2.pagination_navigate_preview_prev_trip(user_id_ integer, trip_id_ integer) OWNER TO postgres;

--
-- Name: FUNCTION pagination_navigate_preview_prev_trip(user_id_ integer, trip_id_ integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.pagination_navigate_preview_prev_trip(user_id_ integer, trip_id_ integer) IS '

GETS THE GROUND TRUTH DEFINITION OF THE TRIP THAT PRECEDES THE ONE WITH THE SPECIFED ID OR RETURNS A NULL SET IF THE TRIP DOES NOT EXIST';


--
-- Name: pagination_navigate_to_next_trip(integer, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.pagination_navigate_to_next_trip(user_id_ integer, trip_id_ integer) RETURNS TABLE(status text, trip_id integer, current_trip_start_date bigint, current_trip_end_date bigint, previous_trip_end_date bigint, previous_trip_activities text, previous_trip_poi_name text, next_trip_start_date bigint, activities json, destination_places json)
    LANGUAGE sql
    AS $_$
-- note: hacky implementation, there should be at least one better way
with 
        next_trip as (
        select t1.trip_id from apiv2.processed_trips t1, apiv2.processed_trips t2
		where t1.user_id = $1
			and t1.user_id = t2.user_id 
			and t2.trip_id = $2
			and t1.trip_id <> t2.trip_id
			and t1.from_time >= t2.to_time
		order by t1.to_time, t1.from_time
		limit 1
        ), actual_next as (        
        SELECT f.* from next_trip g left join lateral apiv2.pagination_get_gt_trip($1, g.trip_id) f on true
        ), f as (select * from apiv2.pagination_get_next_process($1))
        select
	case when (exists (select * from actual_next)) then 'already_annotated'::text else 'needs_annotation'::text end as status, 
	case when (exists (select * from f)) then coalesce(t.trip_id, f.trip_id) else t.trip_id end,
	case when (exists (select * from f)) then coalesce(t.current_trip_start_date,f.current_trip_start_date) else (t.current_trip_start_date) end,
	case when (exists (select * from f)) then coalesce(t.current_trip_end_date,f.current_trip_end_date) else (t.current_trip_end_date) end, 
	case when (exists (select * from f)) then coalesce(t.previous_trip_end_date,f.previous_trip_end_date) else (t.previous_trip_end_date) end,
	case when (exists (select * from f)) then coalesce(t.previous_trip_activities,f.previous_trip_activities) else (t.previous_trip_activities) end,
	case when (exists (select * from f)) then coalesce(t.previous_trip_poi_name,f.previous_trip_poi_name) else (t.previous_trip_poi_name) end,
	case when (exists (select * from f)) then coalesce(t.next_trip_start_date,f.next_trip_start_date) else (t.next_trip_start_date) end,
	case when (exists (select * from f)) then coalesce(t.activities,f.activities) else (t.activities) end,
	case when (exists (select * from f)) then coalesce(t.destination_places,f.destination_places) else (t.destination_places) end

		from apiv2.pagination_get_next_process($1) f 
		full outer join actual_next t on true 
 $_$;


ALTER FUNCTION apiv2.pagination_navigate_to_next_trip(user_id_ integer, trip_id_ integer) OWNER TO postgres;

--
-- Name: FUNCTION pagination_navigate_to_next_trip(user_id_ integer, trip_id_ integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.pagination_navigate_to_next_trip(user_id_ integer, trip_id_ integer) IS '
GETS THE GROUND TRUTH DEFINITION OF THE TRIP THAT FOLLOWS THE ONE WITH THE SPECIFED ID OR RETURNS A NULL SET IF THE TRIP DOES NOT EXIST';


--
-- Name: pagination_navigate_to_previous_trip(integer, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.pagination_navigate_to_previous_trip(user_id_ integer, trip_id_ integer) RETURNS TABLE(status text, trip_id integer, current_trip_start_date bigint, current_trip_end_date bigint, previous_trip_end_date bigint, previous_trip_activities text, previous_trip_poi_name text, next_trip_start_date bigint, activities json, destination_places json)
    LANGUAGE sql
    AS $_$

WITH previous_trip_gt AS (

		SELECT t1.trip_id

		FROM apiv2.processed_trips t1

			,apiv2.processed_trips t2

		WHERE t1.user_id = $1

			AND t1.user_id = t2.user_id

			AND t2.trip_id = $2

			AND t1.trip_id <> t2.trip_id

			AND t1.to_time <= t2.from_time

		ORDER BY t1.from_time DESC

			,t1.to_time DESC limit 1

		)

	,previous_trip_inf AS (

		SELECT t2.trip_id

		FROM apiv2.unprocessed_trips t1

			,apiv2.processed_trips t2

		-- get all the processed trips

		-- of a given user

		WHERE t1.user_id = $1

			AND t1.user_id = t2.user_id

			-- that are before

			AND t1.from_time >= t2.to_time

			-- a given trip id

			AND t1.trip_id = $2

			AND t2.trip_inf_id <> t1.trip_id

		ORDER BY t2.from_time DESC

			,t2.to_time DESC limit 1

		)

	,trip_id AS (

		SELECT coalesce(t2.trip_id, t1.trip_id) AS trip_id

		FROM previous_trip_inf t1

		FULL OUTER JOIN previous_trip_gt t2 ON true

		)

SELECT f.*

FROM trip_id g

LEFT JOIN lateral apiv2.pagination_get_gt_trip($1, g.trip_id) f ON true $_$;


ALTER FUNCTION apiv2.pagination_navigate_to_previous_trip(user_id_ integer, trip_id_ integer) OWNER TO postgres;

--
-- Name: FUNCTION pagination_navigate_to_previous_trip(user_id_ integer, trip_id_ integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.pagination_navigate_to_previous_trip(user_id_ integer, trip_id_ integer) IS '

GETS THE GROUND TRUTH DEFINITION OF THE TRIP THAT PRECEDES THE ONE WITH THE SPECIFED ID OR RETURNS A NULL SET IF THE TRIP DOES NOT EXIST';


--
-- Name: remove_trip(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.remove_trip(trip_id integer) RETURNS TABLE(trip_id integer, current_trip_start_date bigint, current_trip_end_date bigint, previous_trip_end_date bigint, previous_trip_activities text, previous_trip_poi_name text, next_trip_start_date bigint, activities json, destination_places json)
    LANGUAGE sql
    AS $_$ 

WITH deleted_trip AS (

		DELETE

		FROM apiv2.trips_inf

		WHERE trip_id = $1 returning user_id

		),

	 deleted_activities AS (

		DELETE

		FROM apiv2.activities_inf

		WHERE trip_id = $1 returning activity_id

		)

SELECT r.*

FROM deleted_trip

LEFT JOIN lateral apiv2.pagination_get_next_process(user_id::INT) r ON TRUE;$_$;


ALTER FUNCTION apiv2.remove_trip(trip_id integer) OWNER TO postgres;

--
-- Name: FUNCTION remove_trip(trip_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.remove_trip(trip_id integer) IS '

DELETES A TRIP FROM DATABASE AND RETURNS THE NEXT TRIP THAT THE USER HAS TO ANNOTATE

';


--
-- Name: tg_deleted_trip(); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.tg_deleted_trip() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
DECLARE
prev_trip_id integer;
next_trip_id integer; 
BEGIN 
	
	IF OLD.type_of_trip = 1 THEN  
		-- previous stationary tripleg
		prev_trip_id := trip_id from apiv2.trips_inf where user_id = OLD.user_id
			and type_of_trip = 0 and to_time <= OLD.from_time order by to_time desc limit 1;
		-- next stationary tripleg
		next_trip_id := trip_id from apiv2.trips_inf where user_id= OLD.user_id
			and type_of_trip = 0 and from_time >= OLD.to_time order by from_time asc limit 1;

		-- if there is no previous trip or if there is no next trip, it is safe to delete 
		IF prev_trip_id is not null and next_trip_id is not null THEN 
			-- update the previous stationary trip end time to cover the next trip end time 
			UPDATE apiv2.trips_inf set to_time = (select to_time from apiv2.trips_inf where trip_id = next_trip_id) where trip_id = prev_trip_id;
			-- delete the next stationary trip  
			DELETE FROM apiv2.trips_inf where trip_id = next_trip_id; 
		END IF;
	return OLD; 
	END IF;
	
  return OLD;
END;
$$;


ALTER FUNCTION apiv2.tg_deleted_trip() OWNER TO postgres;

--
-- Name: FUNCTION tg_deleted_trip(); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.tg_deleted_trip() IS 'Delete a trip and merge its previous and next stationary trips into one. Any trip deletion results in the subsequent deletion of its triplegs.';


--
-- Name: tg_deleted_trip_after(); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.tg_deleted_trip_after() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
DECLARE
prev_trip_id integer;
next_trip_id integer; 
BEGIN 
	DELETE FROM apiv2.triplegs_inf where trip_id = OLD.trip_id;
  return OLD; 
END;
$$;


ALTER FUNCTION apiv2.tg_deleted_trip_after() OWNER TO postgres;

--
-- Name: FUNCTION tg_deleted_trip_after(); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.tg_deleted_trip_after() IS 'DELETES THE TRIPLEGS BELONGING TO THE DELETED TRIP';


--
-- Name: tg_deleted_tripleg_after(); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.tg_deleted_tripleg_after() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE  
prev_tripleg_id int;
next_tripleg_id int;
next_to_time bigint;
prev_from_time bigint; 
BEGIN 
  -- if the updated tripleg is a movement period, then update its neighboring stationary triplegs 
  IF OLD.type_of_tripleg = 1 THEN 
  	
	-- previous stationary tripleg
	prev_tripleg_id := tripleg_id from apiv2.triplegs_inf where trip_id = OLD.trip_id
		and type_of_tripleg = 0 and to_time <= OLD.from_time order by to_time desc limit 1;
	-- next stationary tripleg
	next_tripleg_id := tripleg_id from apiv2.triplegs_inf where trip_id = OLD.trip_id
		and type_of_tripleg = 0 and from_time >= OLD.to_time order by from_time asc limit 1;

	prev_from_time := from_time from apiv2.triplegs_inf where tripleg_id = prev_tripleg_id;
	next_to_time := to_time from apiv2.triplegs_inf where tripleg_id = next_tripleg_id;
	
	-- if there is no previous tripleg, then a special action for the first tripleg of the trip has to be taken - update the from_time of the current trip 
	IF prev_tripleg_id is null THEN 
		DELETE FROM apiv2.triplegs_inf where tripleg_id = next_tripleg_id; 
		UPDATE apiv2.trips_inf set from_time = next_to_time where trip_id = OLD.trip_id; 
	END IF;

	-- if there is no next tripleg, then a special action for the last tripleg of the trip has to be taken - update the to_time of the current trip 
	IF next_tripleg_id is null THEN 
		DELETE FROM apiv2.triplegs_inf where tripleg_id = prev_tripleg_id;
		UPDATE apiv2.trips_inf set to_time = OLD.from_time where trip_id = OLD.trip_id; 
	END IF;

	IF prev_tripleg_id is not null and next_tripleg_id is not null THEN  
	DELETE FROM apiv2.triplegs_inf where tripleg_id = next_tripleg_id; 
		UPDATE apiv2.triplegs_inf set to_time = next_to_time where tripleg_id = prev_tripleg_id;  
	END IF;
	
  END IF; 
  return OLD; 
END;
$$;


ALTER FUNCTION apiv2.tg_deleted_tripleg_after() OWNER TO postgres;

--
-- Name: FUNCTION tg_deleted_tripleg_after(); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.tg_deleted_tripleg_after() IS 'DELETE AND / OR UPDATE THE NON MOVEMENT PERIOD NEIGHBORING THE DELETED TRIPLEG';


--
-- Name: tg_deleted_tripleg_before(); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.tg_deleted_tripleg_before() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE   
number_of_triplegs_remaining_in_trip int;
BEGIN 
  -- if the updated tripleg is a movement period 
  IF OLD.type_of_tripleg = 1 THEN   
	number_of_triplegs_remaining_in_trip:= count(*) from apiv2.triplegs_inf where trip_id = (select trip_id from apiv2.trips_inf where trip_id = OLD.trip_id);  
	IF number_of_triplegs_remaining_in_trip = 1 THEN 
	RAISE EXCEPTION 'cannot delete the only tripleg in the trip';
	END IF; 
	
  END IF; 
  return OLD; 
END;
$$;


ALTER FUNCTION apiv2.tg_deleted_tripleg_before() OWNER TO postgres;

--
-- Name: FUNCTION tg_deleted_tripleg_before(); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.tg_deleted_tripleg_before() IS 'CHECK IF THE TRIPLEG THAT IS MEANT TO BE DELETED IS NOT THE ONLY TRIPLEG IN THE TRIP';


--
-- Name: tg_deleted_user(); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.tg_deleted_user() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
DECLARE 
BEGIN 
	
	DELETE FROM apiv2.trips_inf where user_id = OLD.id;
	
	DELETE FROM apiv2.triplegs_inf where user_id = OLD.id;
	
	RETURN OLD;
END;
$$;


ALTER FUNCTION apiv2.tg_deleted_user() OWNER TO postgres;

--
-- Name: FUNCTION tg_deleted_user(); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.tg_deleted_user() IS 'CASCADES THE DELETION OF A USER ID TO DELETE ALL THE TRIPS AND TRIPLEGS BELONGING TO THE USER -> ONLY FOR TESTING PURPOSES, SHOULD NOT BE USED IN PRODUCTION';


--
-- Name: tg_inserted_trip(); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.tg_inserted_trip() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
prev_trip_id int;
next_trip_id int;
BEGIN  
	
  IF NEW.from_time > NEW.to_time THEN 
    RAISE EXCEPTION 'invalid start time later than end time'; 
  END IF; 

  -- if the updated tripleg is a movement period, then update its neighboring stationary trips 
  IF NEW.type_of_trip = 1 THEN 
  -- changed from and to type condition to account for the updates as well 
	-- previous stationary trip
	prev_trip_id := trip_id from apiv2.trips_inf where user_id = NEW.user_id
		and type_of_trip = 0 and from_time <= NEW.from_time order by to_time desc limit 1;
	-- next stationary trip
	next_trip_id := trip_id from apiv2.trips_inf where user_id= NEW.user_id
		and type_of_trip = 0 and to_time >= NEW.to_time order by from_time asc limit 1;
					
	-- if there is a previous stationary period and the from_time of the updated trip is different from the previous from_time 
	IF prev_trip_id is not null THEN 
		UPDATE apiv2.trips_inf set to_time = NEW.from_time where trip_id = prev_trip_id; 
	END IF;

	-- if there is a next stationary period and the to_time of the updated trip is different from the previous to_time 
	IF next_trip_id is not null THEN 
		UPDATE apiv2.trips_inf set from_time = NEW.to_time, to_time = greatest(to_time, NEW.to_time) where trip_id = next_trip_id;
	END IF;
  END IF; 
  return NEW; 
END;
$$;


ALTER FUNCTION apiv2.tg_inserted_trip() OWNER TO postgres;

--
-- Name: FUNCTION tg_inserted_trip(); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.tg_inserted_trip() IS 'UPDATE THE NEIGHBORING PASSIVE TRIPS AFFECTED BY THE UPDATE';


--
-- Name: tg_inserted_tripleg(); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.tg_inserted_tripleg() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE 
trip_id bigint; 
user_id int;
number_of_locations int;
safe_to_check boolean;
BEGIN 
	number_of_locations := count(*) from raw_data.location_table l where l.user_id = NEW.user_id and time_ between NEW.from_time and NEW.to_time and accuracy_<= 50; 
	trip_id := t.trip_id from apiv2.trips_inf t where t.trip_id = NEW.trip_id; 
	user_id := u.id from raw_data.user_table u where u.id = NEW.user_id;
	safe_to_check := ((type_of_trip=1) and NEW.type_of_tripleg = 1) from apiv2.trips_inf t where t.trip_id = NEW.trip_id;
	-- this could be obtained via a trigger but it causes problems on deletions due to the order of the trigger cascade drop
  IF trip_id IS NULL THEN 
    RAISE EXCEPTION 'trip_id has to reference a valid key'; 
  END IF; 

    IF user_id IS NULL THEN 
    RAISE EXCEPTION 'user_id has to reference a valid key'; 
  END IF; 


    IF number_of_locations<2 AND safe_to_check  THEN  
     RAISE EXCEPTION 'insufficient number of locations to form a tripleg'; 
    END IF;
    
  return NEW; 
END;
$$;


ALTER FUNCTION apiv2.tg_inserted_tripleg() OWNER TO postgres;

--
-- Name: FUNCTION tg_inserted_tripleg(); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.tg_inserted_tripleg() IS 'Check that the inserted tripleg references a valid trip_id and a valid user_id 
';


--
-- Name: tg_updated_trip_after(); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.tg_updated_trip_after() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
prev_trip_id int;
next_trip_id int;
BEGIN 

  IF NEW.from_time > NEW.to_time THEN 
    RAISE EXCEPTION 'invalid start time later than end time'; 
  END IF; 

	IF NEW.from_time<>OLD.from_time AND NEW.to_time<>OLD.to_time THEN
		update apiv2.triplegs_inf set from_time = NEW.from_time, to_time = NEW.to_time where tripleg_id = (select tripleg_id from apiv2.triplegs_inf where trip_id = NEW.trip_id order by from_time, to_time asc limit 1);
	ELSE
	
		IF NEW.from_time <> OLD.from_time THEN 
		update apiv2.triplegs_inf set from_time = NEW.from_time where tripleg_id = (select tripleg_id from apiv2.triplegs_inf where trip_id = NEW.trip_id order by from_time, to_time asc limit 1);
		END IF;

		IF NEW.to_time <> OLD.to_time THEN
		update apiv2.triplegs_inf set to_time = NEW.to_time where tripleg_id = (select tripleg_id from apiv2.triplegs_inf where trip_id = NEW.trip_id order by from_time desc, to_time desc limit 1);
		END IF;
	END IF;
  return NEW; 
END;
$$;


ALTER FUNCTION apiv2.tg_updated_trip_after() OWNER TO postgres;

--
-- Name: FUNCTION tg_updated_trip_after(); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.tg_updated_trip_after() IS 'UPDATES THE FIRST AND END TRIPLEGS TO MATCH THE TIME UPDATE';


--
-- Name: tg_updated_trip_before(); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.tg_updated_trip_before() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
prev_trip_id int;
next_trip_id int;
BEGIN 

  IF NEW.from_time > NEW.to_time THEN 
    RAISE EXCEPTION 'invalid start time later than end time'; 
  END IF; 

  -- if the updated tripleg is a movement period, then update its neighboring stationary trips 
  IF NEW.type_of_trip = 1 THEN 
	-- previous stationary trip
	prev_trip_id := trip_id from apiv2.trips_inf where user_id = NEW.user_id
		and type_of_trip = 0 and to_time <= OLD.from_time order by to_time desc limit 1;
	-- next stationary trip
	next_trip_id := trip_id from apiv2.trips_inf where user_id= NEW.user_id
		and type_of_trip = 0 and from_time >= OLD.to_time order by from_time asc limit 1;
			
	-- if there is a previous stationary period and the from_time of the updated trip is different from the previous from_time 
	IF prev_trip_id is not null AND NEW.from_time <> OLD.from_time THEN 
		UPDATE apiv2.trips_inf set to_time = NEW.from_time where trip_id = prev_trip_id; 
	END IF;

	-- if there is a next stationary period and the to_time of the updated trip is different from the previous to_time 
	IF next_trip_id is not null AND NEW.to_time <> OLD.to_time THEN 
		UPDATE apiv2.trips_inf set from_time = NEW.to_time, to_time = greatest(to_time, NEW.to_time) where trip_id = next_trip_id;
	END IF;
	
  END IF; 
  return NEW; 
END;
$$;


ALTER FUNCTION apiv2.tg_updated_trip_before() OWNER TO postgres;

--
-- Name: FUNCTION tg_updated_trip_before(); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.tg_updated_trip_before() IS 'UPDATES THE ADJACENT PASSIVE TRIPS TO MAINTAIN TEMPORAL INTEGRITY';


--
-- Name: tg_updated_tripleg(); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.tg_updated_tripleg() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
trip_from_time bigint; 
trip_to_time bigint;
prev_tripleg_id int;
next_tripleg_id int;
number_of_locations_within_update int;
trip_type int;
BEGIN 
	trip_from_time := from_time from apiv2.trips_inf where trip_id = NEW.trip_id;
	trip_to_time := to_time from apiv2.trips_inf where trip_id = NEW.trip_id;
	trip_type := type_of_trip from apiv2.trips_inf where trip_id = NEW.trip_id; 
	number_of_locations_within_update := count(id) from raw_data.location_table where user_id = NEW.user_id and time_ between NEW.from_time and NEW.to_time and accuracy_<50; 		

  IF NEW.from_time < trip_from_time THEN 
    RAISE EXCEPTION 'start time of tripleg has to be within the current trip'; 
  END IF; 

  IF NEW.to_time > trip_to_time THEN 
    RAISE EXCEPTION 'end time of tripleg has to be within the current trip'; 
  END IF; 

  -- if the updated tripleg is a movement period, then update its neighboring stationary triplegs 
  IF NEW.type_of_tripleg = 1 AND (NEW.to_time <> OLD.to_time or NEW.from_time<>OLD.from_time) AND trip_type = 1 THEN 
 
	IF number_of_locations_within_update<2 THEN
	RAISE EXCEPTION 'the updated period does not contain enough locations to form a tripleg, %, %---->%', number_of_locations_within_update, OLD, NEW;
	END IF;
	-- previous stationary tripleg
	prev_tripleg_id := tripleg_id from apiv2.triplegs_inf where trip_id = NEW.trip_id
		and type_of_tripleg = 0 and to_time <= greatest(OLD.from_time, NEW.from_time) order by to_time desc limit 1;
	-- next stationary tripleg
	next_tripleg_id := tripleg_id from apiv2.triplegs_inf where trip_id = NEW.trip_id
		and type_of_tripleg = 0 and from_time >= least(OLD.to_time, NEW.to_time) order by from_time asc limit 1;
 
	IF prev_tripleg_id IS NULL AND NEW.from_time <> OLD.from_time AND trip_from_time<>NEW.from_time THEN 
	RAISE EXCEPTION 'the start period of the first tripleg cannot be updated';
	END IF; 

	IF next_tripleg_id IS NULL AND NEW.to_time <> OLD.to_time AND trip_to_time<>NEW.to_time THEN
	RAISE EXCEPTION 'the end period of the last tripleg cannot be updated'; 
	END IF;
	
	-- if there is a previous stationary period and the from_time of the updated tripleg is different from the previous from_time 
	IF prev_tripleg_id is not null AND NEW.from_time <> OLD.from_time THEN 
		UPDATE apiv2.triplegs_inf set to_time = NEW.from_time where tripleg_id = prev_tripleg_id;
	END IF;

	-- if there is a next stationary period and the to_time of the updated tripleg is different from the previous to_time 
	IF next_tripleg_id is not null AND NEW.to_time <> OLD.to_time THEN 
		UPDATE apiv2.triplegs_inf set from_time = NEW.to_time where tripleg_id = next_tripleg_id;
	END IF;
	
  END IF; 
  return NEW; 
END;
$$;


ALTER FUNCTION apiv2.tg_updated_tripleg() OWNER TO postgres;

--
-- Name: FUNCTION tg_updated_tripleg(); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.tg_updated_tripleg() IS '
Check that the updates of a tripleg only occusr within the time frame of the trip and does not overflow to neighboring trips. 
Also assures time period consistency for stationary period triplegs';


--
-- Name: undo_last_annotation(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.undo_last_annotation(user_id integer) RETURNS TABLE(status text, trip_id integer, current_trip_start_date bigint, current_trip_end_date bigint, previous_trip_end_date bigint, previous_trip_activities text, previous_trip_poi_name text, next_trip_start_date bigint, activities json, destination_places json)
    LANGUAGE sql
    AS $_$

WITH last_processed AS (

		SELECT *

		FROM apiv2.processed_trips

		WHERE user_id = $1

		ORDER BY to_time DESC limit 1

		)

	,last_processed_triplegs AS (

		SELECT *

		FROM apiv2.triplegs_gt

		WHERE user_id = $1

			AND trip_id = (

				SELECT trip_id

				FROM last_processed

				)

		)

	,reset_trip AS (

		UPDATE apiv2.trips_inf

		SET destination_poi_id = NULL

		WHERE trip_id = (

				SELECT trip_inf_id

				FROM last_processed

				)

		)

	,reset_triplegs AS (

		UPDATE apiv2.triplegs_inf

		SET transportation_type = NULL

		WHERE tripleg_id IN (

				SELECT tripleg_inf_id

				FROM last_processed_triplegs

				)

		)

	,delete_triplegs AS (

		DELETE

		FROM apiv2.triplegs_gt

		WHERE trip_id = (

				SELECT trip_id

				FROM last_processed

				)

		)

	,delete_trip AS (

		DELETE

		FROM apiv2.trips_gt

		WHERE trip_id = (

				SELECT trip_id

				FROM last_processed

				)

		)

SELECT 1;

SELECT *

FROM apiv2.get_next_trip_response_temp_fix($1);$_$;


ALTER FUNCTION apiv2.undo_last_annotation(user_id integer) OWNER TO postgres;

--
-- Name: FUNCTION undo_last_annotation(user_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.undo_last_annotation(user_id integer) IS 'Undo last annotation of a user by user id';


--
-- Name: update_trip_activities(integer[], integer, text); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.update_trip_activities(activity_ids integer[], trip_id integer, new_activity text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$

DECLARE i INTEGER;

BEGIN

	DELETE

	FROM apiv2.activities_inf tinf

	WHERE tinf.trip_id = $2;

	FOR

	i IN 1..array_upper($1, 1) LOOP

	IF $1 [i] = 0 THEN WITH new_act AS (

			INSERT INTO apiv2.activity_table (

				name_

				,name_en

				,created_by

				)

			VALUES (

				$3

				,$3

				,(

					SELECT user_id

					FROM apiv2.trips_inf t

					WHERE t.trip_id = $2

					)

				) RETURNING id

			)

		INSERT INTO apiv2.activities_inf

		VALUES (

			$2

			,(

				SELECT id

				FROM new_act

				)

			,i

			);

	ELSE

		INSERT INTO apiv2.activities_inf

		VALUES (

			$2

			,$1 [i]

			,i

			);

END

IF ;END

	LOOP;

RETURN TRUE;END $_$;


ALTER FUNCTION apiv2.update_trip_activities(activity_ids integer[], trip_id integer, new_activity text) OWNER TO postgres;

--
-- Name: FUNCTION update_trip_activities(activity_ids integer[], trip_id integer, new_activity text); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.update_trip_activities(activity_ids integer[], trip_id integer, new_activity text) IS '

UPDATES THE ACTIVITIES OF A TRIP

';


--
-- Name: update_trip_cost(jsonb); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.update_trip_cost(transport_cost jsonb) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$

BEGIN

	WITH cost AS (SELECT * FROM jsonb_populate_recordset(NULL::apiv2.transport_cost_type, $1))

	UPDATE apiv2.triplegs_inf

	   SET tariff = c.tariff, toll = c.toll, parking = c.parking

	  FROM cost AS c

	 WHERE triplegs_inf.tripleg_id = c.tripleg_id;

	RETURN TRUE;

END $_$;


ALTER FUNCTION apiv2.update_trip_cost(transport_cost jsonb) OWNER TO postgres;

--
-- Name: FUNCTION update_trip_cost(transport_cost jsonb); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.update_trip_cost(transport_cost jsonb) IS '

UPDATES THE COSTS OF A TRIPLEGS

';


--
-- Name: update_trip_destination_poi_id(bigint, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.update_trip_destination_poi_id(destination_poi_id bigint, trip_id integer) RETURNS boolean
    LANGUAGE sql
    AS $_$
	UPDATE apiv2.trips_inf SET destination_poi_id = $1 
	WHERE trip_id = $2 
	RETURNING TRUE; 
$_$;


ALTER FUNCTION apiv2.update_trip_destination_poi_id(destination_poi_id bigint, trip_id integer) OWNER TO postgres;

--
-- Name: FUNCTION update_trip_destination_poi_id(destination_poi_id bigint, trip_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.update_trip_destination_poi_id(destination_poi_id bigint, trip_id integer) IS '
UPDATES THE DESTINATION POI ID OF A TRIP 
';


--
-- Name: update_trip_end_time(bigint, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.update_trip_end_time(to_time_ bigint, trip_id_ integer) RETURNS json
    LANGUAGE plpgsql
    AS $_$DECLARE response json; 
foo_trip_id int;
BEGIN
	with 
	-- get the details of the trip that should be updated 
	trip_details as (
	select trip_id, from_time, to_time, user_id from apiv2.unprocessed_trips where trip_id = $2
	),
	-- get the trips that will be affected by the update (both fully within and partially overlapping)
	affected_trips_by_update as (
	select trips.*, 
			-- trips that are fully within the proposed updated timestamps
			case when trips.to_time between tl.to_time and $1 then 'DELETE'
			-- trips that are partially overlapping the proposed updated timestamps
			else case when trips.from_time between tl.to_time and $1 then 'UPDATE' 
			-- error that should never occur 
			else 'ERROR' end end as action_needed 
		from apiv2.trips_inf trips, trip_details tl  
		where trips.trip_id <> tl.trip_id and trips.user_id = tl.user_id
		-- temporal join constraint 
		and (trips.from_time between tl.to_time and $1
			or trips.to_time between tl.to_time and $1)),
	-- updated trips 
	updated_neighboring_trips as (update apiv2.trips_inf set from_time = $1 where trip_id = any (select trip_id from affected_trips_by_update where action_needed = 'UPDATE' and type_of_trip = 1) returning $2 as trip_id),
	-- the initially updated tripleg 
	updated_current_trip as (update apiv2.trips_inf set to_time = $1 where trip_id = $2 returning trip_id), 
	-- the deleted triplegs
	deleted_trips as (delete from apiv2.trips_inf tl2 where tl2.trip_id = any (select trip_id from affected_trips_by_update where action_needed = 'DELETE' and type_of_trip = 1) returning $2 as trip_id),
	returning_trip_id as (SELECT distinct trip_id FROM (select * from deleted_trips union all select * from updated_neighboring_trips union all select *from updated_current_trip)  foo)  
	select trip_id from returning_trip_id into foo_trip_id; 
	
	response := apiv2.pagination_get_triplegs_of_trip($2);

	RETURN response; 
END; 
$_$;


ALTER FUNCTION apiv2.update_trip_end_time(to_time_ bigint, trip_id_ integer) OWNER TO postgres;

--
-- Name: FUNCTION update_trip_end_time(to_time_ bigint, trip_id_ integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.update_trip_end_time(to_time_ bigint, trip_id_ integer) IS 'UPDATES THE END TIME OF A TRIP AND PROPAGATES ANY TEMPORAL MODIFICATIONS TO ITS NEXT NEIGHBORING TRIPS
';


--
-- Name: update_trip_purpose(integer, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.update_trip_purpose(purpose_id integer, trip_id integer) RETURNS boolean
    LANGUAGE sql
    AS $_$
	UPDATE apiv2.trips_inf SET purpose_id = $1 
	WHERE trip_id = $2 
	RETURNING TRUE; 
$_$;


ALTER FUNCTION apiv2.update_trip_purpose(purpose_id integer, trip_id integer) OWNER TO postgres;

--
-- Name: FUNCTION update_trip_purpose(purpose_id integer, trip_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.update_trip_purpose(purpose_id integer, trip_id integer) IS '
UPDATES THE PURPOSE ID OF A TRIP
';


--
-- Name: update_trip_start_time(bigint, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.update_trip_start_time(from_time_ bigint, trip_id_ integer) RETURNS json
    LANGUAGE plpgsql
    AS $_$
DECLARE 
response json;
BEGIN 
	update apiv2.trips_inf set 
	from_time = $1 where trip_id = $2;
	response := apiv2.pagination_get_triplegs_of_trip($2);
	return response;
END;
$_$;


ALTER FUNCTION apiv2.update_trip_start_time(from_time_ bigint, trip_id_ integer) OWNER TO postgres;

--
-- Name: FUNCTION update_trip_start_time(from_time_ bigint, trip_id_ integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.update_trip_start_time(from_time_ bigint, trip_id_ integer) IS '
UPDATES THE START TIME OF A TRIP AND PROPAGATES ANY TEMPORAL MODIFICATION TO ITS PRECEEDING NEIGHBORING NON MOVEMENT TRIP
';


--
-- Name: update_tripleg_end_time(bigint, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.update_tripleg_end_time(to_time bigint, tripleg_id integer) RETURNS json
    LANGUAGE sql
    AS $_$with 
	-- get the details of the tripleg that should be updated 
	tripleg_details as (
	select tripleg_id, from_time, to_time, trip_id, user_id from apiv2.unprocessed_triplegs where tripleg_id = $2
	),
	-- get the triplegs that will be affected by the update (both fully within and partially overlapping)
	affected_triplegs_by_update as (
	select tlgs.*, 
			-- triplegs that are fully within the proposed updated timestamps
			case when tlgs.to_time between tl.to_time and $1 then 'DELETE'
			-- triplegs that are partially overlapping the proposed updated timestamps
			else case when tlgs.from_time between tl.to_time and $1 then 'UPDATE' 
			-- error that should never occur 
			else 'ERROR' end end as action_needed 
		from apiv2.unprocessed_triplegs tlgs, tripleg_details tl 
		-- have same trip id but be different from the updated tripleg
		where tlgs.trip_id = tl.trip_id and tlgs.tripleg_id <> tl.tripleg_id
		-- only consider movement periods, the stationary periods are dealt with exclusively by triggers 
		and tlgs.type_of_tripleg = 1 and tlgs.user_id = tl.user_id 
		-- temporal join constraint 
		and (tlgs.from_time between tl.to_time and $1
			or tlgs.to_time between tl.to_time and $1)),
	-- updated triplegs 
	updated_neighboring_triplegs as (update apiv2.triplegs_inf set from_time = $1 where tripleg_id = any (select tripleg_id from affected_triplegs_by_update where action_needed = 'UPDATE') returning trip_id),
	-- the initially updated tripleg 
	updated_current_tripleg as (update apiv2.triplegs_inf set to_time = $1 where tripleg_id = $2 returning trip_id), 
	-- the deleted triplegs
	deleted_triplegs as (delete from apiv2.triplegs_inf tl2 where tl2.tripleg_id = any (select tripleg_id from affected_triplegs_by_update where action_needed = 'DELETE') returning trip_id),
	returning_trip_id as (SELECT distinct trip_id FROM (select * from updated_neighboring_triplegs union all select * from updated_current_tripleg union all select * from deleted_triplegs ) foo) 

	select pagination_get_triplegs_of_trip from returning_trip_id 
	left join lateral apiv2.pagination_get_triplegs_of_trip(trip_id) ON TRUE; 

$_$;


ALTER FUNCTION apiv2.update_tripleg_end_time(to_time bigint, tripleg_id integer) OWNER TO postgres;

--
-- Name: FUNCTION update_tripleg_end_time(to_time bigint, tripleg_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.update_tripleg_end_time(to_time bigint, tripleg_id integer) IS 'MODIFIES THE END TIME OF A TRIPLEG AND PROPAGATES ANY TEMPORAL MODIFICATIONS TO ALL ITS NEIGHBORING NEXT TRIPLEGS
';


--
-- Name: update_tripleg_start_time(bigint, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.update_tripleg_start_time(from_time bigint, tripleg_id integer) RETURNS json
    LANGUAGE sql
    AS $_$with 
	-- get the details of the tripleg that should be updated 
	tripleg_details as (
	select tripleg_id, from_time, to_time, trip_id, user_id from apiv2.unprocessed_triplegs where tripleg_id = $2
	),
	-- get the triplegs that will be affected by the update (both fully within and partially overlapping)
	affected_triplegs_by_update as (
	select tlgs.*, 
			-- triplegs that are fully within the proposed updated timestamps
			case when tlgs.from_time between $1 and tl.from_time then 'DELETE'
			-- triplegs that are partially overlapping the proposed updated timestamps
			else case when tlgs.to_time between $1 and tl.from_time then 'UPDATE' 
			-- error that should never occur 
			else 'ERROR' end end as action_needed 
		from apiv2.unprocessed_triplegs tlgs, tripleg_details tl 
		-- have same trip id but be different from the updated tripleg
		where tlgs.trip_id = tl.trip_id and tlgs.tripleg_id <> tl.tripleg_id
		-- only consider movement periods, the stationary periods are dealt with exclusively by triggers 
		and tlgs.type_of_tripleg = 1 and tlgs.user_id = tl.user_id 
		-- temporal join constraint 
		and (tlgs.from_time between $1 and tl.from_time
			or tlgs.to_time between $1 and tl.from_time)),
	-- updated triplegs 
	updated_neighboring_triplegs as (update apiv2.triplegs_inf set to_time = $1 where tripleg_id = any (select tripleg_id from affected_triplegs_by_update where action_needed = 'UPDATE') returning trip_id),
	-- the initially updated tripleg 
	updated_current_tripleg as (update apiv2.triplegs_inf set from_time = $1 where tripleg_id = $2 returning trip_id), 
	-- the deleted triplegs
	deleted_triplegs as (delete from apiv2.triplegs_inf tl2 where tl2.tripleg_id = any (select tripleg_id from affected_triplegs_by_update where action_needed = 'DELETE') returning trip_id),
	returning_trip_id as (SELECT distinct trip_id FROM (select * from updated_neighboring_triplegs union all select * from updated_current_tripleg union all select * from deleted_triplegs ) foo) 

	select pagination_get_triplegs_of_trip from returning_trip_id 
	left join lateral apiv2.pagination_get_triplegs_of_trip(trip_id) ON TRUE; 

$_$;


ALTER FUNCTION apiv2.update_tripleg_start_time(from_time bigint, tripleg_id integer) OWNER TO postgres;

--
-- Name: FUNCTION update_tripleg_start_time(from_time bigint, tripleg_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.update_tripleg_start_time(from_time bigint, tripleg_id integer) IS 'MODIFIES THE START TIME OF A TRIPLEG AND PROPAGATES ANY TEMPORAL MODIFICATIONS TO ALL ITS NEIGHBORING PREVIOUS TRIPLEGS
';


--
-- Name: update_tripleg_transition_poi_id(integer, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.update_tripleg_transition_poi_id(transition_poi_id integer, tripleg_id integer) RETURNS boolean
    LANGUAGE sql
    AS $_$
	UPDATE apiv2.triplegs_inf set transition_poi_id = $1 where tripleg_id = $2
	RETURNING true;
$_$;


ALTER FUNCTION apiv2.update_tripleg_transition_poi_id(transition_poi_id integer, tripleg_id integer) OWNER TO postgres;

--
-- Name: FUNCTION update_tripleg_transition_poi_id(transition_poi_id integer, tripleg_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.update_tripleg_transition_poi_id(transition_poi_id integer, tripleg_id integer) IS '
UPDATES THE TRANSITION POI ID OF A GIVEN TRIPLEG 
';


--
-- Name: update_tripleg_travel_mode(integer, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.update_tripleg_travel_mode(travel_mode integer, tripleg_id integer) RETURNS boolean
    LANGUAGE sql
    AS $_$
	UPDATE apiv2.triplegs_inf set transportation_type = $1 where tripleg_id = $2
	RETURNING true;
$_$;


ALTER FUNCTION apiv2.update_tripleg_travel_mode(travel_mode integer, tripleg_id integer) OWNER TO postgres;

--
-- Name: FUNCTION update_tripleg_travel_mode(travel_mode integer, tripleg_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.update_tripleg_travel_mode(travel_mode integer, tripleg_id integer) IS '
UPDATES THE TRAVEL MODE OF A GIVEN TRIPLEG
';


--
-- Name: update_tripleg_travel_mode2(integer, integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.update_tripleg_travel_mode2(travel_mode2 integer, tripleg_id integer) RETURNS json
    LANGUAGE sql
    AS $_$
	UPDATE apiv2.triplegs_inf set transportation_type2 = $1 where tripleg_id = $2;
	SELECT case when $1=15 then (
		SELECT row_to_json(x) FROM  (SELECT *, true as tariff_given FROM apiv2.get_commuterline_cost($2)) x
	) else (
		SELECT row_to_json(x) FROM  (select false as tariff_given) x
	) end;
$_$;


ALTER FUNCTION apiv2.update_tripleg_travel_mode2(travel_mode2 integer, tripleg_id integer) OWNER TO postgres;

--
-- Name: FUNCTION update_tripleg_travel_mode2(travel_mode2 integer, tripleg_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.update_tripleg_travel_mode2(travel_mode2 integer, tripleg_id integer) IS '
UPDATES THE TRAVEL MODE 2 OF A GIVEN TRIPLEG
';


--
-- Name: user_get_badge_trips_info(integer); Type: FUNCTION; Schema: apiv2; Owner: postgres
--

CREATE FUNCTION apiv2.user_get_badge_trips_info(user_id integer) RETURNS bigint
    LANGUAGE sql
    AS $_$
		select count(*) from apiv2.unprocessed_trips 
		where user_id = $1;
$_$;


ALTER FUNCTION apiv2.user_get_badge_trips_info(user_id integer) OWNER TO postgres;

--
-- Name: FUNCTION user_get_badge_trips_info(user_id integer); Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON FUNCTION apiv2.user_get_badge_trips_info(user_id integer) IS '
GETS THE NUMBER OF TRIPS THAT A USER CAN ANNOTATE 
';


--
-- Name: change_password_dashboard(public.citext, text); Type: FUNCTION; Schema: dashboard; Owner: meili
--

CREATE FUNCTION dashboard.change_password_dashboard(username public.citext, password text) RETURNS boolean
    LANGUAGE sql
    AS $_$UPDATE dashboard.surveyor
SET PASSWORD = crypt($2, gen_salt('bf',8))
WHERE username = $1
RETURNING true;$_$;


ALTER FUNCTION dashboard.change_password_dashboard(username public.citext, password text) OWNER TO meili;

--
-- Name: login_dashboard(text, text); Type: FUNCTION; Schema: dashboard; Owner: meili
--

CREATE FUNCTION dashboard.login_dashboard(username text, password text) RETURNS integer
    LANGUAGE sql
    AS $_$SELECT id
FROM dashboard.surveyor
WHERE username = $1 AND password = crypt($2, password);$_$;


ALTER FUNCTION dashboard.login_dashboard(username text, password text) OWNER TO meili;

--
-- Name: register_dashboard(text, text); Type: FUNCTION; Schema: dashboard; Owner: meili
--

CREATE FUNCTION dashboard.register_dashboard(username text, password text) RETURNS text
    LANGUAGE sql
    AS $_$           INSERT INTO dashboard.surveyor (username, password)
	   VALUES ($1, crypt($2, gen_salt('bf',8)))
           ON conflict do nothing
           RETURNING username;$_$;


ALTER FUNCTION dashboard.register_dashboard(username text, password text) OWNER TO meili;

--
-- Name: ap_get_activities(integer); Type: FUNCTION; Schema: learning_processes; Owner: postgres
--

CREATE FUNCTION learning_processes.ap_get_activities(trip_id integer) RETURNS json
    LANGUAGE sql
    AS $_$--explain

WITH trip_candidate AS (

		SELECT *

		FROM apiv2.trips_inf

		WHERE trip_id = $1

		)
	,destination AS (
		SELECT
			ST_MakePoint(lat_,lon_) AS geom
		FROM
			raw_data.location_table l
			, trip_candidate  t1
		WHERE
			t1.user_id = l.user_id
			AND l.time_ <= t1.to_time
			AND l.accuracy_<=50
		ORDER BY
			l.time_ DESC
		limit 1
	)
	,user_generated_trips AS (

		SELECT EXTRACT(DOW FROM to_timestamp(tgt.to_time / 1000)) AS to_time_dow

			,EXTRACT(HOUR FROM to_timestamp(tgt.to_time / 1000)) AS to_time_hour

			,agt.activity_id

			,count(*)

		FROM apiv2.activities_gt agt

			,apiv2.trips_gt tgt
			
			,apiv2.pois poi
			
			,destination dest

		WHERE agt.trip_id = tgt.trip_id
			AND tgt.destination_poi_id = poi.gid
			AND st_dwithin(poi.geom, dest.geom, 50, true)

		GROUP BY -- from_time_dow, from_time_hour,

			to_time_dow

			,to_time_hour

			,activity_id

		)

	,crowd_knowledge AS (

		SELECT t2.activity_id

			,CASE 

				WHEN @(EXTRACT(HOUR FROM to_timestamp(t1.to_time / 1000)) - t2.to_time_hour) = 0

					THEN count

				ELSE count / @(EXTRACT(HOUR FROM to_timestamp(t1.to_time / 1000)) - t2.to_time_hour)

				END AS prob

		FROM user_generated_trips AS t2

			,trip_candidate AS t1

		WHERE EXTRACT(DOW FROM to_timestamp(t1.to_time / 1000)) = t2.to_time_dow

			AND @(EXTRACT(HOUR FROM to_timestamp(t1.to_time / 1000)) - t2.to_time_hour) <= 2

		ORDER BY prob

		)

	,user_history AS (

		SELECT t3.activity_id

			,2 * count(*) AS count

		FROM apiv2.activities_gt AS t3

			,apiv2.trips_gt AS t2

			,trip_candidate AS t1

		WHERE t3.trip_id = t2.trip_id

			AND t2.destination_poi_id = t1.destination_poi_id

			AND t2.user_id = t1.user_id

		GROUP BY t3.activity_id

		ORDER BY count

		)

	,activity_inference AS (

		SELECT CASE 

				WHEN EXISTS (

						SELECT *

						FROM user_history

						)

					THEN (

							SELECT array_to_json(array_agg(x ORDER BY accuracy DESC))

							FROM (

								SELECT activity_id AS id

									,CASE 

										WHEN count > 20

											THEN 100

										ELSE count * 5

										END AS accuracy

									,(

										SELECT name_

										FROM apiv2.activity_table act

										WHERE act.id = foo.activity_id

										) AS name

									,(

										SELECT name_en

										FROM apiv2.activity_table act

										WHERE act.id = foo.activity_id

										) AS name_en

								FROM (

									SELECT DISTINCT ON (activity_id) *

									FROM user_history

									UNION ALL

									(

										SELECT id

											,0

										FROM apiv2.activity_table

										WHERE NOT id = ANY (

												SELECT activity_id

												FROM user_history

												)

										)

									) AS foo

								ORDER BY accuracy DESC

								) x WHERE x.id IN (SELECT id FROM apiv2.activity_table WHERE created_by IS NULL OR created_by IN (SELECT user_id FROM trip_candidate))

							)

				ELSE (

						SELECT array_to_json(array_agg(x ORDER BY accuracy DESC))

						FROM (

							SELECT DISTINCT ON (activity_id) activity_id AS id

								,CASE 

									WHEN count > 20

										THEN 100

									ELSE count * 5

									END AS accuracy

								,(

									SELECT name_

									FROM apiv2.activity_table act

									WHERE act.id = foo.activity_id

									) AS name

								,(

									SELECT name_en

									FROM apiv2.activity_table act

									WHERE act.id = foo.activity_id

									) AS name_en

							FROM (

								SELECT activity_id

									,prob AS count

								FROM crowd_knowledge

								UNION ALL

								(

									SELECT id

										,0 AS count

									FROM apiv2.activity_table

									WHERE NOT id = ANY (

											SELECT activity_id

											FROM crowd_knowledge

											)

									)

								ORDER BY count DESC

								) AS foo

							) x WHERE x.id IN (SELECT id FROM apiv2.activity_table WHERE created_by IS NULL OR created_by IN (SELECT user_id FROM trip_candidate))

						)

				END

		)

SELECT array_to_json AS activites

FROM activity_inference $_$;


ALTER FUNCTION learning_processes.ap_get_activities(trip_id integer) OWNER TO postgres;

--
-- Name: ap_get_destinations_close_by(double precision, double precision, bigint, bigint); Type: FUNCTION; Schema: learning_processes; Owner: postgres
--

CREATE FUNCTION learning_processes.ap_get_destinations_close_by(latitude double precision, longitude double precision, user_id bigint, destination_poi_id bigint) RETURNS json
    LANGUAGE sql
    AS $_$ 
with point_geometry as 
	(select st_setsrid(st_makepoint($2, $1),4326) as orig_pt_geom),
pois_within_buffer as 
	(
	select  gid, lat_ as latitude, lon_ as longitude, 
	case when name_='' then type_ else name_ end as name, 
	type_, is_personal as added_by_user, st_distance(p1.geom, p2.orig_pt_geom) as dist from apiv2.pois as p1, point_geometry as p2 where 
	(p1.gid=$4) or (st_dwithin(p1.geom, p2.orig_pt_geom,500, true) 
	and (user_id= $3 or user_id is null))
	), 
counted_pois_within_buffer as 
	(
	select pois.gid, latitude, longitude,
	name, type_, added_by_user,
	count(*) from pois_within_buffer as pois
	left outer join apiv2.trips_gt as tgt
	on pois.gid = tgt.destination_poi_id 
	and tgt.user_id = $3
	group by pois.gid, latitude, longitude, name, type_, added_by_user
	), 
response as (select gid, latitude, longitude,
	name, type_, added_by_user,
	case when (gid = $4) then 100 else 
		case when added_by_user then 2* (least (count, 5) * 10.0)
		else least(count,5) * 10.0 
		end 
	end as accuracy from counted_pois_within_buffer) 
	
select array_to_json(array_agg(x)) from (select * from response) x

$_$;


ALTER FUNCTION learning_processes.ap_get_destinations_close_by(latitude double precision, longitude double precision, user_id bigint, destination_poi_id bigint) OWNER TO postgres;

--
-- Name: ap_get_probable_modes2_of_tripleg_json(bigint, integer); Type: FUNCTION; Schema: learning_processes; Owner: postgres
--

CREATE FUNCTION learning_processes.ap_get_probable_modes2_of_tripleg_json(triplegid bigint, transportation_type_id integer) RETURNS json
    LANGUAGE sql
    AS $_$
WITH considered_tripleg as

     (

            select *

            from

                   apiv2.triplegs_inf

            where

                   tripleg_id = $1

     )

   , inference_points_stat as

     (

                  SELECT

                               id

                             , time_

                             , speed_

                             , totalmean

                             , totalnumberofsteps

                             , st_distance(st_makepoint(lon_, lat_)::geography, st_makepoint(lag(lon_) over (

                                                                                                partition by l1.user_id

                                                                                                order by

                                                                                                             time_ ), lag(lat_) over (

                                                                                                                         partition by l1.user_id

                                                                                                                         order by

                                                                                                                                      time_ ))::geography) as dist_to_prev

                  FROM

                               raw_data.location_table as l1

                             , considered_tripleg      as l2

                  where

                               l1.user_id = l2.user_id

                               and l1.time_ between l2.from_time and l2.to_time

                               and accuracy_<=50

     )

   , last_point_of_considered_tripleg as

     (

            select

                   lat_

                 , lon_

            from

                   raw_data.location_table as l1

                 , considered_tripleg      as l2

            where

                   l1.id=l2.to_point_id

     )

   , transportation_mode_probability as

     (

            select

                   array_to_json(array_agg(

                   (

                          SELECT

                                 x

                          FROM

                                 (

                                        SELECT

                                               id      as id

                                             , 0       AS certainty

                                             , name_   as name

                                             , name_en as name_en

											 , tariff as tariff

											 , toll as toll

											 , parking as parking

                                 )

                                 x

                   )

                   )) as mode

            FROM

                   apiv2.travel_mode2_table

			where

				   transportation_type = $2

     )

   , points as

     (

            SELECT

                   array_to_json(array_agg(

                   (

                          SELECT

                                 x

                          FROM

                                 (

                                        select

                                               x

                                        from

                                               (

                                                      select

                                                             id

                                                           , lat

                                                           , lon

                                                           , time

                                               )

                                               x

                                 )

                                 as final_selection

                   )

                   ) ) as points

            from

                   (

                          select *

                          from

                                 (

                                        SELECT

                                               id    as id

                                             , lat_  AS lat

                                             , lon_  AS lon

                                             , time_ as time

                                        FROM

                                               raw_data.location_table as l1

                                             , considered_tripleg      as l2

                                        where

                                               l1.user_id = l2.user_id

                                               and l1.time_ between l2.from_time and l2.to_time

                                               and accuracy_<=50

                                 )

                                 as gps_points

                   )

                   as total_selection

     )

   , all_users_point_based_similarity as

     (

              select

                       transportation_type2

                     , avg(speed_similarity*0.25 + acc_similarity*0.25 + steps_similarity*0.25 + dist_similarity*0.25) as total_similarity

              from

                       (

                              select

                                     po.id

                                   , inf.transportation_type2

                                   , least(po.speed_   +0.01,inf.point_avg_speed+0.01)/greatest(po.speed_+0.01,inf.point_avg_speed+0.01) as speed_similarity

                                   , least(po.totalmean+0.01,inf.point_avg_acc+0.01)/greatest(po.totalmean+0.01,inf.point_avg_acc+0.01)  as acc_similarity

                                   , case

                                            when po.totalnumberofsteps    +0.01=0

                                                   and inf.point_avg_steps+0.01=0

                                                   then 1

                                                   else least(po.totalnumberofsteps+0.01,inf.point_avg_steps+0.01)/greatest(po.totalnumberofsteps+0.01,inf.point_avg_steps+0.01)

                                     end as steps_similarity

                                   , case

                                            when po.dist_to_prev+0.01 is null

                                                   then 0

                                                   else least(po.dist_to_prev+0.01,inf.point_avg_dist+0.01)/greatest(po.dist_to_prev+0.01,inf.point_avg_dist+0.01)

                                     end as dist_similarity

                              from

                                     inference_points_stat                      as po

                                   , learning_processes.summary_of_mode2_overall as inf

							  where

									 inf.transportation_type = $2

                       )

                       as foo

              group by

                       transportation_type2

              order by

                       total_similarity desc

     )

   , all_users_period_based_similarity as

     (

              select

                       transportation_type2

                     , dist_similarity*0.33 + duration_similarity*0.33 + speed_similarity*0.33 as total_similarity

              from

                       (

                                select

                                         transportation_type2

                                       , least(sum(dist_to_prev), inf.travelled_distance+0.01) / greatest(sum(dist_to_prev), inf.travelled_distance+0.01)                                                                                       as dist_similarity

                                       , least ((max(time_)-min(time_)), duration_of_tripleg+0.01) / greatest((max(time_)-min(time_)), duration_of_tripleg+0.01)                                                                                as duration_similarity

                                       , least ((1000      *sum(dist_to_prev) / (max(time_)-min(time_))) , inf.speed_overall_of_tripleg+0.01) /greatest((1000*sum(dist_to_prev) / (max(time_)-min(time_))) , inf.speed_overall_of_tripleg+0.01) as speed_similarity

                                from

                                         inference_points_stat                      as po

                                       , learning_processes.summary_of_mode2_overall as inf

								where

										 inf.transportation_type = $2

                                group by

                                         transportation_type2

                                       , inf.travelled_distance+0.01

                                       , duration_of_tripleg   +0.01

                                       , speed_overall_of_tripleg

                                order by

                                         transportation_type2

                       )

                       as foo

              order by

                       total_similarity desc

     )

   , user_specific_point_based_similarity as

     (

              select

                       transportation_type2

                     , avg(speed_similarity*0.25 + acc_similarity*0.25 + steps_similarity*0.25 + dist_similarity*0.25) as total_similarity

              from

                       (

                              select

                                     po.id

                                   , inf.transportation_type2

                                   , least(po.speed_   +0.01,inf.point_avg_speed+0.01)/greatest(po.speed_+0.01,inf.point_avg_speed+0.01) as speed_similarity

                                   , least(po.totalmean+0.01,inf.point_avg_acc+0.01)/greatest(po.totalmean+0.01,inf.point_avg_acc+0.01)  as acc_similarity

                                   , case

                                            when po.totalnumberofsteps    +0.01=0

                                                   and inf.point_avg_steps+0.01=0

                                                   then 1

                                                   else least(po.totalnumberofsteps+0.01,inf.point_avg_steps+0.01)/greatest(po.totalnumberofsteps+0.01,inf.point_avg_steps+0.01)

                                     end as steps_similarity

                                   , case

                                            when po.dist_to_prev+0.01 is null

                                                   then 0

                                                   else least(po.dist_to_prev+0.01,inf.point_avg_dist+0.01)/greatest(po.dist_to_prev+0.01,inf.point_avg_dist+0.01)

                                     end as dist_similarity

                              from

                                     inference_points_stat as po

                                   , (

                                            select *

                                            from

                                                   learning_processes.summary_of_mode2_per_user

                                            where

                                                   user_id =

                                                   (

                                                          select

                                                                 user_id

                                                          from

                                                                 considered_tripleg

                                                   ) and transportation_type = $2

                                     )

                                     as inf

                       )

                       as foo

              group by

                       transportation_type2

              order by

                       total_similarity desc

     )

   , user_specific_period_based_similarity as

     (

              select

                       transportation_type2

                     , dist_similarity*0.33 + duration_similarity*0.33 + speed_similarity*0.33 as total_similarity

              from

                       (

                                select

                                         transportation_type2

                                       , least(sum(dist_to_prev), inf.travelled_distance+0.01) / greatest(sum(dist_to_prev), inf.travelled_distance+0.01)                                                                                       as dist_similarity

                                       , least ((max(time_)-min(time_)), duration_of_tripleg+0.01) / greatest((max(time_)-min(time_)), duration_of_tripleg+0.01)                                                                                as duration_similarity

                                       , least ((1000      *sum(dist_to_prev) / (max(time_)-min(time_))) , inf.speed_overall_of_tripleg+0.01) /greatest((1000*sum(dist_to_prev) / (max(time_)-min(time_))) , inf.speed_overall_of_tripleg+0.01) as speed_similarity

                                from

                                         inference_points_stat as po

                                       , (

                                                select *

                                                from

                                                       learning_processes.summary_of_mode2_per_user

                                                where

                                                       user_id =

                                                       (

                                                              select

                                                                     user_id

                                                              from

                                                                     considered_tripleg

                                                       ) and transportation_type = $2

                                         )

                                         as inf

                                group by

                                         transportation_type2

                                       , inf.travelled_distance+0.01

                                       , duration_of_tripleg   +0.01

                                       , speed_overall_of_tripleg

                                order by

                                         transportation_type2

                       )

                       as foo

              order by

                       total_similarity desc

     )

   , predicted_modes as

     (

                     select

                                     t1.id

                                   ,

                                     (

                                                     case

                                                                     when t2.total_similarity is null

                                                                                     then 0

                                                                                     else t2.total_similarity

                                                     end * 0.125 +

                                                     case

                                                                     when t3.total_similarity is null

                                                                                     then 0

                                                                                     else t3.total_similarity

                                                     end * 0.125 +

                                                     case

                                                                     when t4.total_similarity is null

                                                                                     then 0

                                                                                     else t4.total_similarity

                                                     end * 0.375 +

                                                     case

                                                                     when t5.total_similarity is null

                                                                                     then 0

                                                                                     else t5.total_similarity

                                                     end * 0.375

                                     )

                                     *100 as mode_probability

                                   , t1.name_

                                   , t1.name_en

								   , t1.tariff

								   , t1.toll

								   , t1.parking

                     from

                                     apiv2.travel_mode2_table as t1

                                     left outer join

                                                     all_users_point_based_similarity as t2

                                                     on

                                                                     t1.id = t2.transportation_type2

                                     left outer join

                                                     all_users_period_based_similarity as t3

                                                     on

                                                                     t1.id = t3.transportation_type2

                                     left outer join

                                                     user_specific_point_based_similarity as t4

                                                     on

                                                                     t1.id = t4.transportation_type2

                                     left outer join

                                                     user_specific_period_based_similarity as t5

                                                     on

                                                                     t1.id = t5.transportation_type2

                     where t1.transportation_type = $2 

					 order by

                                     mode_probability desc

     )

select

       array_to_json(array_agg(

       (

              SELECT

                     x

              FROM

                     (

                            SELECT

                                   mode_probability AS accuracy

                                 , id               as id

                                 , name_            as name

                                 , name_en          as name_en

								 , tariff          as tariff

								 , toll          as toll

								 , parking          as parking

                     )

                     x

       )

       )) as mode

FROM

       predicted_modes $_$;


ALTER FUNCTION learning_processes.ap_get_probable_modes2_of_tripleg_json(triplegid bigint, transportation_type_id integer) OWNER TO postgres;

--
-- Name: ap_get_probable_modes_of_tripleg_json(bigint); Type: FUNCTION; Schema: learning_processes; Owner: postgres
--

CREATE FUNCTION learning_processes.ap_get_probable_modes_of_tripleg_json(triplegid bigint) RETURNS json
    LANGUAGE sql
    AS $_$WITH 
considered_tripleg as (select * from apiv2.triplegs_inf where tripleg_id = $1),
inference_points_stat as (SELECT id, time_, speed_, totalmean, totalnumberofsteps, st_distance(st_makepoint(lon_, lat_)::geography, 
		st_makepoint(lag(lon_) over (partition by l1.user_id order by time_ ),
		lag(lat_) over (partition by l1.user_id order by time_ ))::geography) as dist_to_prev 
                 FROM raw_data.location_table as l1, considered_tripleg as l2 where l1.user_id = l2.user_id and l1.time_ between l2.from_time and l2.to_time and accuracy_<=50), 
last_point_of_considered_tripleg as (select lat_, lon_ from raw_data.location_table as l1, considered_tripleg as l2 where l1.id=l2.to_point_id),
transportation_mode_probability as (select array_to_json(array_agg((SELECT x FROM (SELECT id as id, 0 AS certainty, name_ as name, name_sv as name_sv) x) )) as mode FROM apiv2.travel_mode_table),
points as (SELECT array_to_json(array_agg( (SELECT x FROM (
select x from (select id, lat,lon, time) x) as final_selection) ) ) as points from 
(select * from (
SELECT id as id, lat_ AS lat, lon_ AS lon, time_ as time 
                 FROM raw_data.location_table as l1, considered_tripleg as l2 where l1.user_id = l2.user_id and l1.time_ between l2.from_time and l2.to_time and accuracy_<=50) as gps_points)
                 as total_selection),

all_users_point_based_similarity as (
select transportation_type, case when transportation_type = 15 then 0 else avg(speed_similarity*0.25 + acc_similarity*0.25 + steps_similarity*0.25 + dist_similarity*0.25) end as total_similarity
from (
select 
po.id, inf.transportation_type,
least(po.speed_+0.01,inf.point_avg_speed+0.01)/greatest(po.speed_+0.01,inf.point_avg_speed+0.01) as speed_similarity,
least(po.totalmean+0.01,inf.point_avg_acc+0.01)/greatest(po.totalmean+0.01,inf.point_avg_acc+0.01) as acc_similarity,
case when po.totalnumberofsteps+0.01=0 and inf.point_avg_steps+0.01=0 then 1 else least(po.totalnumberofsteps+0.01,inf.point_avg_steps+0.01)/greatest(po.totalnumberofsteps+0.01,inf.point_avg_steps+0.01) end as steps_similarity,
case when po.dist_to_prev+0.01 is null then 0 else least(po.dist_to_prev+0.01,inf.point_avg_dist+0.01)/greatest(po.dist_to_prev+0.01,inf.point_avg_dist+0.01) end as dist_similarity 
from inference_points_stat as po, learning_processes.summary_of_mode_overall as inf) as foo 
group by transportation_type 
order by total_similarity desc ),

all_users_period_based_similarity as (
select transportation_type, dist_similarity*0.33 + duration_similarity*0.33 + speed_similarity*0.33 as total_similarity from 
(select transportation_type,
least(sum(dist_to_prev), inf.travelled_distance+0.01) / greatest(sum(dist_to_prev), inf.travelled_distance+0.01) as dist_similarity,
least ((max(time_)-min(time_)), duration_of_tripleg+0.01) / greatest((max(time_)-min(time_)), duration_of_tripleg+0.01) as duration_similarity,
least ((1000*sum(dist_to_prev) / (max(time_)-min(time_))) , inf.speed_overall_of_tripleg+0.01) /greatest((1000*sum(dist_to_prev) / (max(time_)-min(time_))) , inf.speed_overall_of_tripleg+0.01) as speed_similarity
from inference_points_stat as po, learning_processes.summary_of_mode_overall as inf
group by transportation_type, inf.travelled_distance+0.01, duration_of_tripleg+0.01, speed_overall_of_tripleg
order by transportation_type) as foo 
order by total_similarity desc), 

user_specific_point_based_similarity as (
select transportation_type, case when transportation_type = 15 then 0 else avg(speed_similarity*0.25 + acc_similarity*0.25 + steps_similarity*0.25 + dist_similarity*0.25) end as total_similarity
from (
select 
po.id, inf.transportation_type,
least(po.speed_+0.01,inf.point_avg_speed+0.01)/greatest(po.speed_+0.01,inf.point_avg_speed+0.01) as speed_similarity,
least(po.totalmean+0.01,inf.point_avg_acc+0.01)/greatest(po.totalmean+0.01,inf.point_avg_acc+0.01) as acc_similarity,
case when po.totalnumberofsteps+0.01=0 and inf.point_avg_steps+0.01=0 then 1 else least(po.totalnumberofsteps+0.01,inf.point_avg_steps+0.01)/greatest(po.totalnumberofsteps+0.01,inf.point_avg_steps+0.01) end as steps_similarity,
case when po.dist_to_prev+0.01 is null then 0 else least(po.dist_to_prev+0.01,inf.point_avg_dist+0.01)/greatest(po.dist_to_prev+0.01,inf.point_avg_dist+0.01) end as dist_similarity 
from inference_points_stat as po, (select * from learning_processes.summary_of_mode_per_user where user_id = (select user_id from considered_tripleg)) as inf) as foo 
group by transportation_type 
order by total_similarity desc ),

user_specific_period_based_similarity as (
select transportation_type, dist_similarity*0.33 + duration_similarity*0.33 + speed_similarity*0.33 as total_similarity from 
(select transportation_type,
least(sum(dist_to_prev), inf.travelled_distance+0.01) / greatest(sum(dist_to_prev), inf.travelled_distance+0.01) as dist_similarity,
least ((max(time_)-min(time_)), duration_of_tripleg+0.01) / greatest((max(time_)-min(time_)), duration_of_tripleg+0.01) as duration_similarity,
least ((1000*sum(dist_to_prev) / (max(time_)-min(time_))) , inf.speed_overall_of_tripleg+0.01) /greatest((1000*sum(dist_to_prev) / (max(time_)-min(time_))) , inf.speed_overall_of_tripleg+0.01) as speed_similarity
from inference_points_stat as po, (select * from learning_processes.summary_of_mode_per_user where user_id = (select user_id from considered_tripleg)) as inf 
group by transportation_type, inf.travelled_distance+0.01, duration_of_tripleg+0.01, speed_overall_of_tripleg
order by transportation_type) as foo 
order by total_similarity desc ), 
predicted_modes as (
select t1.id, (case when t2.total_similarity is null then 0 else t2.total_similarity end * 0.125 + case when t3.total_similarity is null then 0 else t3.total_similarity end * 0.125 
+ case when t4.total_similarity is null then 0 else t4.total_similarity end * 0.375
+ case when t5.total_similarity is null then 0 else t5.total_similarity end * 0.375) *100 as mode_probability,
t1.name_, t1.name_sv
from apiv2.travel_mode_table as t1
left outer join all_users_point_based_similarity as t2 on t1.id = t2.transportation_type 
left outer join all_users_period_based_similarity as t3 on t1.id = t3.transportation_type 
left outer join user_specific_point_based_similarity as t4 on t1.id = t4.transportation_type 
left outer join user_specific_period_based_similarity as t5 on t1.id = t5.transportation_type 
order by mode_probability desc 
) 

select array_to_json(array_agg((SELECT x FROM (SELECT mode_probability AS accuracy, id as id, name_ as name, name_sv as name_sv) x) )) as mode FROM predicted_modes
$_$;


ALTER FUNCTION learning_processes.ap_get_probable_modes_of_tripleg_json(triplegid bigint) OWNER TO postgres;

--
-- Name: ap_get_purposes(integer); Type: FUNCTION; Schema: learning_processes; Owner: postgres
--

CREATE FUNCTION learning_processes.ap_get_purposes(trip_id integer) RETURNS json
    LANGUAGE sql
    AS $_$
--explain 
WITH   
trip_candidate as (select * from apiv2.trips_inf
where trip_id = $1),
user_generated_trips as 
(
select  
EXTRACT (DOW FROM to_timestamp(to_time/1000)) as to_time_dow, 
EXTRACT (HOUR FROM to_timestamp(to_time/1000)) as to_time_hour,
purpose_id,
count(*) 
from apiv2.trips_gt 
group by -- from_time_dow, from_time_hour, 
to_time_dow, to_time_hour, purpose_id
), 
crowd_knowledge as 
(select t2.purpose_id, 
	case when @(EXTRACT (HOUR FROM to_timestamp(t1.to_time/1000)) - t2.to_time_hour) = 0 
		then count 
		else count / @(EXTRACT (HOUR FROM to_timestamp(t1.to_time/1000)) - t2.to_time_hour) end as prob 
		from user_generated_trips as t2, trip_candidate as t1
where EXTRACT (DOW FROM to_timestamp(t1.to_time/1000)) = t2.to_time_dow
and @(EXTRACT (HOUR FROM to_timestamp(t1.to_time/1000)) - t2.to_time_hour )<=2 
order by prob), 
user_history as 
(select t2.purpose_id, 2*count(*) as count from apiv2.trips_gt as t2, trip_candidate as t1
where t2.destination_poi_id = t1.destination_poi_id
and t2.user_id = $1
group by t2.purpose_id 
order by count),
purpose_inference as (select case when exists (select * from user_history) 
then (select array_to_json(array_agg(x order by accuracy desc)) from 
 
(select purpose_id as id, case when count > 20 then 100 else count*5 end as accuracy, (select name_ from apiv2.purpose_table pt where pt.id = foo.purpose_id) as name, (select name_sv from apiv2.purpose_table pt where pt.id = foo.purpose_id) as name_sv 
from(
select distinct on (purpose_id) * from user_history 
union all (select id, 0 from apiv2.purpose_table
 where not id = any (select purpose_id from user_history ))  
) as foo order by accuracy desc) x
)
else (select array_to_json(array_agg(x order by accuracy desc)) from 
 
(select distinct on (purpose_id) purpose_id as id, case when count > 20 then 100 else count*5 end as accuracy, 
	(select name_ from apiv2.purpose_table pt where pt.id = foo.purpose_id) as name, (select name_sv from apiv2.purpose_table pt where pt.id = foo.purpose_id) as name_sv 
from(
select purpose_id, prob as count from crowd_knowledge
union all (select id, 0 as count from apiv2.purpose_table 
 where not id = any (select purpose_id from crowd_knowledge) 
 )
 order by count desc  
) as foo) x 
) end) 

select array_to_json as purposes from purpose_inference
$_$;


ALTER FUNCTION learning_processes.ap_get_purposes(trip_id integer) OWNER TO postgres;

--
-- Name: refresh_materialized_views(); Type: FUNCTION; Schema: learning_processes; Owner: postgres
--

CREATE FUNCTION learning_processes.refresh_materialized_views() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE 
last_refresh_date_of_view date;
annotation_date_of_trip date; 
BEGIN  
	
  annotation_date_of_trip := to_timestamp(NEW.to_time/1000)::date;
  last_refresh_date_of_view := last_refreshed from learning_processes.summary_of_mode_overall limit 1; 

  raise notice '%, %',annotation_date_of_trip , last_refresh_date_of_view;

  IF last_refresh_date_of_view IS NULL THEN 
	raise notice 'Refreshing materialized view for the first time';
	refresh materialized view learning_processes.summary_of_mode_overall;
	refresh materialized view learning_processes.summary_of_mode_per_user;
	refresh materialized view learning_processes.summary_of_mode2_overall;
	refresh materialized view learning_processes.summary_of_mode2_per_user;
	ELSE 
		IF last_refresh_date_of_view < annotation_date_of_trip THEN 
			raise notice 'Refreshing materialized view';
			refresh materialized view learning_processes.summary_of_mode_overall;
			refresh materialized view learning_processes.summary_of_mode_per_user;
			refresh materialized view learning_processes.summary_of_mode2_overall;
			refresh materialized view learning_processes.summary_of_mode2_per_user;
		ELSE RETURN NEW;
		END IF; 
	END IF; 
  RETURN NEW; 
END; 
$$;


ALTER FUNCTION learning_processes.refresh_materialized_views() OWNER TO postgres;

--
-- Name: db_to_csv(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.db_to_csv(path text) RETURNS void
    LANGUAGE plpgsql
    AS $$declare
   tables RECORD;
   statement TEXT;
begin
FOR tables IN 
   SELECT (table_schema || '.' || table_name) AS schema_table
   FROM information_schema.tables t INNER JOIN information_schema.schemata s 
   ON s.schema_name = t.table_schema 
   WHERE t.table_schema NOT IN ('pg_catalog', 'information_schema') AND t.table_type NOT IN ('VIEW')
   ORDER BY schema_table
LOOP
   statement := 'COPY ' || tables.schema_table || ' TO ''' || path || '/' || tables.schema_table || '.csv' ||''' DELIMITER '';'' CSV HEADER';
   EXECUTE statement;
END LOOP;
statement := 'COPY (SELECT * FROM apiv2.detail_trip_activity) TO ''' || path || '/apiv2.detail_trip_activity.csv' ||''' DELIMITER '';'' CSV HEADER';
EXECUTE statement;
statement := 'COPY (SELECT * FROM apiv2.detail_trip_tripleg) TO ''' || path || '/apiv2.detail_trip_tripleg.csv' ||''' DELIMITER '';'' CSV HEADER';
EXECUTE statement;
return;  
end;
$$;


ALTER FUNCTION public.db_to_csv(path text) OWNER TO postgres;

--
-- Name: login_user(public.citext, text); Type: FUNCTION; Schema: raw_data; Owner: postgres
--

CREATE FUNCTION raw_data.login_user(username public.citext, password text) RETURNS integer
    LANGUAGE sql
    AS $_$SELECT id from raw_data.user_TABLE 
where 
username = $1
and password = crypt($2, password);$_$;


ALTER FUNCTION raw_data.login_user(username public.citext, password text) OWNER TO postgres;

--
-- Name: FUNCTION login_user(username public.citext, password text); Type: COMMENT; Schema: raw_data; Owner: postgres
--

COMMENT ON FUNCTION raw_data.login_user(username public.citext, password text) IS 'checks if the credentials are correct and returns the user_id for the api end point related to login_user';


--
-- Name: register_user(public.citext, text, text, text, text, text); Type: FUNCTION; Schema: raw_data; Owner: postgres
--

CREATE FUNCTION raw_data.register_user(username public.citext, password text, phone_model text, phone_os text, phone_number text, reg_no text) RETURNS integer
    LANGUAGE sql
    AS $_$
	INSERT INTO raw_data.user_TABLE (username, password, phone_model, phone_os, phone_number, reg_no)
	VALUES ($1, crypt($2, gen_salt('bf',8)), $3, $4, $5, $6)
	RETURNING id;
$_$;


ALTER FUNCTION raw_data.register_user(username public.citext, password text, phone_model text, phone_os text, phone_number text, reg_no text) OWNER TO postgres;

--
-- Name: FUNCTION register_user(username public.citext, password text, phone_model text, phone_os text, phone_number text, reg_no text); Type: COMMENT; Schema: raw_data; Owner: postgres
--

COMMENT ON FUNCTION raw_data.register_user(username public.citext, password text, phone_model text, phone_os text, phone_number text, reg_no text) IS 'inserts a new user with hashed password and returns the user_id for the api end point related to register_user';


--
-- Name: update_user_password(public.citext, text); Type: FUNCTION; Schema: raw_data; Owner: postgres
--

CREATE FUNCTION raw_data.update_user_password(username public.citext, password text) RETURNS boolean
    LANGUAGE sql
    AS $_$
	UPDATE raw_data.user_table 
	SET PASSWORD = crypt($2, gen_salt('bf',8))
	WHERE username = $1
	RETURNING true;
$_$;


ALTER FUNCTION raw_data.update_user_password(username public.citext, password text) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: activities_gt; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.activities_gt (
    trip_id integer NOT NULL,
    activity_id integer NOT NULL,
    activity_order smallint DEFAULT 1
);


ALTER TABLE apiv2.activities_gt OWNER TO postgres;

--
-- Name: activities_inf; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.activities_inf (
    trip_id integer NOT NULL,
    activity_id integer NOT NULL,
    activity_order smallint DEFAULT 1 NOT NULL
);


ALTER TABLE apiv2.activities_inf OWNER TO postgres;

--
-- Name: activity_table_id_seq; Type: SEQUENCE; Schema: apiv2; Owner: postgres
--

CREATE SEQUENCE apiv2.activity_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE apiv2.activity_table_id_seq OWNER TO postgres;

--
-- Name: activity_table; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.activity_table (
    id integer DEFAULT nextval('apiv2.activity_table_id_seq'::regclass) NOT NULL,
    name_ text,
    name_en text,
    created_by integer
);


ALTER TABLE apiv2.activity_table OWNER TO postgres;

--
-- Name: trips_inf; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.trips_inf (
    user_id bigint,
    from_point_id bigint,
    to_point_id bigint,
    from_time bigint,
    to_time bigint,
    type_of_trip smallint,
    purpose_id integer,
    destination_poi_id bigint,
    length_of_trip double precision,
    duration_of_trip double precision,
    number_of_triplegs integer,
    trip_id integer NOT NULL,
    parent_trip_id bigint,
    CONSTRAINT trip_temporal_integrity CHECK ((from_time <= to_time))
);


ALTER TABLE apiv2.trips_inf OWNER TO postgres;

--
-- Name: TABLE trips_inf; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON TABLE apiv2.trips_inf IS 'Stores the trips that have been detected by the segmentation algorithm';


--
-- Name: all_trips; Type: VIEW; Schema: apiv2; Owner: postgres
--

CREATE VIEW apiv2.all_trips AS
 SELECT ti.user_id,
    ti.from_point_id,
    ti.to_point_id,
    ti.from_time,
    ti.to_time,
    ti.type_of_trip,
    ti.purpose_id,
    ti.destination_poi_id,
    ti.length_of_trip,
    ti.duration_of_trip,
    ti.number_of_triplegs,
    ti.trip_id,
    ti.parent_trip_id
   FROM apiv2.trips_inf ti
  WHERE (ti.type_of_trip = 1);


ALTER TABLE apiv2.all_trips OWNER TO postgres;

--
-- Name: VIEW all_trips; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON VIEW apiv2.all_trips IS 'Used to serve the all triplegs per trip - selection per trip_id';


--
-- Name: triplegs_inf; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.triplegs_inf (
    user_id integer,
    from_point_id bigint,
    to_point_id bigint,
    from_time bigint,
    to_time bigint,
    type_of_tripleg smallint,
    transportation_type integer,
    transition_poi_id bigint,
    length_of_tripleg double precision,
    duration_of_tripleg double precision,
    tripleg_id integer NOT NULL,
    trip_id integer,
    parent_tripleg_id bigint,
    transportation_type2 integer,
    tariff bigint,
    toll bigint,
    parking bigint,
    CONSTRAINT tripleg_temporal_integrity CHECK ((from_time <= to_time))
);


ALTER TABLE apiv2.triplegs_inf OWNER TO postgres;

--
-- Name: TABLE triplegs_inf; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON TABLE apiv2.triplegs_inf IS 'Stores the triplegs that have been detected by the segmentation algorithm';


--
-- Name: all_triplegs; Type: VIEW; Schema: apiv2; Owner: postgres
--

CREATE VIEW apiv2.all_triplegs AS
 SELECT triplegs_inf.user_id,
    triplegs_inf.from_point_id,
    triplegs_inf.to_point_id,
    triplegs_inf.from_time,
    triplegs_inf.to_time,
    triplegs_inf.type_of_tripleg,
    triplegs_inf.transportation_type,
    triplegs_inf.transition_poi_id,
    triplegs_inf.length_of_tripleg,
    triplegs_inf.duration_of_tripleg,
    triplegs_inf.tripleg_id,
    triplegs_inf.trip_id,
    triplegs_inf.parent_tripleg_id
   FROM apiv2.triplegs_inf
  WHERE (triplegs_inf.trip_id IN ( SELECT all_trips.trip_id
           FROM apiv2.all_trips));


ALTER TABLE apiv2.all_triplegs OWNER TO postgres;

--
-- Name: trips_gt; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.trips_gt (
    trip_id integer NOT NULL,
    trip_inf_id integer,
    user_id bigint,
    from_point_id text,
    to_point_id text,
    from_time bigint,
    to_time bigint,
    type_of_trip smallint,
    purpose_id integer,
    destination_poi_id bigint NOT NULL,
    length_of_trip double precision,
    duration_of_trip double precision,
    number_of_triplegs integer
);


ALTER TABLE apiv2.trips_gt OWNER TO postgres;

--
-- Name: TABLE trips_gt; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON TABLE apiv2.trips_gt IS 'Stores the trips that have been annotated by the user';


--
-- Name: trips_inf_deleted; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.trips_inf_deleted (
    trip_inf_id integer NOT NULL,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE apiv2.trips_inf_deleted OWNER TO postgres;

--
-- Name: TABLE trips_inf_deleted; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON TABLE apiv2.trips_inf_deleted IS 'all deleted trips are stored here';


--
-- Name: all_unprocessed_trips; Type: VIEW; Schema: apiv2; Owner: postgres
--

CREATE VIEW apiv2.all_unprocessed_trips AS
 SELECT ti.user_id,
    ti.from_point_id,
    ti.to_point_id,
    ti.from_time,
    ti.to_time,
    ti.type_of_trip,
    ti.purpose_id,
    ti.destination_poi_id,
    ti.length_of_trip,
    ti.duration_of_trip,
    ti.number_of_triplegs,
    ti.trip_id,
    ti.parent_trip_id
   FROM apiv2.trips_inf ti
  WHERE ((ti.from_time >= ( SELECT COALESCE(max(tg.to_time), (0)::bigint) AS "coalesce"
           FROM apiv2.trips_gt tg
          WHERE ((tg.user_id = ti.user_id) AND (tg.type_of_trip = 1)))) AND ((ti.type_of_trip = 1) OR (ti.trip_id IN ( SELECT trips_inf_deleted.trip_inf_id
           FROM apiv2.trips_inf_deleted))));


ALTER TABLE apiv2.all_unprocessed_trips OWNER TO postgres;

--
-- Name: VIEW all_unprocessed_trips; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON VIEW apiv2.all_unprocessed_trips IS 'Unprocessed trips + deleted trips';


--
-- Name: all_unprocessed_triplegs; Type: VIEW; Schema: apiv2; Owner: postgres
--

CREATE VIEW apiv2.all_unprocessed_triplegs AS
 SELECT triplegs_inf.user_id,
    triplegs_inf.from_point_id,
    triplegs_inf.to_point_id,
    triplegs_inf.from_time,
    triplegs_inf.to_time,
    triplegs_inf.type_of_tripleg,
    triplegs_inf.transportation_type,
    triplegs_inf.transition_poi_id,
    triplegs_inf.length_of_tripleg,
    triplegs_inf.duration_of_tripleg,
    triplegs_inf.tripleg_id,
    triplegs_inf.trip_id,
    triplegs_inf.parent_tripleg_id
   FROM apiv2.triplegs_inf
  WHERE (triplegs_inf.trip_id IN ( SELECT all_unprocessed_trips.trip_id
           FROM apiv2.all_unprocessed_trips));


ALTER TABLE apiv2.all_unprocessed_triplegs OWNER TO postgres;

--
-- Name: VIEW all_unprocessed_triplegs; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON VIEW apiv2.all_unprocessed_triplegs IS 'Unprocessed triplegs + deleted triplegs';


--
-- Name: processed_trips; Type: VIEW; Schema: apiv2; Owner: postgres
--

CREATE VIEW apiv2.processed_trips AS
 SELECT trips_gt.trip_id,
    trips_gt.trip_inf_id,
    trips_gt.user_id,
    trips_gt.from_point_id,
    trips_gt.to_point_id,
    trips_gt.from_time,
    trips_gt.to_time,
    trips_gt.type_of_trip,
    trips_gt.purpose_id,
    trips_gt.destination_poi_id,
    trips_gt.length_of_trip,
    trips_gt.duration_of_trip,
    trips_gt.number_of_triplegs
   FROM apiv2.trips_gt
  WHERE (trips_gt.type_of_trip = 1);


ALTER TABLE apiv2.processed_trips OWNER TO postgres;

--
-- Name: location_table; Type: TABLE; Schema: raw_data; Owner: postgres
--

CREATE TABLE raw_data.location_table (
    id integer NOT NULL,
    upload boolean DEFAULT false,
    accuracy_ double precision,
    altitude_ double precision,
    bearing_ double precision,
    lat_ double precision,
    lon_ double precision,
    time_ bigint,
    speed_ double precision,
    satellites_ integer,
    user_id integer,
    size integer,
    totalismoving boolean,
    totalmax real,
    totalmean real,
    totalmin real,
    totalnumberofpeaks integer,
    totalnumberofsteps integer,
    totalstddev real,
    xismoving boolean,
    xmaximum real,
    xmean real,
    xminimum real,
    xnumberofpeaks integer,
    xstddev real,
    yismoving boolean,
    ymax real,
    ymean real,
    ymin real,
    ynumberofpeaks integer,
    ystddev real,
    zismoving boolean,
    zmax real,
    zmean real,
    zmin real,
    znumberofpeaks integer,
    zstddev real,
    provider text,
    pref_min_acc integer,
    pref_min_dist integer,
    pref_min_time integer,
    pref_acc_threshold real,
    pref_acc_period real,
    pref_acc_saving real,
    row_inserted_ timestamp with time zone DEFAULT now()
);


ALTER TABLE raw_data.location_table OWNER TO postgres;

--
-- Name: TABLE location_table; Type: COMMENT; Schema: raw_data; Owner: postgres
--

COMMENT ON TABLE raw_data.location_table IS 'stores the locations retrieved from the clients';


--
-- Name: detail_trip_activity; Type: VIEW; Schema: apiv2; Owner: postgres
--

CREATE VIEW apiv2.detail_trip_activity AS
 SELECT m.user_id,
    m.trip_id,
    m.trip_inf_id,
    m.from_time,
    m.from_lon_,
    m.from_lat_,
    m.to_time,
    m.to_lon_,
    m.to_lat_,
    a.activity_id,
    a.activity_order,
    ac.id,
    ac.name_,
    ac.name_en,
    ac.created_by
   FROM ( SELECT a_1.user_id,
            a_1.trip_id,
            a_1.trip_inf_id,
            a_1.from_time,
            a_1.loc_from_time_,
            a_1.from_lon_,
            a_1.from_lat_,
            b.user_id_,
            b.trip_id_,
            b.trip_inf_id_,
            b.to_time,
            b.loc_to_time_,
            b.to_lon_,
            b.to_lat_
           FROM ( SELECT pt.user_id,
                    pt.trip_id,
                    pt.trip_inf_id,
                    (to_timestamp(((pt.from_time / 1000))::double precision))::timestamp without time zone AS from_time,
                    (to_timestamp(((lt.time_ / 1000))::double precision))::timestamp without time zone AS loc_from_time_,
                    lt.lon_ AS from_lon_,
                    lt.lat_ AS from_lat_
                   FROM apiv2.processed_trips pt,
                    raw_data.location_table lt
                  WHERE ((pt.user_id = lt.user_id) AND (pt.from_time = lt.time_))
                  ORDER BY pt.user_id, pt.trip_id) a_1,
            ( SELECT pt.user_id AS user_id_,
                    pt.trip_id AS trip_id_,
                    pt.trip_inf_id AS trip_inf_id_,
                    (to_timestamp(((pt.to_time / 1000))::double precision))::timestamp without time zone AS to_time,
                    (to_timestamp(((lt.time_ / 1000))::double precision))::timestamp without time zone AS loc_to_time_,
                    lt.lon_ AS to_lon_,
                    lt.lat_ AS to_lat_
                   FROM apiv2.processed_trips pt,
                    raw_data.location_table lt
                  WHERE ((pt.user_id = lt.user_id) AND (pt.to_time = lt.time_))
                  ORDER BY pt.user_id, pt.trip_id) b
          WHERE ((a_1.user_id = b.user_id_) AND (a_1.trip_id = b.trip_id_) AND (a_1.trip_inf_id = b.trip_inf_id_))) m,
    apiv2.activities_gt a,
    apiv2.activity_table ac
  WHERE ((m.trip_id = a.trip_id) AND (a.activity_id = ac.id))
  ORDER BY m.user_id, m.trip_id;


ALTER TABLE apiv2.detail_trip_activity OWNER TO postgres;

--
-- Name: VIEW detail_trip_activity; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON VIEW apiv2.detail_trip_activity IS 'keperluan untuk generate report';


--
-- Name: travel_mode2_table; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.travel_mode2_table (
    id smallint NOT NULL,
    name_ text NOT NULL,
    name_en text,
    transportation_type integer NOT NULL,
    tariff json,
    toll json,
    parking json
);


ALTER TABLE apiv2.travel_mode2_table OWNER TO postgres;

--
-- Name: triplegs_gt; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.triplegs_gt (
    tripleg_id integer NOT NULL,
    tripleg_inf_id integer,
    trip_id integer,
    user_id bigint,
    from_point_id text,
    to_point_id text,
    from_time bigint,
    to_time bigint,
    type_of_tripleg smallint,
    transportation_type integer,
    transition_poi_id bigint,
    length_of_tripleg double precision,
    duration_of_tripleg double precision,
    transportation_type2 integer,
    tariff bigint,
    toll bigint,
    parking bigint,
    CONSTRAINT valid_travel_mode CHECK (((type_of_tripleg = 0) OR (transportation_type IS NOT NULL))),
    CONSTRAINT valid_travel_mode2 CHECK (((type_of_tripleg = 0) OR (transportation_type2 IS NOT NULL)))
);


ALTER TABLE apiv2.triplegs_gt OWNER TO postgres;

--
-- Name: TABLE triplegs_gt; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON TABLE apiv2.triplegs_gt IS 'Stores the triplegs that have been annotated by the user';


--
-- Name: detail_trip_tripleg; Type: VIEW; Schema: apiv2; Owner: postgres
--

CREATE VIEW apiv2.detail_trip_tripleg AS
 SELECT m.user_id,
    m.trip_id,
    m.tripleg_id,
    m.tripleg_inf_id,
    m.from_time,
    m.from_lon_,
    m.from_lat_,
    m.to_time,
    m.to_lon_,
    m.to_lat_,
    m.transportation_type,
    m.transportation_type2,
    m.tariff,
    m.parking,
    tm.id,
    tm.name_,
    tm.name_en
   FROM ( SELECT a.user_id,
            a.trip_id,
            a.tripleg_id,
            a.tripleg_inf_id,
            a.from_time,
            a.from_lon_,
            a.from_lat_,
            b.to_time,
            b.to_lon_,
            b.to_lat_,
            a.transportation_type,
            a.transportation_type2,
            a.tariff,
            a.parking
           FROM ( SELECT t.user_id,
                    tl.trip_id,
                    tl.tripleg_id,
                    tl.tripleg_inf_id,
                    (to_timestamp(((tl.from_time / 1000))::double precision))::timestamp without time zone AS from_time,
                    (to_timestamp(((lt.time_ / 1000))::double precision))::timestamp without time zone AS loc_from_time_,
                    lt.lon_ AS from_lon_,
                    lt.lat_ AS from_lat_,
                    tl.transportation_type,
                    tl.transportation_type2,
                    tl.tariff,
                    tl.parking
                   FROM apiv2.triplegs_gt tl,
                    apiv2.trips_gt t,
                    raw_data.location_table lt
                  WHERE ((tl.user_id = t.user_id) AND (tl.trip_id = t.trip_id) AND (tl.user_id = lt.user_id) AND (tl.from_time = lt.time_) AND (tl.type_of_tripleg = 1))) a,
            ( SELECT t.user_id AS user_id_,
                    tl.trip_id AS trip_id_,
                    tl.tripleg_id AS tripleg_id_,
                    tl.tripleg_inf_id AS tripleg_inf_id_,
                    (to_timestamp(((tl.to_time / 1000))::double precision))::timestamp without time zone AS to_time,
                    (to_timestamp(((lt.time_ / 1000))::double precision))::timestamp without time zone AS loc_to_time_,
                    lt.lon_ AS to_lon_,
                    lt.lat_ AS to_lat_,
                    tl.transportation_type,
                    tl.transportation_type2,
                    tl.tariff,
                    tl.parking
                   FROM apiv2.triplegs_gt tl,
                    apiv2.trips_gt t,
                    raw_data.location_table lt
                  WHERE ((tl.user_id = t.user_id) AND (tl.trip_id = t.trip_id) AND (tl.user_id = lt.user_id) AND (tl.to_time = lt.time_) AND (tl.type_of_tripleg = 1))) b
          WHERE ((a.user_id = b.user_id_) AND (a.trip_id = b.trip_id_) AND (a.tripleg_id = b.tripleg_id_))) m,
    apiv2.travel_mode2_table tm
  WHERE (m.transportation_type2 = tm.id)
  ORDER BY m.user_id, m.trip_id, m.from_time;


ALTER TABLE apiv2.detail_trip_tripleg OWNER TO postgres;

--
-- Name: VIEW detail_trip_tripleg; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON VIEW apiv2.detail_trip_tripleg IS 'kebutuhan untuk generate report';


--
-- Name: poi_transportation; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.poi_transportation (
    gid integer NOT NULL,
    osm_id bigint DEFAULT 0,
    type_ text,
    name_ text,
    lat_ double precision,
    lon_ double precision,
    declared_by_user boolean DEFAULT false,
    transportation_lines text,
    transportation_types text,
    declaring_user_id integer,
    type_sv text,
    geom public.geometry(Point)
);


ALTER TABLE apiv2.poi_transportation OWNER TO postgres;

--
-- Name: TABLE poi_transportation; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON TABLE apiv2.poi_transportation IS 'Stores the transportation POIs used by the app';


--
-- Name: poi_transportation_gid_seq; Type: SEQUENCE; Schema: apiv2; Owner: postgres
--

CREATE SEQUENCE apiv2.poi_transportation_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE apiv2.poi_transportation_gid_seq OWNER TO postgres;

--
-- Name: poi_transportation_gid_seq; Type: SEQUENCE OWNED BY; Schema: apiv2; Owner: postgres
--

ALTER SEQUENCE apiv2.poi_transportation_gid_seq OWNED BY apiv2.poi_transportation.gid;


--
-- Name: pois; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.pois (
    gid integer NOT NULL,
    type_ text,
    name_ text,
    lat_ double precision,
    lon_ double precision,
    user_id bigint,
    osm_id bigint DEFAULT 0,
    is_personal boolean,
    geom public.geometry(Point)
);


ALTER TABLE apiv2.pois OWNER TO postgres;

--
-- Name: TABLE pois; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON TABLE apiv2.pois IS 'Stores the POIs used by the app';


--
-- Name: pois_gid_seq; Type: SEQUENCE; Schema: apiv2; Owner: postgres
--

CREATE SEQUENCE apiv2.pois_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE apiv2.pois_gid_seq OWNER TO postgres;

--
-- Name: pois_gid_seq; Type: SEQUENCE OWNED BY; Schema: apiv2; Owner: postgres
--

ALTER SEQUENCE apiv2.pois_gid_seq OWNED BY apiv2.pois.gid;


--
-- Name: processed_triplegs; Type: VIEW; Schema: apiv2; Owner: postgres
--

CREATE VIEW apiv2.processed_triplegs AS
 SELECT triplegs_inf.user_id,
    triplegs_inf.from_point_id,
    triplegs_inf.to_point_id,
    triplegs_inf.from_time,
    triplegs_inf.to_time,
    triplegs_inf.type_of_tripleg,
    triplegs_inf.transportation_type,
    triplegs_inf.transition_poi_id,
    triplegs_inf.length_of_tripleg,
    triplegs_inf.duration_of_tripleg,
    triplegs_inf.tripleg_id,
    triplegs_inf.trip_id,
    triplegs_inf.parent_tripleg_id
   FROM apiv2.triplegs_inf
  WHERE (triplegs_inf.trip_id IN ( SELECT processed_trips.trip_inf_id
           FROM apiv2.processed_trips));


ALTER TABLE apiv2.processed_triplegs OWNER TO postgres;

--
-- Name: purpose_table; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.purpose_table (
    id smallint NOT NULL,
    name_ text,
    name_sv text
);


ALTER TABLE apiv2.purpose_table OWNER TO postgres;

--
-- Name: TABLE purpose_table; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON TABLE apiv2.purpose_table IS 'Stores the purpose schema';


--
-- Name: report_table_id_seq; Type: SEQUENCE; Schema: apiv2; Owner: postgres
--

CREATE SEQUENCE apiv2.report_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE apiv2.report_table_id_seq OWNER TO postgres;

--
-- Name: report_table; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.report_table (
    id integer DEFAULT nextval('apiv2.report_table_id_seq'::regclass) NOT NULL,
    content text,
    report_type integer,
    trip_id integer,
    user_id integer
);


ALTER TABLE apiv2.report_table OWNER TO postgres;

--
-- Name: report_type_table; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.report_type_table (
    id integer NOT NULL,
    name text
);


ALTER TABLE apiv2.report_type_table OWNER TO postgres;

--
-- Name: tariff_train; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.tariff_train (
    poi_from_id integer NOT NULL,
    poi_to_id integer NOT NULL,
    tariff bigint NOT NULL
);


ALTER TABLE apiv2.tariff_train OWNER TO postgres;

--
-- Name: travel_mode_table; Type: TABLE; Schema: apiv2; Owner: postgres
--

CREATE TABLE apiv2.travel_mode_table (
    id smallint NOT NULL,
    name_ text,
    name_sv text
);


ALTER TABLE apiv2.travel_mode_table OWNER TO postgres;

--
-- Name: TABLE travel_mode_table; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON TABLE apiv2.travel_mode_table IS 'Stores the travel mode schema';


--
-- Name: triplegs_gt_tripleg_id_seq; Type: SEQUENCE; Schema: apiv2; Owner: postgres
--

CREATE SEQUENCE apiv2.triplegs_gt_tripleg_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE apiv2.triplegs_gt_tripleg_id_seq OWNER TO postgres;

--
-- Name: triplegs_gt_tripleg_id_seq; Type: SEQUENCE OWNED BY; Schema: apiv2; Owner: postgres
--

ALTER SEQUENCE apiv2.triplegs_gt_tripleg_id_seq OWNED BY apiv2.triplegs_gt.tripleg_id;


--
-- Name: triplegs_inf_tripleg_id_seq; Type: SEQUENCE; Schema: apiv2; Owner: postgres
--

CREATE SEQUENCE apiv2.triplegs_inf_tripleg_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE apiv2.triplegs_inf_tripleg_id_seq OWNER TO postgres;

--
-- Name: triplegs_inf_tripleg_id_seq; Type: SEQUENCE OWNED BY; Schema: apiv2; Owner: postgres
--

ALTER SEQUENCE apiv2.triplegs_inf_tripleg_id_seq OWNED BY apiv2.triplegs_inf.tripleg_id;


--
-- Name: trips_gt_trip_id_seq; Type: SEQUENCE; Schema: apiv2; Owner: postgres
--

CREATE SEQUENCE apiv2.trips_gt_trip_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE apiv2.trips_gt_trip_id_seq OWNER TO postgres;

--
-- Name: trips_gt_trip_id_seq; Type: SEQUENCE OWNED BY; Schema: apiv2; Owner: postgres
--

ALTER SEQUENCE apiv2.trips_gt_trip_id_seq OWNED BY apiv2.trips_gt.trip_id;


--
-- Name: trips_inf_trip_id_seq; Type: SEQUENCE; Schema: apiv2; Owner: postgres
--

CREATE SEQUENCE apiv2.trips_inf_trip_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE apiv2.trips_inf_trip_id_seq OWNER TO postgres;

--
-- Name: trips_inf_trip_id_seq; Type: SEQUENCE OWNED BY; Schema: apiv2; Owner: postgres
--

ALTER SEQUENCE apiv2.trips_inf_trip_id_seq OWNED BY apiv2.trips_inf.trip_id;


--
-- Name: unprocessed_trips; Type: VIEW; Schema: apiv2; Owner: postgres
--

CREATE VIEW apiv2.unprocessed_trips AS
 SELECT ti.user_id,
    ti.from_point_id,
    ti.to_point_id,
    ti.from_time,
    ti.to_time,
    ti.type_of_trip,
    ti.purpose_id,
    ti.destination_poi_id,
    ti.length_of_trip,
    ti.duration_of_trip,
    ti.number_of_triplegs,
    ti.trip_id,
    ti.parent_trip_id
   FROM apiv2.trips_inf ti
  WHERE ((ti.from_time >= ( SELECT COALESCE(max(tg.to_time), (0)::bigint) AS "coalesce"
           FROM apiv2.trips_gt tg
          WHERE ((tg.user_id = ti.user_id) AND (tg.type_of_trip = 1)))) AND (ti.type_of_trip = 1));


ALTER TABLE apiv2.unprocessed_trips OWNER TO postgres;

--
-- Name: VIEW unprocessed_trips; Type: COMMENT; Schema: apiv2; Owner: postgres
--

COMMENT ON VIEW apiv2.unprocessed_trips IS 'Used to serve the annotated triplegs per trip - selection per trip_id';


--
-- Name: unprocessed_triplegs; Type: VIEW; Schema: apiv2; Owner: postgres
--

CREATE VIEW apiv2.unprocessed_triplegs AS
 SELECT triplegs_inf.user_id,
    triplegs_inf.from_point_id,
    triplegs_inf.to_point_id,
    triplegs_inf.from_time,
    triplegs_inf.to_time,
    triplegs_inf.type_of_tripleg,
    triplegs_inf.transportation_type,
    triplegs_inf.transition_poi_id,
    triplegs_inf.length_of_tripleg,
    triplegs_inf.duration_of_tripleg,
    triplegs_inf.tripleg_id,
    triplegs_inf.trip_id,
    triplegs_inf.parent_tripleg_id
   FROM apiv2.triplegs_inf
  WHERE (triplegs_inf.trip_id IN ( SELECT unprocessed_trips.trip_id
           FROM apiv2.unprocessed_trips));


ALTER TABLE apiv2.unprocessed_triplegs OWNER TO postgres;

--
-- Name: surveyor_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: meili
--

CREATE SEQUENCE dashboard.surveyor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.surveyor_id_seq OWNER TO meili;

--
-- Name: surveyor; Type: TABLE; Schema: dashboard; Owner: meili
--

CREATE TABLE dashboard.surveyor (
    id integer DEFAULT nextval('dashboard.surveyor_id_seq'::regclass) NOT NULL,
    username public.citext NOT NULL,
    password text NOT NULL
);


ALTER TABLE dashboard.surveyor OWNER TO meili;

--
-- Name: surveyor_respondent_id_seq; Type: SEQUENCE; Schema: dashboard; Owner: meili
--

CREATE SEQUENCE dashboard.surveyor_respondent_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dashboard.surveyor_respondent_id_seq OWNER TO meili;

--
-- Name: surveyor_respondent; Type: TABLE; Schema: dashboard; Owner: meili
--

CREATE TABLE dashboard.surveyor_respondent (
    id integer DEFAULT nextval('dashboard.surveyor_respondent_id_seq'::regclass) NOT NULL,
    surveyor_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE dashboard.surveyor_respondent OWNER TO meili;

--
-- Name: summary_of_mode2_overall; Type: MATERIALIZED VIEW; Schema: learning_processes; Owner: postgres
--

CREATE MATERIALIZED VIEW learning_processes.summary_of_mode2_overall AS
 SELECT foo.transportation_type2,
    min(foo.transportation_type) AS transportation_type,
    avg(foo.point_avg_speed) AS point_avg_speed,
    avg(foo.point_avg_acc) AS point_avg_acc,
    avg(foo.point_avg_steps) AS point_avg_steps,
    avg(foo.point_avg_dist) AS point_avg_dist,
    avg(foo.travelled_distance) AS travelled_distance,
    avg(foo.duration_of_tripleg) AS duration_of_tripleg,
    avg(foo.speed_overall_of_tripleg) AS speed_overall_of_tripleg,
    ('now'::text)::date AS last_refreshed
   FROM ( SELECT l2.user_id,
            l2.transportation_type2,
            min(l2.transportation_type) AS transportation_type,
            avg(l1.speed_) AS point_avg_speed,
            avg(l1.totalmean) AS point_avg_acc,
            avg((l1.totalnumberofsteps)::numeric) AS point_avg_steps,
            avg(l1.dist_to_prev) AS point_avg_dist,
            count(l1.id) AS period_number_of_points,
            sum(l1.dist_to_prev) AS travelled_distance,
            avg((l2.to_time - l2.from_time)) AS duration_of_tripleg,
                CASE
                    WHEN ((l2.to_time - l2.from_time) <> 0) THEN (((1000)::double precision * sum(l1.dist_to_prev)) / (avg(((l2.to_time - l2.from_time) + 1)))::double precision)
                    ELSE avg(l1.speed_)
                END AS speed_overall_of_tripleg
           FROM apiv2.triplegs_gt l2,
            ( SELECT location_table.id,
                    location_table.user_id,
                    location_table.time_,
                    location_table.speed_,
                    location_table.totalmean,
                    location_table.totalnumberofsteps,
                    public.st_distance((public.st_makepoint(location_table.lon_, location_table.lat_))::public.geography, (public.st_makepoint(lag(location_table.lon_) OVER (PARTITION BY location_table.user_id ORDER BY location_table.time_), lag(location_table.lat_) OVER (PARTITION BY location_table.user_id ORDER BY location_table.time_)))::public.geography) AS dist_to_prev
                   FROM raw_data.location_table
                  WHERE (location_table.accuracy_ <= (50)::double precision)) l1
          WHERE ((l2.type_of_tripleg = 1) AND (l1.user_id = l2.user_id) AND (l1.time_ >= l2.from_time) AND (l1.time_ <= l2.to_time))
          GROUP BY l2.user_id, l2.transportation_type2, l2.from_time, l2.to_time
          ORDER BY l2.user_id, l2.transportation_type2) foo
  GROUP BY foo.transportation_type2
  WITH NO DATA;


ALTER TABLE learning_processes.summary_of_mode2_overall OWNER TO postgres;

--
-- Name: summary_of_mode2_per_user; Type: MATERIALIZED VIEW; Schema: learning_processes; Owner: postgres
--

CREATE MATERIALIZED VIEW learning_processes.summary_of_mode2_per_user AS
 SELECT foo.user_id,
    foo.transportation_type2,
    min(foo.transportation_type) AS transportation_type,
    avg(foo.point_avg_speed) AS point_avg_speed,
    avg(foo.point_avg_acc) AS point_avg_acc,
    avg(foo.point_avg_steps) AS point_avg_steps,
    avg(foo.point_avg_dist) AS point_avg_dist,
    avg(foo.travelled_distance) AS travelled_distance,
    avg(foo.duration_of_tripleg) AS duration_of_tripleg,
    avg(foo.speed_overall_of_tripleg) AS speed_overall_of_tripleg,
    ('now'::text)::date AS last_refreshed
   FROM ( SELECT l2.user_id,
            l2.transportation_type2,
            min(l2.transportation_type) AS transportation_type,
            avg(l1.speed_) AS point_avg_speed,
            avg(l1.totalmean) AS point_avg_acc,
            avg(l1.totalnumberofsteps) AS point_avg_steps,
            avg(l1.dist_to_prev) AS point_avg_dist,
            count(l1.id) AS period_number_of_points,
            sum(l1.dist_to_prev) AS travelled_distance,
            avg((l2.to_time - l2.from_time)) AS duration_of_tripleg,
                CASE
                    WHEN ((l2.to_time - l2.from_time) <> 0) THEN (((1000)::double precision * sum(l1.dist_to_prev)) / (avg(((l2.to_time - l2.from_time) + 1)))::double precision)
                    ELSE avg(l1.speed_)
                END AS speed_overall_of_tripleg
           FROM apiv2.triplegs_gt l2,
            ( SELECT location_table.id,
                    location_table.user_id,
                    location_table.time_,
                    location_table.speed_,
                    location_table.totalmean,
                    location_table.totalnumberofsteps,
                    public.st_distance((public.st_makepoint(location_table.lon_, location_table.lat_))::public.geography, (public.st_makepoint(lag(location_table.lon_) OVER (PARTITION BY location_table.user_id ORDER BY location_table.time_), lag(location_table.lat_) OVER (PARTITION BY location_table.user_id ORDER BY location_table.time_)))::public.geography) AS dist_to_prev
                   FROM raw_data.location_table
                  WHERE (location_table.accuracy_ <= (50)::double precision)) l1
          WHERE ((l2.type_of_tripleg = 1) AND (l1.user_id = l2.user_id) AND (l1.time_ >= l2.from_time) AND (l1.time_ <= l2.to_time))
          GROUP BY l2.user_id, l2.transportation_type2, l2.from_time, l2.to_time
          ORDER BY l2.user_id, l2.transportation_type2) foo
  GROUP BY foo.user_id, foo.transportation_type2
  WITH NO DATA;


ALTER TABLE learning_processes.summary_of_mode2_per_user OWNER TO postgres;

--
-- Name: summary_of_mode_overall; Type: MATERIALIZED VIEW; Schema: learning_processes; Owner: postgres
--

CREATE MATERIALIZED VIEW learning_processes.summary_of_mode_overall AS
 SELECT foo.transportation_type,
    avg(foo.point_avg_speed) AS point_avg_speed,
    avg(foo.point_avg_acc) AS point_avg_acc,
    avg(foo.point_avg_steps) AS point_avg_steps,
    avg(foo.point_avg_dist) AS point_avg_dist,
    avg(foo.travelled_distance) AS travelled_distance,
    avg(foo.duration_of_tripleg) AS duration_of_tripleg,
    avg(foo.speed_overall_of_tripleg) AS speed_overall_of_tripleg,
    ('now'::text)::date AS last_refreshed
   FROM ( SELECT l2.user_id,
            l2.transportation_type,
            avg(l1.speed_) AS point_avg_speed,
            avg(l1.totalmean) AS point_avg_acc,
            avg((l1.totalnumberofsteps)::numeric) AS point_avg_steps,
            avg(l1.dist_to_prev) AS point_avg_dist,
            count(l1.id) AS period_number_of_points,
            sum(l1.dist_to_prev) AS travelled_distance,
            avg((l2.to_time - l2.from_time)) AS duration_of_tripleg,
                CASE
                    WHEN ((l2.to_time - l2.from_time) <> 0) THEN (((1000)::double precision * sum(l1.dist_to_prev)) / (avg(((l2.to_time - l2.from_time) + 1)))::double precision)
                    ELSE avg(l1.speed_)
                END AS speed_overall_of_tripleg
           FROM apiv2.triplegs_gt l2,
            ( SELECT location_table.id,
                    location_table.user_id,
                    location_table.time_,
                    location_table.speed_,
                    location_table.totalmean,
                    location_table.totalnumberofsteps,
                    public.st_distance((public.st_makepoint(location_table.lon_, location_table.lat_))::public.geography, (public.st_makepoint(lag(location_table.lon_) OVER (PARTITION BY location_table.user_id ORDER BY location_table.time_), lag(location_table.lat_) OVER (PARTITION BY location_table.user_id ORDER BY location_table.time_)))::public.geography) AS dist_to_prev
                   FROM raw_data.location_table
                  WHERE (location_table.accuracy_ <= (50)::double precision)) l1
          WHERE ((l2.type_of_tripleg = 1) AND (l1.user_id = l2.user_id) AND (l1.time_ >= l2.from_time) AND (l1.time_ <= l2.to_time))
          GROUP BY l2.user_id, l2.transportation_type, l2.from_time, l2.to_time
          ORDER BY l2.user_id, l2.transportation_type) foo
  GROUP BY foo.transportation_type
  WITH NO DATA;


ALTER TABLE learning_processes.summary_of_mode_overall OWNER TO postgres;

--
-- Name: summary_of_mode_per_user; Type: MATERIALIZED VIEW; Schema: learning_processes; Owner: postgres
--

CREATE MATERIALIZED VIEW learning_processes.summary_of_mode_per_user AS
 SELECT foo.user_id,
    foo.transportation_type,
    avg(foo.point_avg_speed) AS point_avg_speed,
    avg(foo.point_avg_acc) AS point_avg_acc,
    avg(foo.point_avg_steps) AS point_avg_steps,
    avg(foo.point_avg_dist) AS point_avg_dist,
    avg(foo.travelled_distance) AS travelled_distance,
    avg(foo.duration_of_tripleg) AS duration_of_tripleg,
    avg(foo.speed_overall_of_tripleg) AS speed_overall_of_tripleg,
    ('now'::text)::date AS last_refreshed
   FROM ( SELECT l2.user_id,
            l2.transportation_type,
            avg(l1.speed_) AS point_avg_speed,
            avg(l1.totalmean) AS point_avg_acc,
            avg(l1.totalnumberofsteps) AS point_avg_steps,
            avg(l1.dist_to_prev) AS point_avg_dist,
            count(l1.id) AS period_number_of_points,
            sum(l1.dist_to_prev) AS travelled_distance,
            avg((l2.to_time - l2.from_time)) AS duration_of_tripleg,
                CASE
                    WHEN ((l2.to_time - l2.from_time) <> 0) THEN (((1000)::double precision * sum(l1.dist_to_prev)) / (avg(((l2.to_time - l2.from_time) + 1)))::double precision)
                    ELSE avg(l1.speed_)
                END AS speed_overall_of_tripleg
           FROM apiv2.triplegs_gt l2,
            ( SELECT location_table.id,
                    location_table.user_id,
                    location_table.time_,
                    location_table.speed_,
                    location_table.totalmean,
                    location_table.totalnumberofsteps,
                    public.st_distance((public.st_makepoint(location_table.lon_, location_table.lat_))::public.geography, (public.st_makepoint(lag(location_table.lon_) OVER (PARTITION BY location_table.user_id ORDER BY location_table.time_), lag(location_table.lat_) OVER (PARTITION BY location_table.user_id ORDER BY location_table.time_)))::public.geography) AS dist_to_prev
                   FROM raw_data.location_table
                  WHERE (location_table.accuracy_ <= (50)::double precision)) l1
          WHERE ((l2.type_of_tripleg = 1) AND (l1.user_id = l2.user_id) AND (l1.time_ >= l2.from_time) AND (l1.time_ <= l2.to_time))
          GROUP BY l2.user_id, l2.transportation_type, l2.from_time, l2.to_time
          ORDER BY l2.user_id, l2.transportation_type) foo
  GROUP BY foo.user_id, foo.transportation_type
  WITH NO DATA;


ALTER TABLE learning_processes.summary_of_mode_per_user OWNER TO postgres;

--
-- Name: accelerometer_table_id_seq; Type: SEQUENCE; Schema: raw_data; Owner: postgres
--

CREATE SEQUENCE raw_data.accelerometer_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE raw_data.accelerometer_table_id_seq OWNER TO postgres;

--
-- Name: accelerometer_table; Type: TABLE; Schema: raw_data; Owner: postgres
--

CREATE TABLE raw_data.accelerometer_table (
    id integer DEFAULT nextval('raw_data.accelerometer_table_id_seq'::regclass) NOT NULL,
    user_id integer NOT NULL,
    time_ bigint NOT NULL,
    current_x real NOT NULL,
    current_y real NOT NULL,
    current_z real NOT NULL,
    min_x real NOT NULL,
    min_y real NOT NULL,
    min_z real NOT NULL,
    max_x real NOT NULL,
    max_y real NOT NULL,
    max_z real NOT NULL,
    mean_x real NOT NULL,
    mean_y real NOT NULL,
    mean_z real NOT NULL
);


ALTER TABLE raw_data.accelerometer_table OWNER TO postgres;

--
-- Name: location_table_id_seq; Type: SEQUENCE; Schema: raw_data; Owner: postgres
--

CREATE SEQUENCE raw_data.location_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE raw_data.location_table_id_seq OWNER TO postgres;

--
-- Name: location_table_id_seq; Type: SEQUENCE OWNED BY; Schema: raw_data; Owner: postgres
--

ALTER SEQUENCE raw_data.location_table_id_seq OWNED BY raw_data.location_table.id;


--
-- Name: reg_num_list; Type: TABLE; Schema: raw_data; Owner: postgres
--

CREATE TABLE raw_data.reg_num_list (
    reg_num text NOT NULL
);


ALTER TABLE raw_data.reg_num_list OWNER TO postgres;

--
-- Name: user_table; Type: TABLE; Schema: raw_data; Owner: postgres
--

CREATE TABLE raw_data.user_table (
    id integer NOT NULL,
    username public.citext NOT NULL,
    password text NOT NULL,
    phone_model public.citext NOT NULL,
    phone_os text,
    phone_number public.citext,
    reg_no text,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL,
    device_session uuid DEFAULT public.uuid_generate_v4(),
    last_seen timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE raw_data.user_table OWNER TO postgres;

--
-- Name: TABLE user_table; Type: COMMENT; Schema: raw_data; Owner: postgres
--

COMMENT ON TABLE raw_data.user_table IS 'stores the credentials of the user, password is hashed (needs pgcrypto), citext is used for case insensitive storage of email addresses';


--
-- Name: user_table_id_seq; Type: SEQUENCE; Schema: raw_data; Owner: postgres
--

CREATE SEQUENCE raw_data.user_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE raw_data.user_table_id_seq OWNER TO postgres;

--
-- Name: user_table_id_seq; Type: SEQUENCE OWNED BY; Schema: raw_data; Owner: postgres
--

ALTER SEQUENCE raw_data.user_table_id_seq OWNED BY raw_data.user_table.id;


--
-- Name: poi_transportation gid; Type: DEFAULT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.poi_transportation ALTER COLUMN gid SET DEFAULT nextval('apiv2.poi_transportation_gid_seq'::regclass);


--
-- Name: pois gid; Type: DEFAULT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.pois ALTER COLUMN gid SET DEFAULT nextval('apiv2.pois_gid_seq'::regclass);


--
-- Name: triplegs_gt tripleg_id; Type: DEFAULT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.triplegs_gt ALTER COLUMN tripleg_id SET DEFAULT nextval('apiv2.triplegs_gt_tripleg_id_seq'::regclass);


--
-- Name: triplegs_inf tripleg_id; Type: DEFAULT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.triplegs_inf ALTER COLUMN tripleg_id SET DEFAULT nextval('apiv2.triplegs_inf_tripleg_id_seq'::regclass);


--
-- Name: trips_gt trip_id; Type: DEFAULT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.trips_gt ALTER COLUMN trip_id SET DEFAULT nextval('apiv2.trips_gt_trip_id_seq'::regclass);


--
-- Name: trips_inf trip_id; Type: DEFAULT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.trips_inf ALTER COLUMN trip_id SET DEFAULT nextval('apiv2.trips_inf_trip_id_seq'::regclass);


--
-- Name: location_table id; Type: DEFAULT; Schema: raw_data; Owner: postgres
--

ALTER TABLE ONLY raw_data.location_table ALTER COLUMN id SET DEFAULT nextval('raw_data.location_table_id_seq'::regclass);


--
-- Name: user_table id; Type: DEFAULT; Schema: raw_data; Owner: postgres
--

ALTER TABLE ONLY raw_data.user_table ALTER COLUMN id SET DEFAULT nextval('raw_data.user_table_id_seq'::regclass);


--
-- Name: activity_table activity_table_pkey; Type: CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.activity_table
    ADD CONSTRAINT activity_table_pkey PRIMARY KEY (id);


--
-- Name: poi_transportation poi_transportation_pkey; Type: CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.poi_transportation
    ADD CONSTRAINT poi_transportation_pkey PRIMARY KEY (gid);


--
-- Name: pois pois_pkey; Type: CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.pois
    ADD CONSTRAINT pois_pkey PRIMARY KEY (gid);


--
-- Name: purpose_table purpose_table_pkey; Type: CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.purpose_table
    ADD CONSTRAINT purpose_table_pkey PRIMARY KEY (id);


--
-- Name: report_table report_table_pkey; Type: CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.report_table
    ADD CONSTRAINT report_table_pkey PRIMARY KEY (id);


--
-- Name: report_type_table report_type_table_pkey; Type: CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.report_type_table
    ADD CONSTRAINT report_type_table_pkey PRIMARY KEY (id);


--
-- Name: travel_mode2_table travel_mode2_table_pkey; Type: CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.travel_mode2_table
    ADD CONSTRAINT travel_mode2_table_pkey PRIMARY KEY (id);


--
-- Name: travel_mode_table travel_mode_table_pkey; Type: CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.travel_mode_table
    ADD CONSTRAINT travel_mode_table_pkey PRIMARY KEY (id);


--
-- Name: triplegs_inf triplegs_inf_pkey; Type: CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.triplegs_inf
    ADD CONSTRAINT triplegs_inf_pkey PRIMARY KEY (tripleg_id);


--
-- Name: trips_gt trips_gt_pkey; Type: CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.trips_gt
    ADD CONSTRAINT trips_gt_pkey PRIMARY KEY (trip_id);


--
-- Name: trips_gt trips_gt_trip_inf_id_unique; Type: CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.trips_gt
    ADD CONSTRAINT trips_gt_trip_inf_id_unique UNIQUE (trip_inf_id);


--
-- Name: trips_inf_deleted trips_inf_deleted_pkey; Type: CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.trips_inf_deleted
    ADD CONSTRAINT trips_inf_deleted_pkey PRIMARY KEY (trip_inf_id);


--
-- Name: trips_inf trips_inf_pkey; Type: CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.trips_inf
    ADD CONSTRAINT trips_inf_pkey PRIMARY KEY (trip_id);


--
-- Name: surveyor surveyor_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: meili
--

ALTER TABLE ONLY dashboard.surveyor
    ADD CONSTRAINT surveyor_pkey PRIMARY KEY (id);


--
-- Name: surveyor_respondent surveyor_respondent_pkey; Type: CONSTRAINT; Schema: dashboard; Owner: meili
--

ALTER TABLE ONLY dashboard.surveyor_respondent
    ADD CONSTRAINT surveyor_respondent_pkey PRIMARY KEY (id);


--
-- Name: surveyor_respondent surveyor_respondent_user_id_key; Type: CONSTRAINT; Schema: dashboard; Owner: meili
--

ALTER TABLE ONLY dashboard.surveyor_respondent
    ADD CONSTRAINT surveyor_respondent_user_id_key UNIQUE (user_id);


--
-- Name: surveyor surveyor_username_key; Type: CONSTRAINT; Schema: dashboard; Owner: meili
--

ALTER TABLE ONLY dashboard.surveyor
    ADD CONSTRAINT surveyor_username_key UNIQUE (username);


--
-- Name: accelerometer_table accelerometer_table_pkey; Type: CONSTRAINT; Schema: raw_data; Owner: postgres
--

ALTER TABLE ONLY raw_data.accelerometer_table
    ADD CONSTRAINT accelerometer_table_pkey PRIMARY KEY (id);


--
-- Name: location_table location_table_pkey; Type: CONSTRAINT; Schema: raw_data; Owner: postgres
--

ALTER TABLE ONLY raw_data.location_table
    ADD CONSTRAINT location_table_pkey PRIMARY KEY (id);


--
-- Name: location_table location_table_user_id_time__key; Type: CONSTRAINT; Schema: raw_data; Owner: postgres
--

ALTER TABLE ONLY raw_data.location_table
    ADD CONSTRAINT location_table_user_id_time__key UNIQUE (user_id, time_);


--
-- Name: reg_num_list reg_num_list_pkey; Type: CONSTRAINT; Schema: raw_data; Owner: postgres
--

ALTER TABLE ONLY raw_data.reg_num_list
    ADD CONSTRAINT reg_num_list_pkey PRIMARY KEY (reg_num);


--
-- Name: user_table user_table_pkey; Type: CONSTRAINT; Schema: raw_data; Owner: postgres
--

ALTER TABLE ONLY raw_data.user_table
    ADD CONSTRAINT user_table_pkey PRIMARY KEY (id);


--
-- Name: user_table user_table_username_key; Type: CONSTRAINT; Schema: raw_data; Owner: postgres
--

ALTER TABLE ONLY raw_data.user_table
    ADD CONSTRAINT user_table_username_key UNIQUE (username);


--
-- Name: poi_transportation_geometry_index; Type: INDEX; Schema: apiv2; Owner: postgres
--

CREATE INDEX poi_transportation_geometry_index ON apiv2.poi_transportation USING gist (geom);


--
-- Name: pois_geometry_index; Type: INDEX; Schema: apiv2; Owner: postgres
--

CREATE INDEX pois_geometry_index ON apiv2.pois USING gist (geom);


--
-- Name: pois_user_id_index; Type: INDEX; Schema: apiv2; Owner: postgres
--

CREATE INDEX pois_user_id_index ON apiv2.pois USING btree (user_id);


--
-- Name: triplegs_inf_from_time_index; Type: INDEX; Schema: apiv2; Owner: postgres
--

CREATE INDEX triplegs_inf_from_time_index ON apiv2.triplegs_inf USING btree (from_time);


--
-- Name: triplegs_inf_to_time_index; Type: INDEX; Schema: apiv2; Owner: postgres
--

CREATE INDEX triplegs_inf_to_time_index ON apiv2.triplegs_inf USING btree (to_time);


--
-- Name: trips_from_time_index; Type: INDEX; Schema: apiv2; Owner: postgres
--

CREATE INDEX trips_from_time_index ON apiv2.trips_inf USING btree (from_time);


--
-- Name: trips_to_time_index; Type: INDEX; Schema: apiv2; Owner: postgres
--

CREATE INDEX trips_to_time_index ON apiv2.trips_inf USING btree (to_time);


--
-- Name: location_table_time_index; Type: INDEX; Schema: raw_data; Owner: postgres
--

CREATE INDEX location_table_time_index ON raw_data.location_table USING btree (time_);


--
-- Name: trips_gt tg_annotated_trip; Type: TRIGGER; Schema: apiv2; Owner: postgres
--

CREATE TRIGGER tg_annotated_trip AFTER INSERT ON apiv2.trips_gt FOR EACH ROW WHEN ((new.type_of_trip = 1)) EXECUTE PROCEDURE learning_processes.refresh_materialized_views();


--
-- Name: trips_inf trg_deleted_trip; Type: TRIGGER; Schema: apiv2; Owner: postgres
--

CREATE TRIGGER trg_deleted_trip BEFORE DELETE ON apiv2.trips_inf FOR EACH ROW WHEN ((old.type_of_trip = 1)) EXECUTE PROCEDURE apiv2.tg_deleted_trip();


--
-- Name: trips_inf trg_deleted_trip_after; Type: TRIGGER; Schema: apiv2; Owner: postgres
--

CREATE TRIGGER trg_deleted_trip_after AFTER DELETE ON apiv2.trips_inf FOR EACH ROW EXECUTE PROCEDURE apiv2.tg_deleted_trip_after();


--
-- Name: triplegs_inf trg_deleted_tripleg_after; Type: TRIGGER; Schema: apiv2; Owner: postgres
--

CREATE TRIGGER trg_deleted_tripleg_after AFTER DELETE ON apiv2.triplegs_inf FOR EACH ROW WHEN ((old.type_of_tripleg = 1)) EXECUTE PROCEDURE apiv2.tg_deleted_tripleg_after();


--
-- Name: triplegs_inf trg_deleted_tripleg_before; Type: TRIGGER; Schema: apiv2; Owner: postgres
--

CREATE TRIGGER trg_deleted_tripleg_before BEFORE DELETE ON apiv2.triplegs_inf FOR EACH ROW WHEN ((old.type_of_tripleg = 1)) EXECUTE PROCEDURE apiv2.tg_deleted_tripleg_before();


--
-- Name: trips_inf trg_inserted_trip; Type: TRIGGER; Schema: apiv2; Owner: postgres
--

CREATE TRIGGER trg_inserted_trip AFTER INSERT ON apiv2.trips_inf FOR EACH ROW WHEN ((new.type_of_trip = 1)) EXECUTE PROCEDURE apiv2.tg_inserted_trip();


--
-- Name: triplegs_inf trg_inserted_tripleg; Type: TRIGGER; Schema: apiv2; Owner: postgres
--

CREATE TRIGGER trg_inserted_tripleg BEFORE INSERT ON apiv2.triplegs_inf FOR EACH ROW EXECUTE PROCEDURE apiv2.tg_inserted_tripleg();


--
-- Name: trips_inf trg_updated_trip; Type: TRIGGER; Schema: apiv2; Owner: postgres
--

CREATE TRIGGER trg_updated_trip BEFORE UPDATE ON apiv2.trips_inf FOR EACH ROW WHEN ((new.type_of_trip = 1)) EXECUTE PROCEDURE apiv2.tg_updated_trip_before();


--
-- Name: trips_inf trg_updated_trip_after; Type: TRIGGER; Schema: apiv2; Owner: postgres
--

CREATE TRIGGER trg_updated_trip_after AFTER UPDATE ON apiv2.trips_inf FOR EACH ROW EXECUTE PROCEDURE apiv2.tg_updated_trip_after();


--
-- Name: triplegs_inf trg_updated_tripleg; Type: TRIGGER; Schema: apiv2; Owner: postgres
--

CREATE TRIGGER trg_updated_tripleg AFTER UPDATE ON apiv2.triplegs_inf FOR EACH ROW EXECUTE PROCEDURE apiv2.tg_updated_tripleg();


--
-- Name: activities_gt activities_gt_activity_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.activities_gt
    ADD CONSTRAINT activities_gt_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES apiv2.activity_table(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: activities_gt activities_gt_trip_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.activities_gt
    ADD CONSTRAINT activities_gt_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES apiv2.trips_gt(trip_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: activities_inf activities_inf_activity_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.activities_inf
    ADD CONSTRAINT activities_inf_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES apiv2.activity_table(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: activities_inf activities_inf_trip_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.activities_inf
    ADD CONSTRAINT activities_inf_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES apiv2.trips_inf(trip_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: activity_table activity_table_created_by_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.activity_table
    ADD CONSTRAINT activity_table_created_by_fkey FOREIGN KEY (created_by) REFERENCES raw_data.user_table(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: pois pois_user_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.pois
    ADD CONSTRAINT pois_user_id_fkey FOREIGN KEY (user_id) REFERENCES raw_data.user_table(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: tariff_train tariff_train_poi_from_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.tariff_train
    ADD CONSTRAINT tariff_train_poi_from_id_fkey FOREIGN KEY (poi_from_id) REFERENCES apiv2.poi_transportation(gid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tariff_train tariff_train_poi_to_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.tariff_train
    ADD CONSTRAINT tariff_train_poi_to_id_fkey FOREIGN KEY (poi_to_id) REFERENCES apiv2.poi_transportation(gid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: travel_mode2_table travel_mode2_table_transportation_type_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.travel_mode2_table
    ADD CONSTRAINT travel_mode2_table_transportation_type_fkey FOREIGN KEY (transportation_type) REFERENCES apiv2.travel_mode_table(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: triplegs_gt triplegs_gt_transportation_type2_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.triplegs_gt
    ADD CONSTRAINT triplegs_gt_transportation_type2_fkey FOREIGN KEY (transportation_type2) REFERENCES apiv2.travel_mode2_table(id) ON UPDATE CASCADE;


--
-- Name: triplegs_gt triplegs_gt_transportation_type_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.triplegs_gt
    ADD CONSTRAINT triplegs_gt_transportation_type_fkey FOREIGN KEY (transportation_type) REFERENCES apiv2.travel_mode_table(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: triplegs_gt triplegs_gt_trip_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.triplegs_gt
    ADD CONSTRAINT triplegs_gt_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES apiv2.trips_gt(trip_id);


--
-- Name: triplegs_gt triplegs_gt_tripleg_inf_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.triplegs_gt
    ADD CONSTRAINT triplegs_gt_tripleg_inf_id_fkey FOREIGN KEY (tripleg_inf_id) REFERENCES apiv2.triplegs_inf(tripleg_id);


--
-- Name: triplegs_gt triplegs_gt_user_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.triplegs_gt
    ADD CONSTRAINT triplegs_gt_user_id_fkey FOREIGN KEY (user_id) REFERENCES raw_data.user_table(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: triplegs_inf triplegs_inf_transition_poi_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.triplegs_inf
    ADD CONSTRAINT triplegs_inf_transition_poi_id_fkey FOREIGN KEY (transition_poi_id) REFERENCES apiv2.poi_transportation(gid);


--
-- Name: triplegs_inf triplegs_inf_transportation_type2_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.triplegs_inf
    ADD CONSTRAINT triplegs_inf_transportation_type2_fkey FOREIGN KEY (transportation_type2) REFERENCES apiv2.travel_mode2_table(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: triplegs_inf triplegs_inf_transportation_type_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.triplegs_inf
    ADD CONSTRAINT triplegs_inf_transportation_type_fkey FOREIGN KEY (transportation_type) REFERENCES apiv2.travel_mode_table(id);


--
-- Name: triplegs_inf triplegs_inf_trip_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.triplegs_inf
    ADD CONSTRAINT triplegs_inf_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES apiv2.trips_inf(trip_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: triplegs_inf triplegs_inf_user_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.triplegs_inf
    ADD CONSTRAINT triplegs_inf_user_id_fkey FOREIGN KEY (user_id) REFERENCES raw_data.user_table(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trips_gt trips_gt_destination_poi_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.trips_gt
    ADD CONSTRAINT trips_gt_destination_poi_id_fkey FOREIGN KEY (destination_poi_id) REFERENCES apiv2.pois(gid) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trips_gt trips_gt_trip_inf_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.trips_gt
    ADD CONSTRAINT trips_gt_trip_inf_id_fkey FOREIGN KEY (trip_inf_id) REFERENCES apiv2.trips_inf(trip_id);


--
-- Name: trips_gt trips_gt_user_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.trips_gt
    ADD CONSTRAINT trips_gt_user_id_fkey FOREIGN KEY (user_id) REFERENCES raw_data.user_table(id);


--
-- Name: trips_inf_deleted trips_inf_deleted_trip_inf_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.trips_inf_deleted
    ADD CONSTRAINT trips_inf_deleted_trip_inf_id_fkey FOREIGN KEY (trip_inf_id) REFERENCES apiv2.trips_inf(trip_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: trips_inf trips_inf_destination_poi_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.trips_inf
    ADD CONSTRAINT trips_inf_destination_poi_id_fkey FOREIGN KEY (destination_poi_id) REFERENCES apiv2.pois(gid);


--
-- Name: trips_inf trips_inf_purpose_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.trips_inf
    ADD CONSTRAINT trips_inf_purpose_id_fkey FOREIGN KEY (purpose_id) REFERENCES apiv2.purpose_table(id);


--
-- Name: trips_inf trips_inf_user_id_fkey; Type: FK CONSTRAINT; Schema: apiv2; Owner: postgres
--

ALTER TABLE ONLY apiv2.trips_inf
    ADD CONSTRAINT trips_inf_user_id_fkey FOREIGN KEY (user_id) REFERENCES raw_data.user_table(id);


--
-- Name: surveyor_respondent surveyor_respondent_surveyor_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: meili
--

ALTER TABLE ONLY dashboard.surveyor_respondent
    ADD CONSTRAINT surveyor_respondent_surveyor_id_fkey FOREIGN KEY (surveyor_id) REFERENCES dashboard.surveyor(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: surveyor_respondent surveyor_respondent_user_id_fkey; Type: FK CONSTRAINT; Schema: dashboard; Owner: meili
--

ALTER TABLE ONLY dashboard.surveyor_respondent
    ADD CONSTRAINT surveyor_respondent_user_id_fkey FOREIGN KEY (user_id) REFERENCES raw_data.user_table(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: accelerometer_table accelerometer_table_user_id_fkey; Type: FK CONSTRAINT; Schema: raw_data; Owner: postgres
--

ALTER TABLE ONLY raw_data.accelerometer_table
    ADD CONSTRAINT accelerometer_table_user_id_fkey FOREIGN KEY (user_id) REFERENCES raw_data.user_table(id) ON UPDATE CASCADE;


--
-- PostgreSQL database dump complete
--

