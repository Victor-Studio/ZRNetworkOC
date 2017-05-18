var LINK ='://';
// 定义蓝信jssdk的LanxinJSBridge用于实现js对native的调用和native对js的调用
var LanxinJSBridge;
!function() {
	if (window.LanxinJSBridge) {
		return;
	}
	var messagingIframe;
	// sendMessageQueue:为消息队列
	var sendMessageQueue = [];
	// native回调的消息队列
	var receiveMessageQueue = [];
	var messageHandlers = {};
	var menuHandlers = {};
	var actionHandlers = {};

	var CUSTOM_PROTOCOL_SCHEME = 'lx';
	var QUEUE_HAS_MESSAGE = '__has_msg__/';

	// native回调js的“回调方法定义”列表
	var responseCallbacks = {};
	var uniqueId = 1;

	var shareMailCallback;

	function _createQueueReadyIframe(doc) {
		messagingIframe = doc.createElement('iframe');
		messagingIframe.style.display = 'none';
		doc.documentElement.appendChild(messagingIframe);
	}

	function isAndroid() {
		var ua = navigator.userAgent.toLowerCase();
		var isA = ua.indexOf("android") > -1;
		if (isA) {
			return true;
		}
		return false;
	}

	function isIphone() {
		var ua = navigator.userAgent.toLowerCase();
		var isIph = ua.indexOf("iphone") > -1;
		if (isIph) {
			return true;
		}
		return false;
	}

	// set default messageHandler
	function init() {
		if (LanxinJSBridge._messageHandler) {
			throw new Error('LanxinJSBridge.init called twice');
		}
		// 默认的回调方法
		LanxinJSBridge._messageHandler = function messageHandler(data,
				responseCallback) {
			alert(JSON.stringify(data));
		};
		var receivedMessages = receiveMessageQueue;
		receiveMessageQueue = null;
		for (var i = 0; i < receivedMessages.length; i++) {
			_dispatchMessageFromNative(receivedMessages[i]);
		}
	}

	// 保存消息到队列responseCallbacks中，同时通知native有新的消息，native通过fetch函数去队列中取消息
	function send(data, responseCallback) {
		_doSend({
					data : data
				}, responseCallback);
	}

	function registerHandler(handlerName, handler) {
		messageHandlers[handlerName] = handler;
	}

	function _registerMenu(menuItem, param) {
		menuHandlers[menuItem] = param;
		_doSend({
					handlerName : "createMenu",
					data : param.data
				}, param);// 通知客户端去创建菜单
	}
	
	function _registerAction(actionItem, param) {
		actionHandlers[actionItem] = param;
		_doSend({
					handlerName : "createAction",
					data : param.data
				}, param);// 通知客户端去创建菜单
	}

	// handlerName:jssdk的API接口方法名
	// responseCallback：回调方法定义,注意：responseCallback是一个json，其内容为0~n个函数，供native选择调用
	function callHandler(handlerName, data, responseCallback) {
		_doSend({
					handlerName : handlerName,
					data : data
				}, responseCallback);
	}

	// sendMessage add message, 触发native处理 sendMessage
	// message中有三个信息：接口名：handlerName；参数：data；消息的id：callbackId
	// 如果有responseCallback则给message增加一个callbackId，如果没有则直接放入消息队列，并通知native去取
	function _doSend(message, responseCallback) {
		if (responseCallback) {
			var callbackId = 'cb_' + (uniqueId++) + '_' + new Date().getTime();
			responseCallbacks[callbackId] = responseCallback;
			message.callbackId = callbackId;

			responseCallback.currentFun = message.handlerName;
		}

		sendMessageQueue.push(message);
		messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + LINK
				+ QUEUE_HAS_MESSAGE;
		// 自测调用代码 ：模拟native回调jsbridge
//		 var ss =
//		 '{\"responseId\":\"cb_3_1436864961992\",\"responseData\":{\"localIds\":[\"CFF6F669-411B-403C-9667-4A72CAAB6FFF\",\"029DC719-F2C0-4D7B-93AC-03EE29D0F06A\"]},\"status\":\"success\"}';
//		 ss =
//		 '{\"responseId\":\"cb_2_1439195184664\",\"responseData\":{\"localIds\":[\"\\/var\\/mobile\\/Containers\\/Data\\/Application\\/B6E05A84-31D6-4EEB-858B-DF92D35A49AA\\/Documents\\/res\\/image\\/9BB1110B-6A3A-4F5D-9F1E-78877AE14E3B.png\",\"\\/var\\/mobile\\/Containers\\/Data\\/Application\\/B6E05A84-31D6-4EEB-858B-DF92D35A49AA\\/Documents\\/res\\/image\\/686043BC-686A-4097-AE80-1BF26504CD36.png\"]},\"status\":\"success\"}';
//		 ss =
//		 '{\"responseId\":\"cb_5_1439200258946\",\"responseData\":[{\"photoResId\":\"F002CDD3-AA04-4C3F-8C9B-6331F310AA95\",\"name\":\"丁小乐\",\"type\":0,\"userUniId\":\"163@10.uni1\"},{\"photoResId\":\"CC08C6E8-CDAC-4303-A0EB-4C67AC07CCCA\",\"name\":\"Cheshire\",\"type\":0,\"userUniId\":\"252@1000000000.uni1\"},{\"photoResId\":\"F841A6D8-8E2C-47B3-AEA8-080EB137671E\",\"name\":\"段洪锦\",\"type\":0,\"userUniId\":\"128@10.uni1\"}],\"status\":\"success\"}';
//		 var messageJSON = JSON.parse(ss);
//		 messageJSON.responseId = message.callbackId;
//		 messageJSON.status = "success";
//		 _dispatchMessageFromNative(JSON.stringify(messageJSON));
	}

	// 提供给native调用,该函数作用:获取sendMessageQueue返回给native,由于android不能直接获取返回的内容,所以使用url
	// shouldOverrideUrlLoading 的方式返回内容
	function _fetchQueue() {
		var messageQueueString = JSON.stringify(sendMessageQueue);
		sendMessageQueue = [];
		// add by hq
		if (isIphone()) {
			return messageQueueString;
			// android can't read directly the return data, so we can reload
			// iframe src to communicate with java
		} else if (isAndroid()) {
			messagingIframe.src = CUSTOM_PROTOCOL_SCHEME
					+LINK+ 'return/_fetchQueue/' + messageQueueString;
		}else{
			return messageQueueString;
		}
	}

	// 提供给native使用, 也就是native处理完之后回调jssdk的方法，并把返回的结果以messageJSON的格式返回
	// messageJSON中的内容：
	// responseId的值与callbackId一致
	function _dispatchMessageFromNative(messageJSON) {
		setTimeout(function() {
			var message = JSON.parse(messageJSON);
			var responseCallback;
			// java call finished, now need to call js callback function
			if (message.responseId) {

				// 这里的responseCallback是个类
				responseCallback = responseCallbacks[message.responseId];
				if (!responseCallback) {
					return;
				}
				//
				// 回调函数有多个时根据约定的status去取得相应的函数，如：status 为success
				// 则执行成功之后的函数，fail则执行失败后的回调函数
				// var callBackFun = eval("responseCallback." + message.status);
				var mesStatus = message.status;
				// native出现错误或者异常时，status置为error，直接由jsbridge抛出异常
				if ("error" == mesStatus) {
					_error(message.responseData);
					return;
				}

				var callBackFun = responseCallback[mesStatus];
				var completeFun = responseCallback['complete'];

				if (!callBackFun) {
					_error("no such callback function :" + mesStatus);
					return;
				}
				if (LanxinJSBridge.debug) {
					message.responseData.errMsg = responseCallback.currentFun
							+ ":ok";
					alert(JSON.stringify(message.responseData));
				}

				callBackFun(message.responseData);

				if (completeFun != undefined && !completeFun
						&& completeFun != callBackFun)
					completeFun(message.responseData);

				delete responseCallbacks[message.responseId];
			} else {
				var message = JSON.parse(messageJSON);
				var responseCallback = actionHandlers[message.handlerName];
				if(!responseCallback)
				  responseCallback = menuHandlers[message.handlerName]; 
				if (!responseCallback) {
					return;
				}
				var mesStatus = message.status;
				if(!mesStatus)
				   mesStatus = "success";
				// native出现错误或者异常时，status置为error，直接由jsbridge抛出异常
				if ("error" == mesStatus) {
					_error(message.responseData);
					return;
				}
		
				var callBackFun = responseCallback[mesStatus];
				var completeFun = responseCallback['complete'];
		
				if (!callBackFun) {
					_error("no such callback function :" + mesStatus);
					return;
				}
				if (LanxinJSBridge.debug) {
					message.responseData.errMsg = responseCallback.currentFun + ":ok";
					alert(JSON.stringify(message.responseData));
				}
		
				var result = callBackFun(message.responseData);
		
				if (completeFun != undefined && !completeFun&& completeFun != callBackFun)
					completeFun(message.responseData);
				// 直接发送 ，因为_doSend只有一个参数json，所以会把json直接发送给nativce
				// 此时的callbackId是在native中生成的，
				if (message.callbackId) {
					var callbackResponseId = message.callbackId;
					// 作用：发给native做后续处理，相当去调native的回调函数
					_doSend({
								responseId : callbackResponseId,
								responseData : result
							});
				}
			    
			}
		});
	}

	// 提供给native调用,receiveMessageQueue 在会在页面加载完后赋值为null
	// receiveMessageQueue是native发给jssdk的消息队列，用于存储native返回的待处理的消息队列
	function _handleMessageFromNative(messageJSON) {
		if (receiveMessageQueue) {
			receiveMessageQueue.push(messageJSON);
			init();
		} /*
			 * else { _dispatchMessageFromNative(messageJSON); }
			 */
	}

	function _handleMenuFromNative(messageJSON) {
		var message = JSON.parse(messageJSON);
		var responseCallback = menuHandlers[message.menuItem];
		if (!responseCallback) {
			return;
		}
		var mesStatus = message.status;
		// native出现错误或者异常时，status置为error，直接由jsbridge抛出异常
		if ("error" == mesStatus) {
			_error(message.responseData);
			return;
		}

		var callBackFun = responseCallback[mesStatus];
		var completeFun = responseCallback['complete'];

		if (!callBackFun) {
			_error("no such callback function :" + mesStatus);
			return;
		}
		if (LanxinJSBridge.debug) {
			message.responseData.errMsg = responseCallback.currentFun + ":ok";
			alert(JSON.stringify(message.responseData));
		}

		callBackFun(message.responseData);

		if (completeFun != undefined && !completeFun
				&& completeFun != callBackFun)
			completeFun(message.responseData);

	}
	
	function _handleActionFromNative(messageJSON) {
		var message = JSON.parse(messageJSON);
		var responseCallback = actionHandlers[message.actionItem];
		if (!responseCallback) {
			return;
		}
		var mesStatus = message.status;
		// native出现错误或者异常时，status置为error，直接由jsbridge抛出异常
		if ("error" == mesStatus) {
			_error(message.responseData);
			return;
		}

		var callBackFun = responseCallback[mesStatus];
		var completeFun = responseCallback['complete'];

		if (!callBackFun) {
			_error("no such callback function :" + mesStatus);
			return;
		}
		if (LanxinJSBridge.debug) {
			message.responseData.errMsg = responseCallback.currentFun + ":ok";
			alert(JSON.stringify(message.responseData));
		}

		callBackFun(message.responseData);

		if (completeFun != undefined && !completeFun
				&& completeFun != callBackFun)
			completeFun(message.responseData);

	}

	function _shareMail() {
		callHandler("shareMail", LanxinJSBridge.shareMailData,
				LanxinJSBridge.shareMailCallback)
	}

	function _error(mess) {
		if (!mess)
			alert("Unknown error");
		else
			alert(mess);
	}
	// 声明LanxinJSBridge对象
	LanxinJSBridge = window.LanxinJSBridge = {
		debug : false,
		init : init,
		send : send,
		registerHandler : registerHandler,
		_registerMenu : _registerMenu,
		_registerAction : _registerAction,
		callHandler : callHandler,
		_fetchQueue : _fetchQueue,
		_handleMessageFromNative : _handleMessageFromNative,
		_handleMenuFromNative : _handleMenuFromNative,
		_handleActionFromNative : _handleActionFromNative,
		_dispatchMessageFromNative : _dispatchMessageFromNative,

		shareMailData : {},
		shareMailCallback : shareMailCallback,
		_shareMail : _shareMail,

		_error : _error
	};

	var doc = document;
	_createQueueReadyIframe(doc);
	// var readyEvent = doc.createEvent('Events');
	// readyEvent.initEvent('LanxinJSBridgeReady');
	// readyEvent.bridge = LanxinJSBridge;
	// doc.dispatchEvent(readyEvent);

//	registerHandler('onVoiceRecordEnd', function(data, responseCallback) {
//				voice.localId = data.localId;
//				var responseData;
//				responseCallback(responseData);
//			});
//	registerHandler('onVoicePlayEnd', function(data, responseCallback) {
//				voice.localId = data.localId;
//				var responseData;
//				responseCallback(responseData);
//			});

}();
// /////////////////////////////////////////////下面定义供客户端程序调用的api////////////////////////////////////////
var wx = lx = {
	ready : ready,
	checkJsApi : checkJsApi,
	getNetworkType : getNetworkType,

	onMenuShareAppMessage : onMenuShareAppMessage,
	onMenuShareMail : onMenuShareMail,

	config : config,

	translateVoice : translateVoice,

	startRecord : startRecord,
	stopRecord : stopRecord,
	onVoiceRecordEnd : onVoiceRecordEnd,
	playVoice : playVoice,
	pauseVoice : pauseVoice,
	stopVoice : stopVoice,
	onVoicePlayEnd : onVoicePlayEnd,
	uploadVoice : uploadVoice,
	downloadVoice : downloadVoice,

	chooseImage : chooseImage,
	previewImage : previewImage,
	uploadImage : uploadImage,
	downloadImage : downloadImage,

	openLocation : openLocation,
	getLocation : getLocation,

	hideOptionMenu : hideOptionMenu,
	showOptionMenu : showOptionMenu,
	hideMenuItems : hideMenuItems,
	showMenuItems : showMenuItems,
	hideAllNonBaseMenuItem : hideAllNonBaseMenuItem,
	showAllNonBaseMenuItem : showAllNonBaseMenuItem,
	closeWindow : closeWindow,

	scanQRCode : scanQRCode,

	chooseFile : chooseFile,
	uploadFile : uploadFile,
	downloadFile : downloadFile,

	shareMail : shareMail,

	chooseReceiver : chooseReceiver,
	
	transferMess : transferMess,

	registerMenu : registerMenu,
	
	registerAction : registerAction,
	
	forbiddenLongPress : forbiddenLongPress,
	
	showBlueCard : showBlueCard,
	
	openChat : openChat,
	
	wifiDeviceInfo : wifiDeviceInfo,
	bluetoothDeviceInfo : bluetoothDeviceInfo,
	
	createNotice : createNotice,
	
	pickItem : pickItem,
	
	createConference : createConference,
	
	setForbiddenPullRefresh : setForbiddenPullRefresh,
	
	recordVideo : recordVideo,
	
	openVideo : openVideo,
	
	uploadVideo : uploadVideo,
	
	downloadVideo : downloadVideo,
	
	//以下是蓝图接口
	bpOpenWindow : bpOpenWindow,
	bpCloseWindow : bpCloseWindow,
	bpResolveExp : bpResolveExp,
	bpInsert : bpInsert,
	bpSubmit : bpSubmit,  
	bpLog : bpLog,
	bpNotify : bpNotify, 
	pickDate : pickDate,
	pickVoice : pickVoice,
	openVoicePlayer : openVoicePlayer,
	openVoiceRecorder : openVoiceRecorder,
	
	call:call,

	error : error
};

