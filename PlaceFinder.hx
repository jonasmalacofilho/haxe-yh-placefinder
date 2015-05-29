package yahoo;

import haxe.Http;
import haxe.Json;
import haxe.Utf8;
import sys.db.Connection;

/**
 * Yahoo Place Finder API Wrapper
 * http://developer.yahoo.com/geo/placefinder/
 * 2012 Jonas Malaco Filho
 */

class PlaceFinder {

	static var baseURI = 'where.yahooapis.com/geocode';
	static var controlStart = 0;
	static var controlCount = 100;
	static var controlOffset = 5;
	// JSON, aiport code, telephone area code, timezone info and bounding box
	static var controlFlags = 'JQRTX';
	// neighborhoods and cross streets
	static var controlBaseGFlags = 'AC'; // 
	static var controlGFlagsReverseGeocoding = 'R';
	
	public var cnx( default, null ) : Http;
	public var reverse( default, null ) : Bool;
	public var response( default, null ) : Dynamic;
	public var requestDate( default, null ) : Date;
	
	public function new( appID : String ) {
		cnx = new Http( baseURI );
		cnx.setParameter( 'appid', appID );
		reverse = false;
		response = cast { };
	}
	
	function encode( v : Dynamic ) : String {
		var s = Std.string( v );
		if ( Utf8.validate( s ) )
			return s;
		else
			return Utf8.encode( s );
	}
	
	// Free-Form Format
	// A geographical location/address.
	public function setLocationAddressParameter( freeFormat : String ) {
		cnx.setParameter( 'q', encode( freeFormat ) );
	}
	
	// Free-Form Format
	// Lat/lon in decimal degrees
	public function setLocationCoordinatesParameter( lat : Float, lon : Float ) {
		cnx.setParameter( 'q', encode( lat ) + ' ' + encode( lon ) );
		reverse = true;
	}
	
	// N/A
	// A Place of Interest (POI) name, Area of Interest (AOI) name,
	// or airport code. See also POI and AOI Names.
	// Ignored if location parameter is provided.
	public function setNameParameter( name : String ) {
		cnx.setParameter( 'name', encode( name ) );
	}
	
	// Fully-parsed Format
	// House number. Ignored if location, name, woeid,
	// or multi-line (line1/line2/line3) parameter is provided.
	public function setHouseParameter( house : Int ) {
		cnx.setParameter( 'house', encode( house ) );
	}
	
	// Fully-parsed Format
	// Street name. Ignored if location, name, woeid,
	// or multi-line (line1/line2/line3) parameter is provided.
	public function setStreetParameter( street : String ) {
		cnx.setParameter( 'street', encode( street ) );
	}
	
	// Fully-parsed Format
	// Cross Street name. Ignored if location, name, woeid,
	// or multi-line (line1/line2/line3) parameter is provided.
	public function setXStreetParameter( xStreet : String ) {
		cnx.setParameter( 'xstreet', encode( xStreet ) );
	}
	
	// Fully-parsed Format
	// Postal code. Ignored if location, name, woeid,
	// or multi-line (line1/line2/line3) parameter is provided.
	public function setPostalParameter( postal : String ) {
		cnx.setParameter( 'postal', encode( postal ) );
	}
	
	// Fully-parsed Format
	// Level 4 Administrative name (Neighborhood).
	// Ignored if location, name, woeid, or multi-line (line1/line2/line3)
	// parameter is provided.
	public function setNeighborhoodParameter( neighborhood : String ) {
		cnx.setParameter( 'neighborhood', encode( neighborhood ) );
	}
	
	// Fully-parsed Format
	// Level 3 Administrative name (City/Town/Locality).
	// Ignored if location, name, woeid, or multi-line (line1/line2/line3)
	// parameter is provided. Do not specify level3 unless level1 or level0
	// is also specified; otherwise, erroneous results might be returned.
	// For best results, specify at least level0 through level3.
	public function setCityParameter( city : String ) {
		cnx.setParameter( 'city', encode( city ) );
	}
	
	// Fully-parsed Format
	// Level 2 Administrative name (County). Ignored if location, name, woeid,
	// or multi-line (line1/line2/line3) parameter is provided.
	public function setCountyParameter( county : String ) {
		cnx.setParameter( 'county', encode( county ) );
	}
	
	// Fully-parsed Format
	// Level 1 Administrative name (State/Province) or abbreviation (US only).
	// Ignored if location, name, woeid, or multi-line (line1/line2/line3)
	// parameter is provided.
	public function setStateParameter( state : String ) {
		cnx.setParameter( 'state', encode( state ) );
	}
	
	// Fully-parsed Format
	// Level 0 Administrative name (Country) or country code. Ignored
	// if location, name, woeid, or multi-line (line1/line2/line3)
	// parameter is provided.
	public function setCountryParameter( country : String ) {
		cnx.setParameter( 'country', encode( country ) );
	}
	
