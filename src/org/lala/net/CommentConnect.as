package org.lala.net
{
	import com.worlize.websocket.WebSocket;
	import com.worlize.websocket.WebSocketErrorEvent;
	import com.worlize.websocket.WebSocketEvent;
	import com.worlize.websocket.WebSocketMessage;
	
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.net.NetConnection;
	import flash.net.ObjectEncoding;
	import flash.net.Responder;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.sendToURL;
	import flash.system.Security;
	import flash.system.SecurityDomain;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
	import mx.utils.StringUtil;
	
	import org.lala.event.MukioEvent;
	import org.lala.utils.CommentDataParser;

	public class CommentConnect extends EventDispatcher
	{
		private var HTTP_POST_ADDR:String = null;
		protected var _dataServer_webSocket:WebSocket =null;
		private var _session:String=null;
		protected var _dataServer_http:URLLoader = null;
		protected var _userid:String=null;
		private var _responderPut:flash.net.Responder;
		private var _responderGet:flash.net.Responder;
		
		public static var SERVER_TYPE_UNKNOW:uint	=0;
		public static var SERVER_TYPE_WEBSOCKET:uint =3;
		public static var SERVER_TYPE_HTTP:uint		=1;
		public static var SERVER_TYPE_RTMP:uint		=2;
		private var _server_type:uint = SERVER_TYPE_UNKNOW;
		private var _roomid:String=null;
		private var timer:Timer = new Timer(1000*60);
		private var _dataServer_rtmp:FMSDispatcher = new FMSDispatcher();
		public function CommentConnect()
		{
			timer.start();
			timer.addEventListener(TimerEvent.TIMER,WorkFunctionQuquefunction);
			_responderPut = new flash.net.Responder(remotePutHandler,remoteError);
			_responderGet = new flash.net.Responder(remoteGetHandler,remoteError);
		}
		private function remoteError(e:*):void
		{
			//log('remoteError:'+JSON.stringify(e));
		}
		private function remotePutHandler(result:*):void
		{
			//log('remotePutHandler:'+JSON.stringify(result));
			dispatchEvent(new MukioEvent(MukioEvent.SERVER_EVENT_PUT_DATA,result));
		}
		public function set session(_in:String):void
		{
			_session = _in;
		}
		public function get session():String
		{
			return _session;
		}
		private function remoteGetHandler(result:Array):void
		{
			

			dispatchEvent(new MukioEvent(MukioEvent.SERVER_EVENT_GET_DATA,result));
		}
		public function onHttpStatusChange(e:HTTPStatusEvent):void
		{
			//http://www.17sucai.com/pins/demoshow/6112
			trace(e);
		}
		private function handleWebSocketOpen(event:WebSocketEvent):void {
			trace("web socket Connected");
			//订阅频道
			_dataServer_webSocket.sendUTF(JSON.stringify(["SUBSCRIBE", _roomid]));

		}
		
		private function handleWebSocketClosed(event:WebSocketEvent):void {
			trace("web socket Disconnected");
		}
		
		private function handleConnectionFail(event:WebSocketErrorEvent):void {
			trace("web socket Connection Failure: " + event.text);
		}
		private function jsonMessageToData(obj:Object):Boolean
		{
			var basChange:Boolean=false;
			var message:String = obj.text;
			if(Number(obj.mode) == 9)
			{
				try
				{
					basChange=true;
					var appendattr:Object = JSON.parse(message);
					obj.text = CommentDataParser.text_string(appendattr[0]);
					obj.x = appendattr[1];
					obj.y = appendattr[2];
					obj.alpha = appendattr[3];
					obj.style = appendattr[4];
					obj.duration = appendattr[5];
					obj.inStyle = appendattr[6];
					obj.outStyle = appendattr[7];
					obj.position = appendattr[8];
					obj.tStyle = appendattr[9];
					obj.tEffect = appendattr[10];
					//foo(obj.style + obj.position, obj);
				}
				catch (error:Error)
				{
					trace('JSON decode failed:'+message);
					basChange=false;
				}
				
			}
			else if(Number(obj.mode) == 7)
			{
				try
				{
					basChange=true;
					var json:Object = JSON.parse(message);
					obj.x = Number(json[0]);
					obj.y = Number(json[1]);
					obj.text = CommentDataParser.text_string(json[4]);
					obj.rZ = obj.rY = 0;
					if (json.length >= 7)
					{
						obj.rZ = Number(json[5]);
						obj.rY = Number(json[6]);
					}
					obj.adv = false;//表示是无运动的弹幕
					if (json.length >= 11)
					{
						obj.adv = true;//表示是有运动的弹幕
						obj.toX = Number(json[7]);
						obj.toY = Number(json[8]);
						obj.mDuration = 0.5;//默认移动时间,单位秒
						obj.delay = 0;//默认移动前的暂停时间
						if (json[9] != '')
						{
							obj.mDuration = Number(json[9]) / 1000;
						}
						if (json[10] != '')
						{
							obj.delay = Number(json[10]) / 1000;
						}
					}
					obj.duration = 2.5;
					if (json[3] < 12 && json[3] != 1) {
						obj.duration = Number(json[3]);
					}
					obj.inAlpha = obj.outAlpha = 1;
					var aa:Array = String(json[2]).split('-');
					if (aa.length >= 2)
					{
						obj.inAlpha = Number(aa[0]);
						obj.outAlpha = Number(aa[1]);
					}
				} catch (e:Error) 
				{
					trace('不是良好的JSON格式:' + message);
					basChange=false;
				}
			}
			return basChange;
		}
		private function handleWebSocketMessage(event:WebSocketEvent):void 
		{
			if (event.message.type == WebSocketMessage.TYPE_UTF8) 
			{
				
				var data:Object;
				var _json_array:Object = JSON.parse(event.message.utf8Data);
				for each(var _root:Object in _json_array)
				{
					data = JSON.parse(_root[2]);
				}
				if(typeof(data)!="object")return;

				//if(data.userid==_userid)return;
				
				data["border"]="true";
				if(jsonMessageToData(data)==false)
				{
					/*
					try
					{
						data["message"]=data.text;
						delete data.text;
						delete data.msg;
						delete data.type;
					}catch(e:Error)
					{
						trace(e);
					}
					*/
				}
				data["date"] =CommentDataParser.date(new Date(data["date"] * 1000));

				dispatchEvent(new MukioEvent(MukioEvent.SERVER_EVENT_NEWDATA, data));
				
				
			}else if (event.message.type == WebSocketMessage.TYPE_BINARY) 
			{
				trace("Got binary message of length " + event.message.binaryData.length);
			}
		}
		public function appendBarrageQueue(_in:String="",isSelf:Boolean=false):Boolean
		{
			var data:Object = new Object;
			data.border=true;	
			data.color=0xffffff;
			var time:Number = new Date().time;
			data.date = CommentDataParser.date(new Date());
			data.mode="1";	
			data.msg="1";	
			data.size=25;
			data.isSelf=isSelf;
			data.stime=0;	
			data.text=_in;
			data.type="normal";	
			data.user="null";	
			data.userid=null;

			dispatchEvent(new MukioEvent(MukioEvent.SERVER_EVENT_NEWDATA, data));
			return true;
		}
		public function connect(_url:String,...args):void
		{
			var _type:String=null;
			_userid = args[0];
			_roomid = args[1];
			_session = args[2];
			HTTP_POST_ADDR = args[3];
			_type = _url.substr(0,2).toLowerCase();
			if(_url=="")
			{
				_type = HTTP_POST_ADDR.substr(0,2).toLowerCase();
			}
			switch(_type)
			{
				case "st":
				{
					ExternalInterface.addCallback("appendBarrageQueue", appendBarrageQueue);
					
				}
					break;
				case "ws":
				{
					_dataServer_webSocket = new WebSocket(_url,"*");
					_dataServer_webSocket.debug=true;
					_dataServer_webSocket.addEventListener(WebSocketEvent.CLOSED, handleWebSocketClosed);
					_dataServer_webSocket.addEventListener(WebSocketEvent.OPEN, handleWebSocketOpen);
					_dataServer_webSocket.addEventListener(WebSocketEvent.MESSAGE, handleWebSocketMessage);
					_dataServer_webSocket.addEventListener(WebSocketErrorEvent.CONNECTION_FAIL, handleConnectionFail);
					
					_dataServer_webSocket.connect();

					_server_type = SERVER_TYPE_WEBSOCKET;
				}
					break;
				case "ht":
				{
					
					_dataServer_http = new URLLoader();
					_dataServer_http.addEventListener(Event.COMPLETE,postLoader_CompleteHandler);
					_dataServer_http.addEventListener(IOErrorEvent.IO_ERROR,postLoader_ErrorHandler);
					_dataServer_http.addEventListener(SecurityErrorEvent.SECURITY_ERROR,postLoader_ErrorHandler);
					_server_type = SERVER_TYPE_HTTP;
					
					/*
					_dataServer_http = new URLLoader();
					_dataServer_http.load(new URLRequest(_url));
					_server_type = SERVER_TYPE_HTTP;
					_dataServer_http.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatusChange);
					_dataServer_http.addEventListener(Event.COMPLETE, function(e:Event):void
					{
						trace(e.currentTarget.data);
					});
					*/
					//_dataServer_http.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				}
					break;
				case "rt":
				{

					_dataServer_rtmp.connect(_roomid,null,_url);
					_dataServer_rtmp.addEventListener(MukioEvent.SERVER_EVENT_USER_IN, rtmpUserIn);
					_dataServer_rtmp.addEventListener(MukioEvent.SERVER_EVENT_USER_OUT, rtmpUserOut);
					_dataServer_rtmp.addEventListener(MukioEvent.SERVER_EVENT_USER_LIST, rtmpUserList);
					_dataServer_rtmp.addEventListener(MukioEvent.SERVER_EVENT_MSG_LIST, rtmpMsgList);
					_dataServer_rtmp.addEventListener(MukioEvent.SERVER_EVENT_NEWDATA, rtmpNewCmtDataHandler);
					_server_type = SERVER_TYPE_RTMP;
				}
					break;
				default:
				{
					_server_type = SERVER_TYPE_UNKNOW;
				}
					break;				
			}
		}
		private function rtmpUserIn(event:MukioEvent):void
		{
			dispatchEvent(new MukioEvent(MukioEvent.SERVER_EVENT_USER_IN, event.data));
		}
		private function rtmpUserOut(event:MukioEvent):void
		{
			dispatchEvent(new MukioEvent(MukioEvent.SERVER_EVENT_USER_OUT, event.data));
		}
		private function rtmpUserList(event:MukioEvent):void
		{
			dispatchEvent(new MukioEvent(MukioEvent.SERVER_EVENT_USER_LIST, event.data));
		}
		private function rtmpMsgList(event:MukioEvent):void
		{
			dispatchEvent(new MukioEvent(MukioEvent.SERVER_EVENT_MSG_LIST, event.data));
		}
		private function rtmpNewCmtDataHandler(event:MukioEvent):void
		{
			if(event.data==null)
			{
				return;
			}
			dispatchEvent(new MukioEvent(MukioEvent.SERVER_EVENT_NEWDATA, event.data));

		}
		private function postLoader_CompleteHandler(event:Event):void
		{
			trace('POST Complete:' + String(event.target.data));   
		}
		private function postLoader_ErrorHandler(event:Event):void
		{
			trace("POST Error:" + event.toString());
		}
		public function get type():uint
		{
			return _server_type;
		}
		public function getConnect():Object
		{
			switch(_server_type)
			{
				case SERVER_TYPE_HTTP:
					return _dataServer_http;

				case SERVER_TYPE_RTMP:
					return _dataServer_rtmp;
					
				case SERVER_TYPE_WEBSOCKET:
					return _dataServer_webSocket;
			}
				return null;

		}
		private function Str2Encode(str:String,code:String):String
		{
			var stringresult:String = "";
			var byte:ByteArray =new ByteArray();
			byte.writeMultiByte(str,code);
			for (var i:int; i<byte.length; i++)
			{
				stringresult +=  escape(String.fromCharCode(byte[i]));
			}
			return stringresult;
		}

		private function WorkFunctionQuquefunction(e:TimerEvent):void
		{
			if(_dataServer_webSocket && _dataServer_webSocket.connected)
			{
				_dataServer_webSocket.ping();
			}
		}
		public function  PostCmt(item:Object,postAddr:String=null):void
		{
			var data:Object;
			if(postAddr==null)
			{
				return;
			}
			var _postLoader:URLLoader = new URLLoader();
			data = CommentDataParser.data_format(item);
			//data = item;
			var postVariables:URLVariables = new URLVariables();
			for(var k:String in data)
			{
				postVariables[k] = data[k];
			}
			postVariables["cid"] = _roomid;
			postVariables["session"]=_session;
			postVariables["userid"] = _userid;
			postVariables["msg"] = item["msg"];
			postVariables["type"] = item["type"];
			var request:URLRequest = null;

			request = new URLRequest(postAddr);
			request.method = URLRequestMethod.POST;
			request.data = postVariables;
			
			_postLoader.addEventListener(Event.COMPLETE,function(event:Event):void
			{
				trace('POST Complete:' + String(event.target.data));
			});
			_postLoader.addEventListener(IOErrorEvent.IO_ERROR,function(event:Event):void
			{
				trace("POST Error:" + event.toString());
			});
			_postLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,function(event:Event):void
			{
				trace("POST Error:" + event.toString());
			});
			_postLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS,function(e:HTTPStatusEvent):void
			{
				trace(e.toString());
			});
			_postLoader.load(request);

		}
		public function send(_cmd:String,...args):void
		{
			var item:Object = args[0];
			switch(_server_type)
			{
				case SERVER_TYPE_HTTP:
				{
					
					//return _dataServer_http;
					var data:Object;
					data = CommentDataParser.data_format(item);
					var postVariables:URLVariables = new URLVariables();
					for(var k:String in data)
					{
						postVariables[k] = data[k];
					}
					postVariables["cid"] = _roomid;
					var request:URLRequest = new URLRequest(HTTP_POST_ADDR);
					request.method = 'POST';
					request.data = postVariables;
					_dataServer_http.load(request);
				}
					break;
					
				case SERVER_TYPE_RTMP:
				{
					if(_cmd=="putCmt")
					{
						if(_dataServer_rtmp)
						{
							_dataServer_rtmp.sendData(item);
							return;
						}
						//_dataServer_rtmp.call(_cmd,_responderPut,args);
					}
					if(_cmd=="getCmts")
					{

						//_dataServer_rtmp.call(_cmd,_responderGet,args);
					}
				}
					break;
					
				case SERVER_TYPE_WEBSOCKET:
				{
					if(_cmd=="putCmt")
					{
						if(!_dataServer_webSocket)return;
						
						
						
						/*var _json_data:String =JSON.stringify(args[0]);

				
						var _request:URLRequest = new URLRequest();

						_request.url = "http://" + _dataServer_webSocket.host + "/publish/" + _roomid + "/" + Str2Encode(_json_data,"UTF8");
						_request.method = URLRequestMethod.GET;
					
						sendToURL(_request);
						*/
						PostCmt(item,HTTP_POST_ADDR);

					}
					if(_cmd=="getCmts")
					{
						
						//_dataServer_webSocket.sendUTF(JSON.stringify(["PUBLISH", "mychannel","testtest"]));
					}
					
					//return _dataServer_webSocket;
				}
					break;
			}
			
		}
		/*
		public function set client(_in:Object):void
		{
			_dataServer_rtmp.client = _in;
		}
		public function get client():Object
		{
			return _dataServer_rtmp.client;
		}		
		public function set objectEncoding(_in:uint):void
		{
			_dataServer_rtmp.objectEncoding = _in;
		}
		public function get objectEncoding():uint
		{
			return _dataServer_rtmp.objectEncoding;
		}	
		*/
	}
}