// 页面加载后首先执行此函数
var readyFunction;
function ready(fun) {
	readyFunction = fun;
}
// ready函数在所有文档加载完毕后执行（config函数执行完之后ready函数执行）
// $(document).ready(function(){
// if(checkJsApi){
// if(LanxinJSBridge.debug)
// LanxinJSBridge._error("{\"errMsg\":\"config:ok\"}");
// }else{
// if(LanxinJSBridge.debug)
// LanxinJSBridge._error("{\"errMsg\":\"config:invalid signature\"}");
// LanxinJSBridge._error("config:invalid signature");
// }
// setTimeout(readyFunction)
// });


//$(document).ready(function() {
//	if (checkjsapi) {
//		if (LanxinJSBridge.debug)
//			error({"errMsg":"config:ok"});
//	} else {
//		if (LanxinJSBridge.debug)
//			error({"errMsg":"config:invalid signature"});
//		error("config:invalid signature");
//	}
//	setTimeout(readyFunction)
//});
// 动态验证是否有验证调用jssdk的权限
var checkjsapi = true;
function config(paramJson) {
	var appId = paramJson['appId'];
	var timestamp = paramJson['timestamp'];
	var nonceStr = paramJson['nonceStr'];
	var signature = paramJson['signature'];
	var jsApiList = paramJson['jsApiList'];

	// $.ajax({
	// type: "GET",
	// url: "http://api.lanxin.cn/cgi-bin/js/verify?appId="+appId
	// +"&timestamp="+timestamp
	// +"&nonceStr="+nonceStr
	// +"&signature="+signature
	// +"&jsApiList="+jsApiList,
	// dataType: "jsonp",
	// success : function(data){
	// checkjsapi= data.checkJsApi;
	// }
	// });

	LanxinJSBridge.debug = paramJson['debug'];
	
	if(navigator.userAgent.indexOf("Lanxin")<0) {  
        alert("当前浏览器不支持蓝信js-sdk");  
//        alert(navigator.userAgent);
    }
	
	if (checkjsapi) {
		if (LanxinJSBridge.debug)
			error({"errMsg":"config:ok"});
	} else {
		if (LanxinJSBridge.debug)
			error({"errMsg":"config:invalid signature"});
		error("config:invalid signature");
	}
	setTimeout(readyFunction);
    //$(document).ready(readyFunction);//此行代码与setTimeout(readyFunction)相同

//	checkAgent();
}
// 监测是否有调用相应api的权限
function checkJsApi(param) {
	formateJsonAndCallHander("checkJsApi", param);
}

