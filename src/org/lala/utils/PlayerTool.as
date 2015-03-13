package org.lala.utils
{
	import com.longtailvideo.jwplayer.player.Player;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class PlayerTool extends EventDispatcher
	{
		/** 所辅助控制的播放器的引用 **/
		private var _player:Player;
		
		public function PlayerTool(p:Player, target:IEventDispatcher=null)
		{
			_player = p;		
			super(target);
		}
		
		/**
		 * 播放youtube视频,同时测试一下log
		 * @param vid youtube视频id
		 **/
		public function loadYoutubeVideo(vid:String):void
		{
			log("开始加载 youtube 视频信息...");
			//_player.load("https://www.youtube.com/watch?v=bKolpsFAK2U");
			var url:String = "https://www.youtube.com/watch?v=" + vid;
			_player.load({file: url});			
		}
		
		/**
		 * 播放youtube视频,同时测试一下log
		 * @param vid youtube视频id
		 **/
		public function loadLiveStream(serverAddr:String, channel:String):void
		{
			log("loading live stream ...");
			var url:String = "rtmp://" + serverAddr + "/play/" + channel;
			_player.load({file: url});			
		}
		
		private function log(message:String):void
		{
			trace(message);
		}
	}
}