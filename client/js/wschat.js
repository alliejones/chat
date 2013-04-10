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

  WSChat.prototype.send = function (message) {
    this.client.send(message);
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