// 监测是否有网络
function getNetworkType(param) {
	formateJsonAndCallHander("getNetworkType", param);
}

//function checkAgent(){
//	window.checkagent = false;
//	formateJsonAndCallHander("checkAgent", {success : function(){
//	     window.checkagent = true; 
//	}});
//}
// 分享接口
// 分享到蓝信
function onMenuShareAppMessage(param) {
	formateJsonAndCallHander("onMenuShareAppMessage", param);
}
// 分享到蓝邮件
function onMenuShareMail(param) {
	formateJsonAndCallHander("onMenuShareMail", param);
}

// 智能接口
// 识别音频并返回识别结果接口
function translateVoice(param) {
	formateJsonAndCallHander("translateVoice", param);
}

// 开始录音接口
function startRecord(param) {
	formateJsonAndCallHander("startRecord", param);
}
// 停止录音接口
function stopRecord(param) {
	formateJsonAndCallHander("stopRecord", param);
}
// 监听录音自动停止接口
function onVoiceRecordEnd(param) {
	// LanxinJSBridge.registerHandler('onVoiceRecordEnd',param);
}
// 播放语音接口
function playVoice(param) {
	formateJsonAndCallHander("playVoice", param);
}
// 暂停播放接口
function pauseVoice(param) {
	formateJsonAndCallHander("pauseVoice", param);
}
// 停止播放接口
function stopVoice(param) {
	formateJsonAndCallHander("stopVoice", param);
}
// 监听录音播放停止
function onVoicePlayEnd(param) {
	// LanxinJSBridge.registerHandler('onVoicePlayEnd',param);
}
// 上传语音接口
function uploadVoice(param) {
	formateJsonAndCallHander("uploadVoice", param);
}
// 下载语音接口
function downloadVoice(param) {
	formateJsonAndCallHander("downloadVoice", param);
}

