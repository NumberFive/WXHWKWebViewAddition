function wxhWKWebViewDidLoad(){
    var u = navigator.userAgent;
    var isiOS = !!u.match(/\(i[^;]+;( U;)? CPU.+Mac OS X/); //ios终端
    if (isiOS) {
        window.webkit.messageHandlers.WXHWKWebViewDidLoad.postMessage(null);
    }
}

function iOSFunction(name)
{
	var u = navigator.userAgent;
	var isiOS = !!u.match(/\(i[^;]+;( U;)? CPU.+Mac OS X/); //ios终端
	if (isiOS) {
		var obj = {"selector":name};
		window.webkit.messageHandlers.WXHWKWebViewFunction.postMessage(obj);
	}
}
function iOSFunctionWithData(name,data)
{
	var u = navigator.userAgent;
	var isiOS = !!u.match(/\(i[^;]+;( U;)? CPU.+Mac OS X/); //ios终端
	if (isiOS) {
		var obj = {
			"selector":name,
			"data":data,
		};
		window.webkit.messageHandlers.WXHWKWebViewFunction.postMessage(obj);
	}
}
wxhWKWebViewDidLoad();