	public function setApplicationId( id : String ) {
		cnx.setParameter( 'appid', id );
	}
	
	// The language and country. A two-letter ISO-639 major language
	// code and a two-letter ISO-3166-1 alpha-2 country code,
	// separated by either a hyphen or underscore. Default is en_US (English/US).
	public function request( ?locale = 'en_US' ) {
		cnx.setParameter( 'locale', locale );
		cnx.setParameter( 'start', encode( controlStart ) );
		cnx.setParameter( 'count', encode( controlCount ) );
		cnx.setParameter( 'offset', encode( controlOffset ) );
		cnx.setParameter( 'flags', encode( controlFlags ) );
		cnx.setParameter( 'gflags', encode( reverse ? controlBaseGFlags + controlGFlagsReverseGeocoding : controlBaseGFlags ) );
		cnx.onError = function( msg ) { trace( Std.format( 'ERROR: $msg' ) ); };
		cnx.onData = function( data ) { response = Json.parse( data ).ResultSet; };
		requestDate = Date.now();
		cnx.request( false );
	}
	
	function csv( v : Dynamic, separator ) : String {
		var s = Std.string( v );
		if ( Utf8.validate( s ) )
			s = Utf8.decode( s );
		if ( !( new EReg( Std.format( '["${separator}]' ), '' ) ).match( s ) )
			return s;
		else
			return '"' + s.split( '"' ).join( '""' ) + '"';
	}
	
	public function getCsv( separator : String ) : String {
		if ( response == null )
			return Std.format( 'ERROR: NO REQUEST' );
		else if ( response.Error != 0 )
			return Std.format( 'ERROR: ${response.ErrorMessage}' );
		var fields = [ 'quality', 'latitude', 'longitude', 'offsetlat', 'offsetlon', 'radius', 'name', 'line1', 'line2', 'line3', 'line4', 'cross', 'house', 'street', 'xstreet', 'unittype', 'unit', 'postal', 'neighborhood', 'city', 'county', 'state', 'country', 'level4', 'level3', 'level2', 'level1', 'level0', 'countycode', 'level2code', 'level1code', 'level0code', 'timezone', 'areacode', 'uzip', 'hash', 'woeid', 'woetype' ];
		var b = new StringBuf();
		for ( f in fields ) {
			b.add( csv( f, separator ) );
			b.add( separator );
		}
		b.add( '\n' );
		if ( response.Found >= 1 )
			for ( r in cast( response.Results, Array<Dynamic> ) ) {
				for ( f in fields ) {
					b.add( csv( Reflect.field( r, f ), separator ) );
					b.add( separator );
				}
				b.add( '\n' );
			}
		return b.toString();
	}
	
	static var sqlFields = [ 'label', 'requestDate', 'httpJson', 'responseJson', 'quality', 'latitude', 'longitude', 'offsetlat', 'offsetlon', 'radius', 'name', 'line1', 'line2', 'line3', 'line4', 'cross', 'house', 'street', 'xstreet', 'unittype', 'unit', 'postal', 'neighborhood', 'city', 'county', 'state', 'country', 'level4', 'level3', 'level2', 'level1', 'level0', 'countycode', 'level2code', 'level1code', 'level0code', 'timezone', 'areacode', 'uzip', 'hash', 'woeid', 'woetype' ];
	
	public function getSql( db : Connection, tableName : String, label : String ) : { create : String, insert : String } {
		
		if ( response == null )
			throw Std.format( 'ERROR: NO REQUEST' );
		else if ( response.Error != 0 )
			throw Std.format( 'ERROR: ${response.ErrorMessage}' );
		
		var stms = { create : '', insert : '' };
		var b = new StringBuf();
		b.add( Std.format( 'CREATE TABLE IF NOT EXISTS $tableName ( ' ) );
		for ( f in sqlFields ) {
			b.add( f );
			b.add( ',' );
		}
		b.add( Std.format( ' PRIMARY KEY ( ${sqlFields[0]}, ${sqlFields[1]} ) )' ) );
		stms.create = b.toString();
		b = new StringBuf();
		b.add( Std.format( 'INSERT INTO $tableName ( ' ) );
		b.add( sqlFields.join( ',' ) );
		b.add( ' ) VALUES' );
		if ( response.Found >= 1 ) {
			var cnt = 0;
			for ( r in cast( response.Results, Array<Dynamic> ) ) {
				if ( cnt++ > 0 )
					b.add( ', (' );
				else
					b.add( ' (' );
				db.addValue( b, label );
				b.add( ',' );
				db.addValue( b, requestDate );
				b.add( ',' );
				db.addValue( b, Json.stringify( cnx ) );
				b.add( ',' );
				db.addValue( b, Json.stringify( response ) );
				for ( f in sqlFields.slice( 4 ) ) {
					b.add( ',' );
					db.addValue( b, Reflect.field( r, f ) );
				}
				b.add( ')' );
			}
		}
		stms.insert = b.toString();
		return stms;
	}
	
}