// 选择图片
function chooseImage(param) {
	formateJsonAndCallHander("chooseImage", param);
}
// 预览图片
function previewImage(param) {
	formateJsonAndCallHander("previewImage", param);
}
// 上传图片
function uploadImage(param) {
	formateJsonAndCallHander("uploadImage", param);
}
// 下载图片
function downloadImage(param) {
	formateJsonAndCallHander("downloadImage", param);
}

// 查看地理位置
function openLocation(param) {
	formateJsonAndCallHander("openLocation", param);
}
// 获取当前地理位置
function getLocation(param) {
	formateJsonAndCallHander("getLocation", param);
}

// 界面操作接口
// 隐藏右上角菜单接口
function hideOptionMenu(param) {
	formateJsonAndCallHander("hideOptionMenu", param);
}
// 显示右上角菜单接口
function showOptionMenu(param) {
	formateJsonAndCallHander("showOptionMenu", param);
}
// 批量隐藏功能按钮接口
function hideMenuItems(param) {
	formateJsonAndCallHander("hideMenuItems", param);
}
// 批量显示功能按钮接口
function showMenuItems(param) {
	formateJsonAndCallHander("showMenuItems", param);
}
// 隐藏所有非基础按钮接口
function hideAllNonBaseMenuItem(param) {
	formateJsonAndCallHander("hideAllNonBaseMenuItem", param);
}
// 显示所有功能按钮接口
function showAllNonBaseMenuItem(param) {
	formateJsonAndCallHander("showAllNonBaseMenuItem", param);
}
// 关闭当前网页窗口接口
function closeWindow(param) {
	formateJsonAndCallHander("closeWindow", param);
}

