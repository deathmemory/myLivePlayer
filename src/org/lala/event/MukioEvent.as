package org.lala.event
{
    import flash.events.Event;
    /** 播放器事件管道中流动的事件类 **/
    public class MukioEvent extends Event
    {
        /** 数据将被送到服务器 **/
        public static var SEND:String = 'send';
        /** 数据将被送到显示者 **/
        public static var DISPLAY:String = 'display';
        /** 日志数据 **/
        public static var LOG:String = 'log';
		
		public static var SERVER_EVENT_NEWDATA:String	="newCmtData";
		public static var SERVER_EVENT_GET_DATA:String	="SERVER_EVENT_GET_DATA";
		public static var SERVER_EVENT_PUT_DATA:String	="SERVER_EVENT_PUT_DATA";
		public static var SERVER_EVENT_USER_IN:String	="SERVER_EVENT_USER_IN";
		public static var SERVER_EVENT_USER_OUT:String	="SERVER_EVENT_USER_OUT";
		public static var SERVER_EVENT_USER_LIST:String	="SERVER_EVENT_USER_LIST";
		public static var SERVER_EVENT_MSG_LIST:String	="SERVER_EVENT_MSG_LIST";
        private var _data:Object;
        public function MukioEvent(type:String, d:Object, bubbles:Boolean=false, cancelable:Boolean=false)
        {
            _data = d;
            super(type, bubbles, cancelable);
        }
        public function get data():Object
        {
            return _data;
        }
        
    }
}