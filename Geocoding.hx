import neko.Lib;
import sys.db.Sqlite;
import sys.io.File;
import yahoo.PlaceFinder;

/**
 * Geocoding
 * 2012 Jonas Malaco Filho
 */

class Geocoding {
	
	inline static var yahooAPIid = '';  // TODO read from somewhere

	static function main() {
		var ypf = new PlaceFinder( yahooAPIid );
		var locale = 'pt_BR';
		var output = Default;
		var args = Lambda.list( Sys.args() );
		while ( !args.isEmpty() ) {
			var a = args.pop();
			switch ( a ) {
				case '--address' : ypf.setLocationAddressParameter( args.pop() );
				case '--reverse' : ypf.setLocationCoordinatesParameter( Std.parseFloat( args.pop() ), Std.parseFloat( args.pop() ) );
				case '--name' : ypf.setNameParameter( args.pop() );
				case '--house' : ypf.setHouseParameter( Std.parseInt( args.pop() ) );
				case '--street' : ypf.setStreetParameter( args.pop() );
				case '--xstreet' : ypf.setXStreetParameter( args.pop() );
				case '--postal' : ypf.setPostalParameter( args.pop() );
				case '--neighborhood' : ypf.setNeighborhoodParameter( args.pop() );
				case '--city' : ypf.setCityParameter( args.pop() );
				case '--county' : ypf.setCountyParameter( args.pop() );
				case '--state' : ypf.setStateParameter( args.pop() );
				case '--country' : ypf.setCountryParameter( args.pop() );
				case '--locale' : locale = args.pop();
				case '--csv' : output = Csv( args.pop() );
				case '--sqlite3' :
					var path = args.pop();
					var table = args.pop();
					var label = args.pop();
					if ( label.charAt( 0 ) == '-' ) {
						args.push( label ); 
						label = '';
					}
					output = Sqlite3( path, table, label );
				case '--appid' : ypf.setApplicationId( args.pop() );
			}
		}
		ypf.request( locale );
		if ( ypf.response.Error == 0 )
			switch ( output ) {
				case Default : 
					Lib.println( ypf.getCsv( '\t' ) );
				case Csv( path ) :
					var f = File.write( path, false );
					f.writeString( ypf.getCsv( ',' ) );
					f.close();
				case Sqlite3( path, table, label ) :
					var sqlite = Sqlite.open( path );
					var stms = ypf.getSql( sqlite, table, label );
					sqlite.request( stms.create );
					sqlite.request( stms.insert );
					sqlite.close();
			}
		else
			Lib.println( Std.format( 'ERROR: ${ypf.response.ErrorMessage}' ) );
	}
	
}

private enum Output {
	Csv( path : String );
	Sqlite3( path : String, table : String, label : String );
	Default;
}
