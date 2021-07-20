import haxe.Int64;
import haxe.Http;
import tink.url.Query;

using tink.CoreApi;
	
inline var NODEURL = "http://xymharvesting.net:3000";
inline var ADDRESS = "NBMWZZZOCUKZXXHKB7R3P3G2ZCO4CSGIXC37USI";
inline var XYM_MOSAIC_ID = "6BED913FA20223F8";
inline var ENUM_HARVEST_FEE = 8515;

function main() {
	
	final addressUrl = NODEURL + "/accounts/" + ADDRESS;
	final address = requestURL( addressUrl );
	
	address.handle( o ->{
		switch o {
			case Success( addressData ):
				final accountData:Account = try haxe.Json.parse( addressData )
				catch( e ) throw 'Invalid json: $addressData';
				final address48 = accountData.account.address;
				// trace( addressData );
				trace( 'address48 $address48' );
				getStatements( address48 );
			
			case Failure( failure ): trace( 'error: $failure' );
		
		}
	});
}

function getStatements( address48:String, pageNumber = 1 ) {
	trace( 'GetStatements Page $pageNumber' );

	final q = new QueryStringBuilder()
	.add( "targetAddress", ADDRESS )
	.add( "order", "desc" );
	if( pageNumber != 1 ) q.add( "pageNumber", Std.string( pageNumber ));
	
	final statementsUrl = NODEURL + "/statements/transaction?" + q.toString();
	final statements = requestURL( statementsUrl );
	
	statements.handle( o -> {
		switch o {
			case Success( data ):
				final statementsData:Statement = try haxe.Json.parse( data )
				catch( e ) throw 'Invalid json: $data';
				// trace( data );

				for( d in statementsData.data ) {
					final height = d.statement.height;
					for( receipt in d.statement.receipts ) {
						// if( receipt.type == ENUM_HARVEST_FEE ) trace( 'targetAddress ${receipt.targetAddress}  ${receipt.targetAddress == address48}' );
						if( receipt.type == ENUM_HARVEST_FEE && receipt.targetAddress == address48 ) {
							final amount = Int64.parseString( receipt.amount );
							trace( 'height: $height, amount: $amount' );
						}
					}
				}
				if( statementsData.data.length > 0 ) getStatements( address48, pageNumber + 1 );

			case Failure( failure ): trace( 'Error: $failure' );
		}
	});
}
	

function processResponses( responses:Array<String> ) {
	
	final accountData:Account = try haxe.Json.parse( responses[0] )
	catch( e ) throw 'Invalid json: ${responses[0]}';

	final statementData:Statement = try haxe.Json.parse( responses[1] )
	catch( e ) throw 'Invalid json: ${responses[1]}';

	final address48 = accountData.account.address;
	trace( 'address48 $address48' );
	for( d in statementData.data ) {
		final height = d.statement.height;
		for( receipt in d.statement.receipts ) {
			trace( 'receipt type ${receipt.type}  targetAddress ${receipt.targetAddress}  ${receipt.targetAddress == address48}' );
			if( receipt.type == ENUM_HARVEST_FEE && receipt.targetAddress == address48 ) {
				final amount = Int64.parseString( receipt.amount );
				trace( 'height: $height, amount: $amount' );
			}
		}
	}
}

function requestURL( url:String ):Promise<String> {

	final httpRequest = new Http( url );
	final promiseTrigger = Promise.trigger();

	httpRequest.onData = function( data ) promiseTrigger.trigger( Success( data ));
	httpRequest.onError = function( error ) promiseTrigger.trigger( Failure( new Error( error )));
	httpRequest.request();
	
	return promiseTrigger;
}



typedef Account = {
	final id:String;
	final account:{
		final version:Int;
		final address:String;
		final addressHeight:String;
		final publicKey:String;
		final publicKeyHeight:String;
		final accountType:Int;
		final supplementalPublicKeys:{
			final linked:{ final publicKey:String; }
			final node:{ final publicKey:String; }
			final vrf:{ final publicKey:String; }
			final voting:{
				final publicKeys:Array<{
					final publicKey:String;
					final startEpoch:String;
					final endEpoch:String;
				}>;
			}
		}
		final activityBuckets:Array<{
			final startHeight:String;
			final totalFeesPaid:String;
			final beneficiaryCount:String;
			final rawScore:String;
		}>;
		final mosaics:Array<Mosaic>;
		final importance:String;
		final importanceHeight:String;
	}
}

typedef Mosaic = {
	final id:String;
	final amount:String;
}

typedef Statement = {
	final data:Array<{
		final id:String;
		final statement:{
			final height:String;
			final source:{
				final primaryId:Int;
				final secondaryId:Int;
			};
			final receipts:Array<{
				final version:Int;
				final type:Int;
				final targetAddress:String;
				final mosaicId:String;
				final amount:String;
			}>;

		}
	}>;
}
