package org.lala.net
{
    
	//import com.adobe.protocols.dict.events.ErrorEvent;
	
	import flash.events.AsyncErrorEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.NetConnection;
	import flash.net.ObjectEncoding;
	import flash.net.Responder;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Security;
	import flash.system.SecurityDomain;
	import flash.utils.ByteArray;
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
	import mx.utils.StringUtil;
	
	import org.lala.event.EventBus;
	import org.lala.event.MukioEvent;
	import org.lala.net.CommentConnect;
	import org.lala.utils.CommentDataParser;
	import org.lala.utils.CommentXMLConfig;
    
    /** 
    * 处理向服务器发送弹幕消息
    * 从服务器的Amf加载弹幕
    * 普通的弹幕文件加载在provider中,因为实现得比较早
    * @author aristotle9
    **/
    public class CommentServer extends EventDispatcher
    {
        private var _user:String=null;
		private var _userid:String = null;
		private var _session:String=null;
        private var _cid:String;//_roomid
        private var _conf:CommentXMLConfig;
        private var _gateway:String;
        private var _postServer:String;
  
        private var _dataServer:CommentConnect;
		

        private var _dispathHandle:Function;
		
		
		private var _rtmp:String;

        public function CommentServer(target:IEventDispatcher=null)
        {
			_dataServer = new CommentConnect();
			if(_user==null)
			{
            	_user = 'user_' + Math.floor((Math.random()*0xFFFFFFFF));
			}
			if(_userid==null)
			{
				_userid = "appleClient_" + Math.floor((Math.random()*0xFFFFFFFF));
			}
            EventBus.getInstance().addEventListener(MukioEvent.SEND,sendHandler);
            
            

            
            super(target);
        }
		private function putDataHandler(e:MukioEvent):void
		{
			log('remotePutHandler:'+JSON.stringify(e.target.date));
		}
        /** 当接收到SEND消息后 **/
        private function sendHandler(event:MukioEvent):void
        {
            /**
            * item的格式在EventBus中以及弹幕输入类Input中可查
            **/
            var item:Object = event.data;
            var data:Object;
            item.user = _user;

            if(_dataServer)
            {
                log("使用AMF发送");
               // data = CommentDataParser.data_format(item);
				_dataServer.send("putCmt",item);

            }
            else if(_postServer)
            {
                log("使用POST发送");
				//_dataServer.PostCmt(item);

            }
            else
            {
                log("无法发送弹幕,服务器配置不正确.");
                EventBus.getInstance().removeEventListener(MukioEvent.SEND,sendHandler);
            }

        }
		

        private function getDataHandler(e:MukioEvent):void
        {
			var _idx:String=null;
			var result:Object = e.data;
			if(result==null || result.length==0)
			{
				//_dataServer.call('getCmts',_responderGet);
				return;
			}

			//直接通过转发的数据播放
			for( _idx in result)
			{
				var newCmt:Array=new Array();
				var _array:Object = result[_idx];
				for(var _item:String in _array)
				{
					if(_item=="date")
					{
						_array[_item] = CommentDataParser.date(new Date(_array[_item] * 1000));
					}
					if(_item!="mx_internal_uid")
					{
						newCmt[_item] =_array[_item];
					}
				}
				_array=null;
				try
				{
					if(newCmt.type!=undefined)
					{
						//_fmsDispatcher.onServerData(newCmt);
					}
				}
				catch(errorCatch:Error)
				{
					
				}
				newCmt=null;
			}
			
			//解析成xml 再播放
			/*
			var xmlstr:String = new String("<i>");

			for(var _idx in result)
			{
				var _array = result[_idx];

					try
					{
						
						xmlstr += StringUtil.substitute("<d p=\"{0},{1},{2},{3},{4},{5},{6},{7}\">{8}</d>\n",
							_array.stime,_array.mode,_array.size,_array.color,_array.date,_array.border,_array.user,_array.cmtid,_array.text);
					}
					catch(error1)
					{
						continue;
					}
			}
			xmlstr +="</i>";
			var _xml:XML = new XML(xmlstr);
			CommentDataParser.bili_parse(_xml,_dispathHandle);
			*/
			
            //CommentDataParser.data_parse(_xml.item,_dispathHandle);
        }
        private function remoteError(e:*):void
        {
            log('remoteError:'+JSON.stringify(e));
        }
        public function get cid():String
        {
            return _cid;
        }
		public function set userid(_in:String):void
		{
			_userid = _in;
		}
		public function get userid():String
		{
			return _userid;
		}		
		public function set session(_in:String):void
		{
			_session = _in;
		}
		public function get session():String
		{
			return _session;
		}
        public function set cid(value:String):void
        {

            _cid = value;
            _postServer = _conf.getCommentPostURL(_cid);
			//实时弹幕,geteway作为长连接服务器,postServer作为提交接口
			if(_gateway!="" || _postServer!="")
			{
				try
				{
					
					_dataServer.addEventListener(MukioEvent.SERVER_EVENT_USER_IN, rtmpUserIn);
					_dataServer.addEventListener(MukioEvent.SERVER_EVENT_USER_OUT, rtmpUserOut);
					_dataServer.addEventListener(MukioEvent.SERVER_EVENT_USER_LIST, rtmpUserList);
					_dataServer.addEventListener(MukioEvent.SERVER_EVENT_MSG_LIST, rtmpMsgList);
					
					_dataServer.addEventListener(MukioEvent.SERVER_EVENT_NEWDATA, rtmpNewCmtDataHandler);
					_dataServer.addEventListener(MukioEvent.SERVER_EVENT_PUT_DATA,putDataHandler);
					_dataServer.addEventListener(MukioEvent.SERVER_EVENT_GET_DATA,getDataHandler);
					_dataServer.connect(_gateway,_userid,_cid,_session,_postServer);


					log('与服务器连接完毕');
				}
				catch(error:Error)
				{
					log('与服务器连接遇到问题:\n' + 	'_gateway:' + _gateway + '\n' + error);
				}
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
		public function onBWCheck(...arg):void
		{
			return;
		}
		public function onBWDone(...arg):void
		{
			return;
		}
        private function log(message:String):void
        {
            EventBus.getInstance().log(message);
        }

        private function get gateway():String
        {
            return _gateway;
        }
        public function getCmts(foo:Function):void
        {
            if(!_dataServer)
            {
                log('服务器未连接,无法取得弹幕块.');
                return;
            }
            _dispathHandle = foo;
            _dataServer.send('getCmts');
        }
        private function set gateway(value:String):void
        {
            _gateway = value;
            if(_gateway == '')
            {
                log('服务器网关为空,取消连接操作.');
                return;
            }
           
        }
        /**
        * post提交的url
        * 收到需要发送的数据时,先检测_dataServer是否赋值,如果是,则用_gateway进行postamf提交
        * 如果没有赋值,则检测_postServer是否赋值,如果是,则用post表单提交
        **/
        private function get postServer():String
        {
            return _postServer;
        }

        private function set postServer(value:String):void
        {
            _postServer = value;
        }

        public function set conf(value:CommentXMLConfig):void
        {
            _conf = value;
            gateway = _conf.gateway;
			rtmp = value.rtmp;
        }

        public function get user():String
        {
            return _user;
        }

        public function set user(value:String):void
        {
            _user = value;
        }

		public function get rtmp():String
		{
			return _rtmp;
		}

		public function set rtmp(value:String):void
		{
			_rtmp = value;
			/*
			if(rtmp != "" && _cid != null)
			{
				_fmsDispatcher = new FMSDispatcher(rtmp + '/' + _cid + '/');
				_fmsDispatcher.addEventListener(MukioEvent.SERVER_EVENT_NEWDATA, rtmpNewCmtDataHandler);
			}
			*/
		}
		
		private function rtmpNewCmtDataHandler(event:MukioEvent):void
		{
			if(event.data==null)
			{
				return;
			}
			delete event.data.border;
			try
			{
				if(event.data.isSelf)
				{
					event.data.border=true;
				}
			}catch(e:ErrorEvent)
			{
				trace("no isself");
			}
			
			
			EventBus.getInstance().sendMukioEvent("displayRtmp", event.data);
		}


    }
}