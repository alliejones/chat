var io = require('socket.io').listen(8080);
var _ = require('underscore');

var clients = {};

function Client (ws) {
  this.socket = ws;
  this.id = ws.id;
  this.username = 'Anonymous';
}

Client.prototype.logout = function () {
  io.sockets.in('').emit('user:logout', { content: null, user: this.toJSON() });
};

Client.prototype.onConnection = function () {
  this.socket.emit('server:connection', clients);
  clients[this.id] = this;
};

Client.prototype.onLogin = function (username) {
  this.username = username;
  io.sockets.in('').emit('user:login', { content: null, user: this.toJSON() });
};

Client.prototype.onMessage = function (data) {
  io.sockets.in('').emit('user:message', {
    content: data,
    user: this.toJSON()
  });
};

Client.prototype.onDisconnect = function () {
  this.logout();
};

Client.prototype.toJSON = function () {
  return { id: this.id, username: this.username };
}

io.sockets.on('connection', function (socket) {
  var client = new Client(socket);
  client.onConnection();
  console.log(_.keys(clients).length + ' connected');

  socket.on('login', function (username) {
    client.onLogin(username);
  });

  socket.on('message', function (data) {
    client.onMessage(data);
  });

  socket.on('disconnect', function () {
    client.onDisconnect();
    delete clients[client.id];
    console.log(_.keys(clients).length + ' connected');
  });
});


