import haxe.Int64;
import haxe.Http;
import tink.url.Query;

using tink.CoreApi;
	
inline var NODEURL = "http://xymharvesting.net:3000";
inline var ADDRESS = "NDLS6GYOIPHATATNAVVOUNJXBD6X4BXU6IRBHIY";
inline var XYM_MOSAIC_ID = "6BED913FA20223F8";

function main() {
	final addressUrl = NODEURL + "/accounts/" + ADDRESS;
	final address = requestURL( addressUrl );
	
	address.handle( o -> {
		switch o {
			case Success( addressData ):
				final accountData:Account = try haxe.Json.parse( addressData )
				catch( e ) throw 'Invalid json: $addressData';
				final address48 = accountData.account.address;
				getTransactions( address48 );

			case Failure( failure ): trace( 'Error: $failure' );
		}
	});
}

function getTransactions( address48:String, pageNumber = 1 ) {
	trace( 'GetTransactions Page $pageNumber' );

	final q = new QueryStringBuilder()
	.add( "address", ADDRESS )
	.add( "order", "desc" );
	if( pageNumber != 1 ) q.add( "pageNumber", Std.string( pageNumber ));
	
	final transactionsUrl = NODEURL + "/transactions/confirmed?" + q.toString();
	final transactions = requestURL( transactionsUrl );
	
	transactions.handle( o -> {
		switch o {
			case Success( data ):
				final transactionsData:Transaction = try haxe.Json.parse( data )
				catch( e ) throw 'Invalid json: $data';
				for( d in transactionsData.data ) {
					if( d.transaction.mosaics != null ) {
						final xymAmount = getXYMAmount( d.transaction.mosaics );
						final isRecipient = d.transaction.recipientAddress == address48;
						trace( 'Height: ${d.meta.height} - ${isRecipient ? "Received" : "Sent" }: $xymAmount' );
					}
				}
				if( transactionsData.data.length > 0 ) getTransactions( address48, pageNumber + 1 );

			case Failure( failure ): trace( 'Error: $failure' );
		}
	});

}

function getXYMAmount( mosaics:Array<Mosaic> ) {
	for( m in mosaics ) if( m.id == XYM_MOSAIC_ID ) return Int64.parseString( m.amount );
	return 0;
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

typedef Transaction = {
	final data:Array<{
		final id:String;
		final meta:{
			final height:String;
			final hash:String;
			final merkleComponentHash:String;
			final index:Int;
		}
		final transaction:{
			final size:Int;
			final signature:String;
			final signerPublicKey:String;
			final version:Int;
			final network:Int;
			final type:Int;
			final maxFee:String;
			final deadline:String;
			final ?recipientAddress:String;
			final ?message:String;
			final ?mosaics:Array<Mosaic>;
			final ?transactionsHash:String;
			final ?cosignatures:Array<String>;
		}
	}>;
	final pagination:{
		final pageNumber:Int;
		final pageSize:Int;
	}
}

typedef Mosaic = {
	final id:String;
	final amount:String;
}