// 关闭当前网页窗口接口
function closeWindow(param) {
	formateJsonAndCallHander("closeWindow", param);
}

// 蓝信扫一扫
function scanQRCode(param) {
	formateJsonAndCallHander("scanQRCode", param);
}

// 文件接口
// 选择文件接口
function chooseFile(param) {
	formateJsonAndCallHander("chooseFile", param);
}
// 上传文件接口
function uploadFile(param) {
	formateJsonAndCallHander("uploadFile", param);
}
// 下载文件接口
function downloadFile(param) {
	formateJsonAndCallHander("downloadFile", param);
}

// 蓝邮件分享
function shareMail(param) {
	LanxinJSBridge.shareMailData.title = param.title;
	LanxinJSBridge.shareMailData.serverId = param.serverId;
	LanxinJSBridge.shareMailCallback = param;
}

// 选人
function chooseReceiver(param) {
	formateJsonAndCallHander("chooseReceiver", param);
}

// 转发蓝邮件
function transferMess(param) {
	formateJsonAndCallHander("transferMess", param);
}

// 禁止长按功能
function forbiddenLongPress(param) {
	formateJsonAndCallHander("forbiddenLongPress", param);
}

//展示蓝名片
function showBlueCard(param) {
	formateJsonAndCallHander("showBlueCard", param);
}

