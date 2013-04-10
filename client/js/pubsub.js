(function(scope) {
  function PubSub () {
    this.handlers = {};
  }

  PubSub.prototype.on = function (eventType, handler) {
    if (!(eventType in this.handlers)) {
      this.handlers[eventType] = [];
    }

    this.handlers[eventType].push(handler);
    return this;
  };

  PubSub.prototype.emit = function (eventType) {
    var handlerArgs = Array.prototype.slice.call(arguments, 1);
    console.log('emit', eventType, JSON.stringify(handlerArgs));
    if (eventType in this.handlers) {
      for (var i = 0; i < this.handlers[eventType].length; i++) {
        this.handlers[eventType][i].apply(this, handlerArgs);
        }
    }
    return this;
  };

  scope.PubSub = PubSub;
})(this);