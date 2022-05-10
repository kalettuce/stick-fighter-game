package cse481d.logging;
#if flash
import flash.net.SharedObject;
#end
import haxe.Http;
import haxe.Json;
import haxe.Timer;
import haxe.crypto.Md5;
#if js
import js.Browser;
import js.html.Storage;
#end

/**
 * ...
 * @author 
 */
class CapstoneLogger 
{
	static var devUrl:String = "http://dev.ws.centerforgamescience.com/cgs/apps/games/v2/index.php/";
	static var prdUrl:String = "https://integration.centerforgamescience.org/cgs/apps/games/v2/index.php/";
	
	/*
	 * Properties specific to each game
	 */
	private var gameId:Int;
	private var gameName:String;
	private var gameKey:String;
	private var categoryId:Int;
	// Need to keep this at one (another table entry defines the valid version number)
	// To keep things simple, only modify the categoryId to filter data
	private var versionNumber:Int;
	private var useDev:Bool;
	
	/*
	 * Logging state
	 */
	private var currentUserId:String;
	private var currentSessionId:String;
	private var currentDqid:String;
	private var currentLevelId:Int;
	
	private var currentLevelSeqInSession:Int;
	private var currentActionSeqInSession:Int;
	private var currentActionSeqInLevel:Int;
	
	private var timestampOfPrevLevelStart:Float;
	
	private var levelActionBuffer:Array<Dynamic>;
	private var levelActionTimer:Timer;
	
	private var bufferedRequestsWaitingForSession:Array<Http>;
	
	public function new(gameId:Int, gameName:String, gameKey:String, categoryId:Int, useDev:Bool = true) 
	{
		this.gameId = gameId;
		this.gameName = gameName;
		this.gameKey = gameKey;
		this.categoryId = categoryId;
		this.versionNumber = 1;
		this.useDev = useDev;
		
		this.levelActionBuffer = new Array<Dynamic>();
	}
	
	// Generate a guid for a user, use this to track their actions
	public function generateUuid():String
	{
		var uuid:String = "";
		for (characterIndex in 0...32)
		{
			if (characterIndex == 8 || characterIndex == 12 || characterIndex == 16 || characterIndex == 20)
			{
				uuid += "-";
			}
			
			uuid += StringTools.hex(Math.floor(Math.random() * 16));
		}
		
		return uuid;
	}
	
	public function getSavedUserId():String
	{
		var savedUserId:String = null;
		#if js
			savedUserId = Browser.window.localStorage.getItem("saved_userid");
		#elseif flash
			var sharedObject:SharedObject = SharedObject.getLocal("capstone");
			savedUserId = sharedObject.data.saved_userid;
		#end
		
		return savedUserId;
	}
	
	public function setSavedUserId(value:String):Void
	{
		#if js
			Browser.window.localStorage.setItem("saved_userid", value);
		#elseif flash
			var sharedObject:SharedObject = SharedObject.getLocal("capstone");
			sharedObject.setProperty("saved_userid", value);
		#end
	}
	
	public function startNewSession(userId:String, callback:Bool->Void):Void
	{
		this.currentUserId = userId;
		this.currentLevelSeqInSession = 0;
		this.currentActionSeqInSession = 0;
		
		var sessionRequest:Http = new Http(this.composeUrl("loggingpageload/set/"));
		var sessionParams:Dynamic = {
			eid: 0,
			cid: this.categoryId,
			pl_detail: {},
			client_ts: Date.now().getTime(),
			uid: this.currentUserId,
			g_name: this.gameName,
			gid: this.gameId,
			svid: 2,
			vid: this.versionNumber
		};
		this.addParamsToRequest(sessionRequest, sessionParams);
		sessionRequest.onData = function(data:String):Void
		{
			// Part of the response data should be the session id
			var sessionSuccess:Bool = false;
			if (data != null)
			{
				data = data.substr(5);
				var parsedResults:Dynamic = Json.parse(data);
				if (parsedResults.tstatus == 't')
				{
					this.currentSessionId = parsedResults.r_data.sessionid;
					sessionSuccess = true;
				}
			}
			
			if (callback != null)
			{
				callback(sessionSuccess);
			}
		};
		
		sessionRequest.onError = function(message:String):Void
		{
			callback(false);
		};
		sessionRequest.request(true);
	}
	
	public function logLevelStart(levelId:Int, ?details:Dynamic):Void
	{
		this.flushBufferedLevelActions();
		if (this.levelActionTimer != null)
		{
			this.levelActionTimer.stop();
		}
		this.levelActionTimer = new Timer(3000);
		this.levelActionTimer.run = flushBufferedLevelActions;
		
		this.timestampOfPrevLevelStart = Date.now().getTime();
		this.currentActionSeqInLevel = 0;
		this.currentLevelId = levelId;
		this.currentDqid = null;
		
		var levelStartRequest:Http = new Http(this.composeUrl("quest/start/"));
		
		var startData:Dynamic = this.getCommonData();
		startData.sessionid = this.currentSessionId;
		startData.sid = this.currentSessionId;
		startData.quest_seqid = ++this.currentLevelSeqInSession;
		startData.qaction_seqid = ++this.currentActionSeqInLevel;
		startData.q_detail = details;
		startData.q_s_id = 1;
		startData.session_seqid = ++this.currentActionSeqInSession;
		
		this.addParamsToRequest(levelStartRequest, startData);
		levelStartRequest.onData = function(data:String):Void
		{
			if (data != null)
			{
				data = data.substr(5);
				this.currentDqid = Json.parse(data).dqid;
			}
		};
		
		levelStartRequest.request(true);
	}
	
