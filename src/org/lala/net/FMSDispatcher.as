package org.lala.net
{
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.events.SyncEvent;
	import flash.events.TimerEvent;
	import flash.net.NetConnection;
	import flash.net.SharedObject;
	import flash.utils.Timer;
	
	import org.lala.event.MukioEvent;
	
	/**
	 * 有新弹幕
	 **/
	[Event(name="newCmtData", type="org.lala.event.MukioEvent")]
	public class FMSDispatcher extends EventDispatcher
	{
		protected var nc:NetConnection=null;
		protected var _shareObject:SharedObject=null;
		protected var rnd:uint = 0;
		private var heartBeat:Timer = new Timer(1000*15);//14分钟一个心跳包
		public function FMSDispatcher()
		{
			
		}
		public function connect(_room:String=null,_nc:NetConnection=null,_serverip:String=null):void
		{
			if(_serverip!=null)
			{
				nc = new NetConnection();
				nc.client=this;
				nc.addEventListener(NetStatusEvent.NET_STATUS,function(e:NetStatusEvent):void
				{
					if(e.info.code=="NetConnection.Connect.Success")
					{
						
						nc.call("ServerFunc_EnablePresence",null);
						heartBeat.start();
						heartBeat.addEventListener(TimerEvent.TIMER,heartBeatCallback);
						trace("rtmp chat server success!");
					}
				});
				
				
				
				nc.connect(_serverip+ "/" +_room,0,1);
			}else
			{
				nc = _nc;
				_shareObject = SharedObject.getRemote(_room,_nc.uri,false);
				_shareObject.client = _nc.client;
				_shareObject.connect(_nc);
				_shareObject.addEventListener(SyncEvent.SYNC,syncHandler);
			}
			//nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			//nc.connect(url);
			
			rnd = Math.floor(Math.random() * 0x1000000);
		}
		private function heartBeatCallback(e:TimerEvent):void
		{
			if(nc && nc.connected)
			{
				nc.call("ServerFunc_Heart",null);
				trace("send heartbeat");
			}
		}
		public function ClientFunc_EnablePresence(info:Object):void
		{
			trace("客户端认证成功!");
		}
		public function set client(_in:Object):void
		{
			if(nc)
			{
				nc.client = _in;
			}
		}
		public function get client():Object
		{
			return nc.client;
		}		
		public function set objectEncoding(_in:uint):void
		{
			if(nc)
			{
				nc.objectEncoding = _in;
			}
		}
		public function get objectEncoding():uint
		{
			return nc.objectEncoding;
		}	
		public function syncHandler(evt:SyncEvent):void
		{
			var _changedObject:Object = null;
			for(var _change:uint;_change<evt.changeList.length;_change++)
			{
				var _get:String=null;
				var a:String=null;
				switch(evt.changeList[_change].code)
				{
					case "change":
					{
						_changedObject = _shareObject.data[evt.changeList[_change].name] as Object;
						if(_changedObject==null)return;
						onServerData(_changedObject);
						for( _get in _changedObject)
						{
							 a = _changedObject[_get];
						}
					}
						break;
					case "clear":
					{
						
					}
						break;
					case "success":
					{
						_changedObject = _shareObject.data[evt.changeList[_change].name] as Object;
						if(_changedObject==null)return;

						for(_get in _changedObject)
						{
							 a = _changedObject[_get];
						}

							
					}
						break;
					default:
					{
						
					}
						break;
				}
			}
		}
		private function putCmt(data:Object):void
		{
			
			if(_shareObject)
			{
				_shareObject.setProperty("msgBlock",data);
			}else
			{
				if(nc && nc.connected)
				{

					nc.call("ServerFunc_CallClientFunc",null,"ServerPullBack",0,data);
				}
			}
			
		}
		public function ServerPullBack(fromid:int,data:Object):void
		{
			dispatchEvent(new MukioEvent(MukioEvent.SERVER_EVENT_NEWDATA, data));
			
		}
		public function Remote_MsgList(msgs:Object):void
		{
			//trace("Remote_MsgList");
			/*
			if ( isLiveMeeting() && getLiveCastStatus() != StringUtils.m_MeetingLiving )
			{	
				for each (var item:Object in msgs) 
				{
					if(item.name == "StartLiveMeeting")
					{
						setLiveCastStatus(item.body);
						break;
					}
				}
			}
			
			if (!isReceiveMsg()) return;
			
			var msgList:Array = new Array;
			for each (var item:Object in msgs) 
			{
				msgList.push(item);
			}
			msgList.sortOn("seq", Array.NUMERIC);
			
			m_isMsgList = true;
			for each (var item2:Object in msgList) 
			{
				if(item2.name != "StartLiveMeeting")
					Remote_PubMsg(item2);
			}
			m_isMsgList = false;
			if (UserMgr.instance().GetUserCount()==1 && !m_isPlayBKMusic && hasBKMusic())
			{
				playBKMusic();
				publishMessage("playBKMusic",0,0,true,"playBKMusic","");
			}
			
			if(loginUserType == 1)
			{
				ClientFunc_RequestChairmanACK(1);
			}
			*/
		}
		/**用户退出回调**/
		public function ClientFunc_UserOut( MeetBuddyID :uint   ):void
		{	
			//trace("ClientFunc_UserOut");
			/*
			var user:CUser = UserMgr.instance().GetUser( MeetBuddyID,0 );
			if( !user )
			{
				if(  m_MeetingParam.m_ConfUserNum + m_MeetingParam.m_SidelineUserNum > 500 )
					UserMgr.instance().DeleteUser( MeetBuddyID );
				return;
			}
			UnWatchAudio( MeetBuddyID );
			
			dispatchEvent( new CustomEvent("ClientFunc_UserOut",MeetBuddyID));
			
			Remote_DelMsg({"name": "RequestSpeak", "associatedUserID":MeetBuddyID});
			Remote_DelMsg({"name": "RequestControl", "associatedUserID":MeetBuddyID});
			Remote_DelMsg({"name": "RequestOperate", "associatedUserID":MeetBuddyID});
			
			if(user.isChairMan())
				setChairManPID(0);
			
			UserMgr.instance().DeleteUser( MeetBuddyID );
			*/
		}
		/**再会人员收到 新进用户的userin**/
		public function ClientFunc_UserIn(userinfo:Object):void
		{	
			//trace("ClientFunc_UserIn");
			/*
			//表示此时我还没出席，同时登陆服务器的用户很多的时候，会给我发userin消息，那样就重复了
			if( MeetingSession.MeetingStatus != MeetingSession.Signin )
				return;
			
			if (!userinfo["m_EnablePresence"])
				return;
			
			var user :CUser = new CUser(userinfo);
			if( user.m_UserType == 1)//将主席变为交互用户,通过chairmanchange修改
				user.m_UserType = 0;
			UserMgr.instance().AddUser(user);
			
			if (user.m_RuntimeType == StringUtils.m_RuntimeType_Tel)
			{
				user.m_PublishedAudio = StringUtils.m_RequestSpeak_Allow;
				WatchAudio(user.m_MeetBuddyID);
			}
			
			userinfo["id"] = user.m_MeetBuddyID;
			ClientFunc_ClientProperty(userinfo);
			
			dispatchEvent( new CustomEvent("ClientFunc_UserIn",userinfo));   //控制着给新进用户发送影音共享进度
			*/
		}
		/**新进用户收到再会用户列表**/
		public function ClientFunc_UserInList(userList:Array):void
		{
			//trace("获得用户列表!");
			/*
			for each(var userinfo:Object in userList)
			{	
				if (userinfo.m_BuddyID == m_LocalUser.m_BuddyID && m_LocalUser.m_BuddyID != 0)
				{
					GetMainNetConnect().call( "ServerFunc_CallClientFunc", null, 
						"ClientFunc_ChairmanKickOut", userinfo.m_MeetBuddyID ,StringUtils.m_S2C_Kickout_Repeat );
					continue;;
				}
				ClientFunc_UserIn(userinfo);
			}	
			if (UserMgr.instance().GetUserCount()!=1) return;
			//进入会议只有自已一人且会议模式为主讲模式时  发送ChairmanMode消息
			if( isSpeakerMode())
			{
				setChairmanMode(MeetingSession.Chairman_Control_Mode);
				var msgs:Array = new Array;
				msgs.push(createMessage("ChairmanMode", 0, 0, true, "ChairmanMode", "ChairmanChange") );
				if (!isLiveMeeting())
					msgs.push( createMessage("LayoutMode", 0, 0, layout,"LayoutMode","ChairmanMode") );
				publishMessageMulti(msgs);
			}	
			if (isSyncVideo())
			{
				
			}
			*/
		}


		public function sendData(data:Object):void
		{
			putCmt(data);

			
			/*
			try
			{
				nc.call("dispatchData", null, data, rnd);
			} 
			catch(error:Error) 
			{
				trace(error.toString());
			}
			*/
		}
		
		public function onServerData(data:Object):void
		{
			//if(r !== rnd)
			//{
				dispatchEvent(new MukioEvent(MukioEvent.SERVER_EVENT_NEWDATA, data));
			//}
			trace(data);
			
		}
		
		protected function netStatusHandler(event:NetStatusEvent):void
		{
			trace(event.info.code);			
		}
		public function onBWCheck(...arg):void
		{
			return;
		}
		public function onBWDone(...arg):void
		{
			return;
		}
		public function close():void
		{
			
		}
	}
}