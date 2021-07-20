import haxe.Http;

using tink.CoreApi;
	
inline var NODEURL = "http://xymharvesting.net:3000";
inline var ADDRESS = "NANZVLZJTVXAK2772CAETNCFXL7FRVTJNGYAH4Q";
inline var NEMESIS_BLOCK_TIMESTAMP = "2021-03-16 00:06:25";

function main() {
	
	final height = 361534;

	final blockUrl = NODEURL + "/blocks/" + height;
	final block = requestURL( blockUrl );
	
	block.handle( o ->{
		switch o {
			case Success( data ):
				final blockData:Block = try haxe.Json.parse( data )
				catch( e ) throw 'Invalid json: $data';

				final timestamp = Std.parseFloat( blockData.block.timestamp );
				final nbTimestamp = Date.fromString( NEMESIS_BLOCK_TIMESTAMP ).getTime() + timestamp;
				final date = Date.fromTime( nbTimestamp );
				trace( date );
			
			case Failure( failure ): trace( 'error: $failure' );
		
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

typedef Block = {
	final id:String;
	final meta:{
		final hash:String;
		final generationHash:String;
		final totalFee:String;
		final totalTransactionsCount:Int;
		final stateHashSubCacheMerkleRoots:Array<String>;
		final transactionsCount:Int;
		final statementsCount:Int;
	};
	final block:{
		final size:Int;
		final signature:String;
		final signerPublicKey:String;
		final version:Int;
		final network:Int;
		final type:Int;
		final height:String;
		final timestamp:String;
		final difficulty:String;
		final proofGamma:String;
		final proofVerificationHash:String;
		final proofScalar:String;
		final previousBlockHash:String;
		final transactionsHash:String;
		final receiptsHash:String;
		final stateHash:String;
		final beneficiaryAddress:String;
		final feeMultiplier:Int;
	}
}