	public function logLevelEnd(?details:Dynamic):Void
	{
		this.flushBufferedLevelActions();
		if (this.levelActionTimer != null)
		{
			this.levelActionTimer.stop();
		}
		
		var levelEndRequest:Http = new Http(this.composeUrl("quest/end"));
		
		var endData:Dynamic = this.getCommonData();
		endData.sessionid = this.currentSessionId;
		endData.sid = this.currentSessionId;
		endData.qaction_seqid = ++this.currentActionSeqInLevel;
		endData.q_detail = details;
		endData.q_s_id = 0;
		endData.dqid = this.currentDqid;
		endData.session_seqid = ++this.currentActionSeqInSession;
		
		this.addParamsToRequest(levelEndRequest, endData);
		levelEndRequest.request(true);
		
		this.currentDqid = null;
	}
	
	// Actions should be buffered and sent at a limited rate
	// (immediately flush if an end occurs or new quest start)
	public function logLevelAction(actionId:Int, ?details:Dynamic):Void
	{
		// Per action, figure out the time since the start of the level
		var timestampOfAction:Float = Date.now().getTime();
		var relativeTime:Float = timestampOfAction - this.timestampOfPrevLevelStart;
		var individualAction:Dynamic = {
			detail: details,
			client_ts: timestampOfAction,
			ts: relativeTime,
			te: relativeTime,
			session_seqid: ++this.currentActionSeqInSession,
			qaction_seqid: ++this.currentActionSeqInLevel,
			aid: actionId
		};
		this.levelActionBuffer.push(individualAction);
	}
	
	public function logActionWithNoLevel(actionId:Int, ?details:Dynamic):Void
	{
		var actionNoLevelRequest:Http = new Http(this.composeUrl("loggingactionnoquest/set/"));
		var actionNoLevelData:Dynamic = {
			session_seqid: ++this.currentActionSeqInSession,
			cid: this.categoryId,
			client_ts: Date.now().getTime(),
			aid: actionId,
			vid: this.versionNumber,
			uid: this.currentUserId,
			g_name: this.gameName,
			a_detail: details,
			gid: this.gameId,
			svid: 2,
			sessionid: this.currentSessionId
		};
		this.addParamsToRequest(actionNoLevelRequest, actionNoLevelData);
		actionNoLevelRequest.request(true);
	}
	
	private function flushBufferedLevelActions():Void
	{
		// Don't log any actions until a dqid has been set
		if (this.levelActionBuffer.length > 0 && this.currentDqid != null)
		{
			var levelActionRequest:Http = new Http(this.composeUrl("logging/set"));
			
			var bufferedActionsData:Dynamic = this.getCommonData();
			bufferedActionsData.actions = this.levelActionBuffer;
			bufferedActionsData.dqid = this.currentDqid;
			
			this.addParamsToRequest(levelActionRequest, bufferedActionsData);
			levelActionRequest.request(true);
			
			// Clear out old array
			this.levelActionBuffer = new Array<Dynamic>();
		}
	}
	
	private function composeUrl(suffix:String):String
	{
		var targetUrl:String = CapstoneLogger.prdUrl;
		if (this.useDev)
		{
			targetUrl = CapstoneLogger.devUrl;
		}
		return targetUrl + suffix;
	}
	
	private function getCommonData():Dynamic
	{
		return {
			client_ts: Date.now().getTime(),
			cid: this.categoryId,
			svid: 2,
			lid: 0,
			vid: this.versionNumber,
			qid: this.currentLevelId,
			g_name: this.gameName,
			uid: this.currentUserId,
			g_s_id: this.gameId,
			tid: 0,
			gid: this.gameId
		};
	}
	
	private function addParamsToRequest(request:Http, data:Dynamic):Void
	{
		// Standard template data sent for every request
		var stringifiedData:String = (data != null) ?
			Json.stringify(data) : null;
		var requestBlob:Dynamic = {
			dl: "0",
			latency: "5",
			priority: "1",
			de: "0",
			noCache: "",
			cid: Std.string(this.categoryId),
			gid: Std.string(this.gameId),
			data: stringifiedData,
			skey: this.encodedData(stringifiedData)
		};
		
		for (prop in Reflect.fields(requestBlob))
		{
			request.addParameter(prop, Reflect.field(requestBlob, prop));
		}
	}
	
	private function encodedData(value:String):String
	{
		if (value == null)
		{
			value = "";
		}
		
		var salt:String = value + this.gameKey;
		var result:String = Md5.encode(salt);
		return result;
	}
}
