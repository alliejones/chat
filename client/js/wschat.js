(function(scope) {
  function WSChat (url) {
    this.client = null;
    this.url = url;
    this.pubsub = new PubSub();
    return this;
  };

  WSChat.prototype.login = function (username) {
    this.client = new WSClient(this.url, this.pubsub);
    this.client.login(username);
    return this;
  };

  WSChat.prototype.logout = function () {
    this.client.disconnect();
  };

  WSChat.prototype.on = function () {
    this.pubsub.on.apply(this.pubsub, arguments);
  };

  WSChat.prototype.off = function () {};

  scope.WSChat = WSChat;
})(this);

$(function() {
  var oldLog = window.console.log;
  window.console.log = function () {
    var args = Array.prototype.slice.call(arguments, 0);
    oldLog.apply(window.console, args);
    $('body').append('<p>'+args.join(' ')+'</p>');
  };

  $(window).on('beforeunload', function() {
    // close socket connection when the page is reloaded or closed
    wsChat.logout();
  });

  window.wsChat = new WSChat('ws://0.0.0.0:8080/').login({ username: 'allie' });
});