function openChat(param) {
	formateJsonAndCallHander("openChat", param);
}

function wifiDeviceInfo(param) {
	formateJsonAndCallHander("wifiDeviceInfo", param);
}

function bluetoothDeviceInfo(param) {
	formateJsonAndCallHander("bluetoothDeviceInfo", param);
}

function createNotice(param) {
	formateJsonAndCallHander("createNotice", param);
}

function pickItem(param) {
	formateJsonAndCallHander("pickItem", param);
}

function createConference(param) {
	formateJsonAndCallHander("createConference", param);
}

function setForbiddenPullRefresh(param) {
	formateJsonAndCallHander("setForbiddenPullRefresh", param);
}

function recordVideo(param) {
	formateJsonAndCallHander("recordVideo", param);
}

function openVideo(param) {
	formateJsonAndCallHander("openVideo", param);
}

function uploadVideo(param) {
	formateJsonAndCallHander("uploadVideo", param);
}

function downloadVideo(param) {
	formateJsonAndCallHander("downloadVideo", param);
}

//以下是蓝图接口
function bpOpenWindow(param) {
	formateJsonAndCallHander("bpOpenWindow", param);
}
function bpCloseWindow(param) {
	formateJsonAndCallHander("bpCloseWindow", param);
}
function bpResolveExp(param) {
	formateJsonAndCallHander("bpResolveExp", param);
}
function bpInsert(param) {
	formateJsonAndCallHander("bpInsert", param);
}
function bpSubmit(param) {
	formateJsonAndCallHander("bpSubmit", param);
}
function bpLog(param) {
	formateJsonAndCallHander("bpLog", param);
}
function bpNotify(param) {
	formateJsonAndCallHander("bpNotify", param);
}
function pickDate(param) {
	formateJsonAndCallHander("pickDate", param);
}
function pickVoice(param) {
	formateJsonAndCallHander("pickVoice", param);
}
function openVoicePlayer(param) {
	formateJsonAndCallHander("openVoicePlayer", param);
}
function openVoiceRecorder(param) {
	formateJsonAndCallHander("openVoiceRecorder", param);
}

