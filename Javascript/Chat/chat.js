/**
 * ChatSystem: local, transport-pluggable chat -- explicitly NOT
 * connected to Mojang's chat or friends network (no such access exists
 * for third-party projects). Everything here stores/relays messages
 * entirely on the player's own machine/browser.
 *
 * The default transport uses BroadcastChannel, a standard browser API
 * letting same-origin tabs/windows message each other directly with no
 * server involved -- genuinely functional today: open the same page in
 * two tabs and messages appear in both. A WebSocket transport (real LAN
 * chat between different machines, via a small relay server you run)
 * can be swapped in later without touching ChatSystem itself, since a
 * transport only needs postMessage(data) and onMessage(callback).
 */

const MAX_LOG_LENGTH = 200;

export class ChatSystem {
  constructor({ playerName = "Player", transport = null } = {}) {
    this.playerName = playerName;
    this.transport = transport;
    this.log = [];
    this.listeners = new Set();

    if (this.transport) {
      this.transport.onMessage((data) => this._receive(data));
    }
  }

  setPlayerName(name) {
    const trimmed = String(name ?? "").trim();
    this.playerName = trimmed.length > 0 ? trimmed.slice(0, 24) : "Player";
  }

  /**
   * Sends a message. Text starting with "/" is treated as a command and
   * is handled locally only -- it never gets broadcast to the transport.
   */
  send(text) {
    const trimmed = String(text ?? "").trim();
    if (trimmed.length === 0) return null;

    if (trimmed.startsWith("/")) {
      return this._handleCommand(trimmed);
    }

    const message = this._makeMessage(this.playerName, trimmed, true);
    this._appendToLog(message);

    if (this.transport) {
      this.transport.postMessage({ sender: this.playerName, text: trimmed, timestamp: message.timestamp });
    }

    return message;
  }

  _handleCommand(raw) {
    const [cmd, ...rest] = raw.slice(1).split(/\s+/);
    switch (cmd.toLowerCase()) {
      case "clear": {
        this.log = [];
        this._notify({ type: "clear" });
        return null;
      }
      case "nick": {
        const newName = rest.join(" ");
        if (newName) this.setPlayerName(newName);
        const sys = this._makeMessage("system", `You are now known as ${this.playerName}`, false);
        this._appendToLog(sys);
        return sys;
      }
      default: {
        const sys = this._makeMessage("system", `Unknown command: /${cmd}`, false);
        this._appendToLog(sys);
        return sys;
      }
    }
  }

  _receive(data) {
    if (!data || typeof data.text !== "string") return;
    const message = this._makeMessage(data.sender || "Unknown", data.text, false, data.timestamp);
    this._appendToLog(message);
  }

  _makeMessage(sender, text, isSelf, timestamp = Date.now()) {
    return { id: `${timestamp}-${Math.random().toString(36).slice(2, 8)}`, sender, text, isSelf, timestamp };
  }

  _appendToLog(message) {
    this.log.push(message);
    if (this.log.length > MAX_LOG_LENGTH) {
      this.log.splice(0, this.log.length - MAX_LOG_LENGTH);
    }
    this._notify({ type: "message", message });
  }

  /** Returns an unsubscribe function. */
  onMessage(listener) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  _notify(event) {
    for (const listener of this.listeners) listener(event, this.log);
  }
}

/**
 * BroadcastChannel-backed transport: same-browser, same-origin, works
 * across tabs/windows with zero server setup.
 */
export class BroadcastChannelTransport {
  constructor(channelName = "voxelpe_chat") {
    if (typeof BroadcastChannel === "undefined") {
      throw new Error("BroadcastChannel is not available in this environment.");
    }
    this.channel = new BroadcastChannel(channelName);
    this._callback = null;
    this.channel.onmessage = (event) => {
      if (this._callback) this._callback(event.data);
    };
  }

  postMessage(data) {
    this.channel.postMessage(data);
  }

  onMessage(callback) {
    this._callback = callback;
  }

  close() {
    this.channel.close();
  }
}
