package org.lala.lang
{
	import mx.core.UIComponent;
	import mx.managers.SystemManager;
	import mx.resources.ResourceBundle;
	import mx.resources.ResourceManager;

	public class langmgr
	{
		[ResourceBundle("info")]
		
		private static var bInited:Boolean = false;
		
		public function langmgr()
		{
		}
		
		public static function isInit():Boolean
		{
			return bInited;
		}
		
		public static function init(params:Object):void
		{			
			var lang:String = params["lang"];
			if ( null != lang ) {
				switch (lang)
				{
					case "en" : lang = "en_US"; break;
					case "cn" : lang = "zh_CN"; break;
					case "pt" : lang = "pt_PT"; break;
					case "tr" : lang = "tr_TR"; break;
				}
			} else
				lang = "en_US";
			setLocation(lang);
		}
		
		public static function setLocation( location:String ):void
		{
			ResourceManager.getInstance().localeChain = [location];
			bInited = true;
		}
		
		public static function getString( key:String ):String
		{
			if ( isInit() )
				return ResourceManager.getInstance().getString("info", key);
			else
				return "";
		}
	}
}