import haxe.Int64;
import haxe.Http;
import tink.url.Query;

using tink.CoreApi;
	
inline var NODEURL = "http://xymharvesting.net:3000";
inline var ADDRESS = "NBMWZZZOCUKZXXHKB7R3P3G2ZCO4CSGIXC37USI";
inline var XYM_MOSAIC_ID = "6BED913FA20223F8";
inline var ENUM_HARVEST_FEE = 8515;
inline var NEMESIS_BLOCK_TIMESTAMP = "2021-03-16 00:06:25";

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
				trace( 'address $ADDRESS  address48 $address48' );
				final heightAmounts = getStatements( address48 );
				final blocks = Promise.inSequence( heightAmounts.map( heightAmount -> getBlock( heightAmount.height )));
				
				blocks.handle( o -> switch o {
					case Success( blocksResponses ): processBlocks( heightAmounts, blocksResponses );
					case Failure( failure ): trace( 'error: $failure' );
				});
						
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
	
	final heightAmounts = [];
	statements.handle( o -> {
		switch o {
			case Success( data ):
				final statementsData:Statement = try haxe.Json.parse( data )
				catch( e ) throw 'Invalid json: $data';
				// trace( data );

				for( d in statementsData.data ) {
					for( receipt in d.statement.receipts ) {
						// if( receipt.type == ENUM_HARVEST_FEE ) trace( 'targetAddress ${receipt.targetAddress}  ${receipt.targetAddress == address48}' );
						if( receipt.type == ENUM_HARVEST_FEE && receipt.targetAddress == address48 ) {
							final height = Int64.parseString( d.statement.height );
							final amount = Int64.parseString( receipt.amount );
							final heightAmount:HeightAmount = { height: height, amount: amount };
							trace( 'height: $height, amount: $amount' );
							heightAmounts.push( heightAmount );
						}
					}
				}
				if( statementsData.data.length > 0 ) getStatements( address48, pageNumber + 1 );

			case Failure( failure ): trace( 'Error: $failure' );
		}
	});

	return heightAmounts;
}

function processBlocks( heightAmounts:Array<HeightAmount>, blocksResponses:Array<String> ) {
	trace( 'ProcessBlocks' );
	for( i in 0...blocksResponses.length ) {
		final blockData:Block = try haxe.Json.parse( blocksResponses[i] )
		catch( e ) throw 'Invalid json: ${blocksResponses[i]}';
	
		final timestamp = Std.parseFloat( blockData.block.timestamp );
		final nbTimestamp = Date.fromString( NEMESIS_BLOCK_TIMESTAMP ).getTime() + timestamp;
		final date = Date.fromTime( nbTimestamp );
		trace( 'block ${heightAmounts[i].height}  date ${date}  amount ${heightAmounts[i].amount}' );
	}
}

function getBlock( height:Int64 ) {
	final blockUrl = NODEURL + "/blocks/" + height;
	final block = requestURL( blockUrl );
	return block;
}

function requestURL( url:String ):Promise<String> {
	final httpRequest = new Http( url );
	final promiseTrigger = Promise.trigger();

	httpRequest.onData = function( data ) promiseTrigger.trigger( Success( data ));
	httpRequest.onError = function( error ) promiseTrigger.trigger( Failure( new Error( error )));
	httpRequest.request();
	
	return promiseTrigger;
}

typedef HeightAmount = {
	final height:Int64;
	final amount:Int64;
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