function call(param){
	var handlerName = param["handlerName"];
	var dataJson =param["data"];
    LanxinJSBridge.callHandler(handlerName, dataJson, param);
}

function registerMenu(param) {
	if (LanxinJSBridge.debug && !checkjsapi) {
		error({"errMsg":"system:permission denied"});
		return;
	}
	var dataJson = {};
	var menuItem = "";
	for (var key in param) {
		var value = param[key];
		if (typeof(value) != "undefined" && typeof(value) != "function") {
			dataJson[key] = value;
			if ("menuItem" == key)
				menuItem = value;
			delete param[key];
		}
	}
	param["data"] = dataJson;
	LanxinJSBridge._registerMenu(menuItem, param);
}

function registerAction(param) {
	if (LanxinJSBridge.debug && !checkjsapi) {
		error({"errMsg":"system:permission denied"});
		return;
	}
	var dataJson = {};
	var actionItem = "";
	for (var key in param) {
		var value = param[key];
		if (typeof(value) != "undefined" && typeof(value) != "function") {
			dataJson[key] = value;
			if ("actionItem" == key)
				actionItem = value;
			delete param[key];
		}
	}
	param["data"] = dataJson;
	LanxinJSBridge._registerAction(actionItem, param);
}

function error(param) {
	var res ;
	if(param){
	  if (typeof(param) == "string")
	     res = param;
	  else if(typeof(param) == "object")
	     res = param.errMsg;
	  else if(typeof(param) == "function"){
	  	 var json = {};
	  	 json.success=param;
	     formateJsonAndCallHander("error", json);
	     return;
	  }
	  LanxinJSBridge._error(res);
	}
}

function formateJsonAndCallHander(handlerName, param) {
	if (LanxinJSBridge.debug && !checkjsapi) {
		error({"errMsg":"system:permission denied"});
		return;
	}
	var dataJson = {};
	for (var key in param) {
		var value = param[key];
		if (typeof(value) != "undefined" && typeof(value) != "function") {
			dataJson[key] = value;
		}
	}

	LanxinJSBridge.callHandler(handlerName, dataJson, param);
}