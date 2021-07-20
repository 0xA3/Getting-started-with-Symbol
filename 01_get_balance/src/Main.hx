import haxe.Int64;
import haxe.Http;

using tink.CoreApi;
	
inline var NODEURL = "http://xymharvesting.net:3000";
inline var ADDRESS = "NDLS6GYOIPHATATNAVVOUNJXBD6X4BXU6IRBHIY";

function main() {
	
	final result = requestURL( NODEURL + "/accounts/" + ADDRESS );

	result.handle( o -> {
		switch o {
			case Success( data ):
				final accountData:Account = haxe.Json.parse( data );
				final balance = Int64.parseString( accountData.account.mosaics[0].amount );
				trace( 'balance $balance' );
			case Failure( error ): trace( 'error: $error' );
		}
	});
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
		final mosaics:Array<{
			final id:String;
			final amount:String;
		}>;
		final importance:String;
		final importanceHeight:String;
	}
}