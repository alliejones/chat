(function(scope) {
  function WSClient (url, pubsub) {
    this.url = url;
    this.pubsub = pubsub;

    this.pubsub.on('login', this.login.bind(this));
  }

  WSClient.prototype.login = function (settings) {
    this.username = settings.username;
    this.connect();
  };

  WSClient.prototype.connect = function () {
    this.socket = new WebSocket(this.url);

    this.socket.onopen = function (msg) { this.onOpen(msg); }.bind(this);
    this.socket.onmessage = function (msg) { this.onMessage(msg); }.bind(this);
    this.socket.onclose = function (msg) { this.onClose(msg); }.bind(this);
  },

  WSClient.prototype.disconnect = function () {
    this.socket.close();
  },

  WSClient.prototype.send = function (msg) {
    if (typeof msg !== 'string') msg = JSON.stringify(msg);
    this.socket.send(msg);
  },

  WSClient.prototype.onOpen = function (msg) {
    this.send({command: 'login', username: this.username });
  },

  WSClient.prototype.onMessage = function (msg) {
    this.pubsub.emit('message', {type: 'server', content: msg.data });
  },

  WSClient.prototype.onClose = function(e) {
    this.pubsub.emit('message', {type: 'server', content: 'Disconnected from server.'});
  }

  scope.WSClient = WSClient;
})(this);
